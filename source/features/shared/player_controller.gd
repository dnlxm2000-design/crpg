# player_controller.gd — 플레이어 입력 처리기 (Stoneshard 스타일).
# _input(이벤트 기반) + _process(폴링) 이중 방식으로 안정적인 입력 캡처.
extends Node

const CombatResolver = preload("res://source/features/turnbased/combat_resolver.gd")

# 이동 키 → 그리드 방향 벡터 매핑 (아이소메트릭 8방향).
# WASD = 화면 상하좌우, QRZV = 화면 대각선.
# 화면 ↑ = 그리드 (-1,-1), 화면 → = 그리드 (1,-1), 등.
const DIRECTION_MAP: Dictionary = {
	"move_up": Vector2i(-1, -1),        # W / ↑ → 화면 위
	"move_down": Vector2i(1, 1),        # S / ↓ → 화면 아래
	"move_left": Vector2i(-1, 1),       # A / ← → 화면 왼쪽
	"move_right": Vector2i(1, -1),      # D / → → 화면 오른쪽
	"move_diag_up_left": Vector2i(-1, 0),   # Q → 화면 위-왼쪽 대각선
	"move_diag_up_right": Vector2i(0, -1),  # R → 화면 위-오른쪽 대각선
	"move_diag_down_left": Vector2i(0, 1),  # Z → 화면 아래-왼쪽 대각선
	"move_diag_down_right": Vector2i(1, 0), # V → 화면 아래-오른쪽 대각선
}

var _movement = null   # UnitMovement 컴포넌트 (경로 탐색 + 이동)
var _unit = null       # 부모 유닛 노드

# 턴 종료 확인: 첫 Space는 대기, 두 번째 Space가 턴 종료 확정
var _turn_end_confirm: bool = false

# 두 번 클릭 프리뷰: 첫 클릭 미리보기, 두 번째 클릭 이동 실행
var _preview_active: bool = false
var _preview_target_world: Vector2 = Vector2.ZERO
var _preview_target_grid: Vector2i = Vector2i(-1, -1)
var _path_preview: Node = null


func _ready() -> void:
	_movement = get_node("../UnitMovement")
	_unit = get_parent()
	if _movement:
		print("[PlayerController] Found UnitMovement, parent=", _unit.name)
	else:
		push_error("[PlayerController] UnitMovement not found at ../UnitMovement")
	_path_preview = get_node_or_null("/root/Main/PathPreview")   # 이동 경로 시각화 노드


func _input(event: InputEvent) -> void:
	if not _movement or _movement.is_locked:
		return

	# I키: 인벤토리 토글 (모드 무관, 전투/탐험 모두 동작)
	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	# U키: 장비 패널 토글 (모드 무관)
	if event.is_action_pressed("ui_focus_next") or (event is InputEventKey and event.keycode == KEY_U and event.pressed and not event.echo):
		_toggle_equipment()
		get_viewport().set_input_as_handled()
		return

	# 턴 기반 모드: 이벤트 기반 입력 처리
	if GameState.current_mode == GameState.GameMode.TURNBASED:
		_handle_turn_input(event)
		return

	# 실시간 모드: 마우스 클릭 처리 (이동 경로 지정 + 아이템 클릭)
	_handle_realtime_input(event)


func _process(_delta: float) -> void:
	if not _movement or _movement.is_locked:
		return

	var is_turn: bool = (GameState.current_mode == GameState.GameMode.TURNBASED)

	# Keyboard movement — 실시간모드에서만 _process 처리 (턴모드는 _input에서 처리)
	if not is_turn:
		for action in DIRECTION_MAP:
			if Input.is_action_just_pressed(action):
				_do_key_move(DIRECTION_MAP[action], is_turn)

	if not is_turn:
		# E키: 가장 가까운 아이템 집기 (탐험/조사 중심 RPG — 자동 줍기 없음)
		if Input.is_action_just_pressed("attack_action"):
			_pickup_nearest_item()

		# C키: 전투 진입 (주변에 적이 있을 때만 동작)
		if Input.is_action_just_pressed("enter_combat"):
			_cancel_preview()
			var gl = get_node("/root/Main/GameLoop")
			if gl and gl.has_method("request_combat_entry"):
				gl.request_combat_entry(_unit)


## ─── Real-time two-click preview system ───

## HUD 패널(인벤토리/장비)이 열려 있고 클릭이 그 위에 있으면 true.
func _is_click_on_hud_panel() -> bool:
	var hud = get_node_or_null("/root/Main/HUD")
	if not hud:
		return false
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	for panel_name in ["InventoryPanel", "EquipmentPanel"]:
		var panel = hud.get_node_or_null(panel_name)
		if panel and panel.visible and panel.get_global_rect().has_point(mouse_pos):
			return true
	return false


## Handle mouse input events for real-time mode (left click, right click).
func _handle_realtime_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	# HUD 패널 위 클릭은 게임 이동/액션으로 소비하지 않음 (닫기 버튼 등 UI 동작 보장)
	if _is_click_on_hud_panel():
		return

	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_click_preview_or_move()
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT:
			if _preview_active:
				_cancel_preview()
				get_viewport().set_input_as_handled()


## First click previews, second click on SAME tile confirms and moves.
## Clicking a DIFFERENT tile updates the preview.
## If there is a MapItem at the clicked tile, picks it up instead.
func _click_preview_or_move() -> void:
	if _movement.is_moving:
		return

	var mouse_world: Vector2 = _unit.get_global_mouse_position()
	var grid_world = _movement.get_grid_world()
	if not grid_world:
		return
	var mouse_grid: Vector2i = grid_world.world_to_grid(mouse_world)

	# Check if there is a pickable MapItem at the clicked tile
	if _click_pickup_at(mouse_grid):
		_cancel_preview()
		return

	if not _preview_active:
		# First click: show preview path
		_preview_active = true
		_preview_target_world = grid_world.grid_to_world(mouse_grid)
		_preview_target_grid = mouse_grid
		if _path_preview and _path_preview.has_method("preview_to"):
			_path_preview.preview_to(mouse_grid)
	elif mouse_grid == _preview_target_grid:
		# Second click on the SAME tile: confirm and move
		_preview_active = false
		if _path_preview and _path_preview.has_method("clear"):
			_path_preview.clear()
		_movement.navigate_to(_preview_target_world)
	else:
		# Click on a DIFFERENT tile: update preview
		_preview_target_world = grid_world.grid_to_world(mouse_grid)
		_preview_target_grid = mouse_grid
		if _path_preview and _path_preview.has_method("preview_to"):
			_path_preview.preview_to(mouse_grid)


## Cancel active preview without moving.
func _cancel_preview() -> void:
	_preview_active = false
	if _path_preview and _path_preview.has_method("clear"):
		_path_preview.clear()


## ─── Inventory & Equipment ───

## Toggle the inventory panel visibility.
func _toggle_inventory() -> void:
	"""I키: HUD 아래 InventoryPanel의 toggle()을 호출하여 표시/숨김 전환."""
	var hud = get_node_or_null("/root/Main/HUD")
	if hud:
		var inv_panel = hud.get_node_or_null("InventoryPanel")
		if inv_panel and inv_panel.has_method("toggle"):
			inv_panel.toggle()


## U키: 장비 패널 표시/숨김 전환.
func _toggle_equipment() -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud:
		var eq_panel = hud.get_node_or_null("EquipmentPanel")
		if eq_panel and eq_panel.has_method("toggle"):
			eq_panel.toggle()


## E키로 호출: 바닥에 있는 아이템 또는 시체 중 가장 가까운(거리 ≤1) 것을 처리.
## 탐험 모드: 아이템 우선, 없으면 시체 수색.
func _pickup_nearest_item() -> void:
	var grid_world = _movement.get_grid_world() if _movement else null
	if not grid_world:
		return

	var inv = _unit.get_node_or_null("Inventory")
	if not inv:
		return

	var player_gp: Vector2i = grid_world.world_to_grid(_unit.global_position)

	# 1. Try picking up a MapItem first
	var map_items: Array[Node] = get_tree().get_nodes_in_group("map_items")
	var nearest_item: Node = null
	var nearest_item_dist: int = 999
	for mi in map_items:
		if not is_instance_valid(mi):
			continue
		var mi_gp = mi.get("grid_position") if "grid_position" in mi else Vector2i(-1, -1)
		if mi_gp == Vector2i(-1, -1):
			continue
		var dist: int = max(abs(mi_gp.x - player_gp.x), abs(mi_gp.y - player_gp.y))
		if dist <= 1 and dist < nearest_item_dist:
			nearest_item = mi
			nearest_item_dist = dist

	if nearest_item:
		_do_pickup_item(nearest_item)
		return

	# 2. No MapItem — try looting a nearby corpse
	_try_loot_corpse(player_gp, grid_world, inv)


## Try to pick up a MapItem at a specific grid position.
## Returns true if an item was found and picked up at that position.
## 좌클릭으로 호출: grid_pos 위치에 MapItem이 있으면 획득한다.
## 거리 ≤1 (플레이어 타일 또는 인접 8방향)인 경우에만 가능.
## 반환값: 아이템을 집었으면 true, 아니면 false.
func _click_pickup_at(grid_pos: Vector2i) -> bool:
	var grid_world = _movement.get_grid_world() if _movement else null
	if not grid_world:
		return false

	var inv = _unit.get_node_or_null("Inventory")
	if not inv:
		return false

	var player_gp: Vector2i = grid_world.world_to_grid(_unit.global_position)
	var pickup_dist: int = max(abs(grid_pos.x - player_gp.x), abs(grid_pos.y - player_gp.y))
	if pickup_dist > 1:
		return false                                       # 거리 초과 → 무시

	# 해당 타일에 있는 MapItem 찾기
	var map_items_grp: Array[Node] = get_tree().get_nodes_in_group("map_items")
	for mi in map_items_grp:
		if not is_instance_valid(mi):
			continue
		var mi_gp = mi.get("grid_position") if "grid_position" in mi else Vector2i(-1, -1)
		var mi_item_name = ""
		var mi_item = mi.get("item")
		if mi_item and typeof(mi_item) == TYPE_OBJECT and "item_name" in mi_item:
			mi_item_name = mi_item.item_name
		print("[Pickup] Found map item '%s' at grid %s (item at grid_pos=%s)" % [mi_item_name, str(mi_gp), str(grid_pos)])
		if mi_gp == grid_pos:
			_do_pickup_item(mi)
			return true

	print("[Pickup] No MapItem at grid %s (dist=%d, player=%s, map_items_in_group=%d)" % [str(grid_pos), pickup_dist, str(player_gp), map_items_grp.size()])
	return false


## 아이템을 인벤토리에 추가하고, 픽업 애니메이션 재생, 로그에 기록한다.
## E키와 좌클릭 모두 이 함수를 통해 처리된다.
func _do_pickup_item(map_node: Node) -> void:
	if not is_instance_valid(map_node):
		return

	var item = map_node.get("item")
	if not item or typeof(item) != TYPE_OBJECT or not ("id" in item) or not ("item_name" in item):
		return

	# Gold → directly add to wallet
	if "item_type" in item and item.item_type == 4:  # GOLD
		var amount = item.value  # value = gold amount
		if "gold" in _unit:
			_unit.gold += amount
			EventBus.gold_changed.emit(_unit, amount)
			print("[PlayerController] Collected %d gold (total: %d)" % [amount, _unit.gold])
			if map_node.has_method("animate_pickup"):
				map_node.animate_pickup()
			else:
				map_node.queue_free()
			var event_log = get_node_or_null("/root/Main/HUD/EventLog")
			if event_log and event_log.has_method("add_entry"):
				event_log.add_entry("+%d gold" % amount, Color(1.0, 0.8, 0.0))
			return

	# Normal item → add to inventory
	var inv = _unit.get_node_or_null("Inventory")
	if not inv:
		return

	if inv.has_method("add_item") and inv.add_item(item):
		print("[PlayerController] Picked up: %s" % item.item_name)
		if map_node.has_method("animate_pickup"):
			map_node.animate_pickup()
		else:
			map_node.queue_free()
		# Log the pickup
		var event_log = get_node_or_null("/root/Main/HUD/EventLog")
		if event_log and event_log.has_method("add_entry"):
			event_log.add_entry("Picked up %s" % item.item_name, Color(0.4, 1.0, 0.4))


## E키/좌클릭에서 호출: 인접한(거리 ≤1) 시체를 찾아 수색한다.
## 시체가 있으면 gold/items를 플레이어 인벤토리로 이동시키고 시체 제거.
## 반환값: 시체를 수색했으면 true, 없으면 false.
func _try_loot_corpse(player_gp: Vector2i, grid_world, inv: Node) -> bool:
	var corpses: Array[Node] = get_tree().get_nodes_in_group("corpses")
	if corpses.is_empty():
		return false

	for c in corpses:
		if not is_instance_valid(c):
			continue
		if not c.has_method("loot"):
			continue
		var c_gp = c.get("grid_position") if "grid_position" in c else Vector2i(-1, -1)
		if c_gp == Vector2i(-1, -1):
			continue
		var dist: int = max(abs(c_gp.x - player_gp.x), abs(c_gp.y - player_gp.y))
		if dist <= 1:
			c.loot(_unit, inv)
			return true

	return false


## ─── Turn-based input ───

## Clear end-turn confirmation and hide any center prompt.
func _reset_turn_confirm() -> void:
	_turn_end_confirm = false
	_hide_center_prompt()


func _do_key_move(dir: Vector2i, is_turn: bool) -> void:
	if is_turn:
		_reset_turn_confirm()
		if _movement.move_one_tile(dir, _unit):
			_auto_end_turn_if_ap_empty()
	else:
		_movement.move_one_tile(dir)
		_cancel_preview()


func _handle_turn_input(event: InputEvent) -> void:
	# ── 마우스 클릭 처리 (전투 중 이동/공격) ──
	if event is InputEventMouseButton and event.pressed:
		# HUD 패널(인벤토리/장비) 위 클릭은 게임 입력으로 소비하지 않음
		if _is_click_on_hud_panel():
			return
		get_viewport().set_input_as_handled()
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_turn_click()
				return
			MOUSE_BUTTON_RIGHT:
				_cancel_preview()
				# 타겟 해제
				var hud = get_node_or_null("/root/Main/HUD")
				if hud:
					var tgt = hud.get_node_or_null("Targeting")
					if tgt and tgt.has_method("clear_target"):
						tgt.clear_target()
				return

	# E → attack adjacent enemy, or loot corpse if none nearby
	if event.is_action_pressed("attack_action"):
		_reset_turn_confirm()
		if _try_attack_adjacent():
			_auto_end_turn_if_ap_empty()
			return
		# No adjacent enemy — try looting a corpse instead
		var g = _movement.get_grid_world() if _movement else null
		if g:
			var pg: Vector2i = g.world_to_grid(_unit.global_position)
			var inv = _unit.get_node_or_null("Inventory")
			if inv and _try_loot_corpse(pg, g, inv):
				_auto_end_turn_if_ap_empty()
		return

	# Space → confirm-once if AP remains, else instant
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("skip_turn"):
		var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
		if ap > 0:
			if not _turn_end_confirm:
				# First Space: show warning, set confirm flag
				_turn_end_confirm = true
				turn_indicator_set("Press Space again to end turn")
				get_viewport().set_input_as_handled()
				return
			# Second Space: confirm end turn
		_turn_end_confirm = false
		turn_indicator_set("")
		_end_player_turn()
		return

	# Tab → cycle through targets
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo:
		var hud = get_node_or_null("/root/Main/HUD")
		if hud:
			var targeting = hud.get_node_or_null("Targeting")
			if targeting and targeting.has_method("cycle_next"):
				if event.shift_pressed:
					targeting.cycle_prev()
				else:
					targeting.cycle_next()
		get_viewport().set_input_as_handled()
		return

	# Directional movement
	for action_name in DIRECTION_MAP:
		if event.is_action_pressed(action_name):
			_reset_turn_confirm()
			var dir: Vector2i = DIRECTION_MAP[action_name]
			if _movement.move_one_tile(dir, _unit):
				get_viewport().set_input_as_handled()
				_auto_end_turn_if_ap_empty()
			return


## ─── Turn-based mouse click ───

## 전투 중 좌클릭 처리: 적 클릭 → 타겟+공격, 빈 타일 클릭 → 경로 이동.
func _handle_turn_click() -> void:
	if not _movement or not _movement.get_grid_world():
		return

	var grid_world = _movement.get_grid_world()
	var mouse_world = _unit.get_global_mouse_position()
	var mouse_grid: Vector2i = grid_world.world_to_grid(mouse_world)

	_reset_turn_confirm()

	# 1. 적 클릭 → 타겟 설정 + 인접 시 공격
	var occupant = grid_world.get_occupant(mouse_grid)
	if occupant and occupant != _unit \
			and occupant.get("is_player") == false \
			and occupant.get("is_alive"):
		_select_target_node(occupant)

		var my_pos: Vector2i = grid_world.world_to_grid(_unit.global_position)
		var dist: int = max(abs(mouse_grid.x - my_pos.x), abs(mouse_grid.y - my_pos.y))
		if dist <= 1:
			_try_attack_adjacent()
		return

	# 2. 빈 타일 클릭 → 경로 탐색 + 이동
	var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
	if ap <= 0 or not grid_world.is_walkable(mouse_grid):
		return

	var from_grid: Vector2i = grid_world.world_to_grid(_unit.global_position)
	var path: Array = grid_world.find_path_grid(from_grid, mouse_grid)
	if path.is_empty():
		return

	_move_along_path(path)


## 경로를 따라 한 칸씩 이동 (AP 소모).
func _move_along_path(path: Array) -> void:
	for step in path:
		var from: Vector2i = _movement.get_grid_world().world_to_grid(_unit.global_position)
		var dir: Vector2i = step - from
		if dir == Vector2i.ZERO:
			continue
		if not _movement.move_one_tile(dir, _unit):
			break
		if not _auto_end_turn_if_ap_empty():
			break


## HUD Targeting 시스템에서 특정 노드를 타겟으로 선택.
func _select_target_node(node: Node) -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if not hud:
		return
	var targeting = hud.get_node_or_null("Targeting")
	if not targeting or not targeting.has_method("refresh_targets"):
		return
	targeting.refresh_targets()
	if targeting.has_method("select_target_by_node"):
		targeting.select_target_by_node(node)


## Update the turn indicator label in HUD (if available).
func turn_indicator_set(text: String) -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("set_turn_indicator"):
		hud.set_turn_indicator(text)


## Show center-screen prompt (AP 0 message, etc.).
func _show_center_prompt(text: String) -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("show_center_prompt"):
		hud.show_center_prompt(text)


## Hide center-screen prompt.
func _hide_center_prompt() -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("hide_center_prompt"):
		hud.hide_center_prompt()


## ─── Turn management ───

## End the player's turn explicitly.
func _end_player_turn() -> void:
	get_viewport().set_input_as_handled()
	_hide_center_prompt()
	EventBus.player_ended_turn.emit(_unit)


## Ask if player wants to end turn when AP = 0 (instead of auto-ending).
## Returns false if AP is empty (movement should stop).
func _auto_end_turn_if_ap_empty() -> bool:
	var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
	if ap <= 0:
		if not _turn_end_confirm:
			_turn_end_confirm = true
			_show_center_prompt("AP 0 — Press SPACE to end turn")
			get_viewport().set_input_as_handled()
		return false  # AP depleted, stop moving
	return true  # AP remains, can continue


## ─── Attack ───

## Try to attack an adjacent enemy. Returns true if attack happened.
func _try_attack_adjacent() -> bool:
	if not _movement:
		return false

	var grid_world = _movement.get_grid_world()
	if not grid_world:
		return false

	# Check AP
	var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
	if ap < 1:
		return false

	var my_pos: Vector2i = grid_world.world_to_grid(_unit.global_position)

	# 공격 헬퍼: elevation + back attack 포함 resolve 후 attack 수행
	var _do_attack = func(occupant: Node, occ_pos: Vector2i) -> void:
		_unit.current_action_points -= 1
		EventBus.ap_changed.emit(_unit)
		var elv_diff: int = grid_world.get_elevation(my_pos) - grid_world.get_elevation(occ_pos) if grid_world.has_method("get_elevation") else 0
		var back: bool = CombatResolver.is_back_attack(my_pos, occupant)
		var result = CombatResolver.resolve_attack(_unit, occupant, 1, elv_diff, back)
		var hit = result[CombatResolver.KEY_HIT]
		if hit:
			if result[CombatResolver.KEY_CRIT]:
				print("[Combat] CRIT! %s -> %s (%d dmg)" % [_unit.unit_name, occupant.unit_name, result[CombatResolver.KEY_DAMAGE]])
			elif result[CombatResolver.KEY_GRAZE]:
				print("[Combat] Graze %s -> %s (%d dmg)" % [_unit.unit_name, occupant.unit_name, result[CombatResolver.KEY_DAMAGE]])
		else:
			EventBus.unit_evaded.emit(occupant, _unit)

	# 1. 바라보는 방향 우선 공격
	var facing_dir: Vector2 = _unit.get("facing_direction") if "facing_direction" in _unit else Vector2.DOWN
	var facing_tile: Vector2i = my_pos + Vector2i(roundi(facing_dir.x), roundi(facing_dir.y))
	var facing_occ = grid_world.get_occupant(facing_tile)
	if facing_occ and facing_occ != _unit \
			and facing_occ.get("is_player") == false \
			and facing_occ.get("is_alive"):
		_do_attack.call(facing_occ, facing_tile)
		return true

	# 2. 없으면 모든 인접 적 중 첫 번째 공격
	var neighbors: Array[Vector2i] = [
		my_pos + Vector2i(0, -1), my_pos + Vector2i(1, 0),
		my_pos + Vector2i(0, 1), my_pos + Vector2i(-1, 0),
		my_pos + Vector2i(-1, -1), my_pos + Vector2i(1, -1),
		my_pos + Vector2i(-1, 1), my_pos + Vector2i(1, 1),
	]

	for n in neighbors:
		var occupant = grid_world.get_occupant(n)
		if occupant and occupant != _unit \
				and occupant.get("is_player") == false \
				and occupant.get("is_alive"):
			_do_attack.call(occupant, n)
			return true

	return false
