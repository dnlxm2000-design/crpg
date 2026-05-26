# player_controller.gd — 플레이어 입력 처리기 (Stoneshard 스타일). 3D version.
# 입력: _input 첫 키 즉시 반응 + _process 홀드 반복 (0.12s 간격).
# 실시간 마우스: 단클릭 즉시 이동 + 경로 미리보기.
# 방향: 4방향 면이동 (W=북, S=남, A=서, D=동).
extends Node

const CombatResolver = preload("res://source/features/turnbased/combat_resolver.gd")

# 이동 키 → 그리드 방향 벡터 매핑 (4방향 면이동).
# W=(0,-1)=북, S=(0,1)=남, A=(-1,0)=서, D=(1,0)=동
const DIRECTION_MAP: Dictionary = {
	"move_up": Vector2i(0, -1),
	"move_down": Vector2i(0, 1),
	"move_left": Vector2i(-1, 0),
	"move_right": Vector2i(1, 0),
}

var _movement = null
var _unit = null

# 턴 종료 확인
var _turn_end_confirm: bool = false

# 실시간 홀드 이동 반복 타이머
var _move_hold_timer: float = 0.0
const MOVE_HOLD_INTERVAL: float = 0.12

# 3D 마우스 피킹용 RayCast3D
var _mouse_raycast: RayCast3D = null


func _ready() -> void:
	_movement = get_node("../UnitMovement")
	_unit = get_parent()
	if _movement:
		print("[PlayerController] Found UnitMovement, parent=", _unit.name)
	else:
		push_error("[PlayerController] UnitMovement not found at ../UnitMovement")

	# RayCast3D 설정 (마우스 → 3D 월드 피킹)
	_mouse_raycast = RayCast3D.new()
	_mouse_raycast.name = "MouseRayCast"
	_mouse_raycast.target_position = Vector3(0, -100, 0)  # 아래 방향으로 긴 레이
	_mouse_raycast.collide_with_areas = false
	_mouse_raycast.collide_with_bodies = false
	# Terrain 메쉬와 충돌하도록 collision_mask 설정 (필요시 조정)
	_mouse_raycast.collision_mask = 1
	add_child(_mouse_raycast)


func _input(event: InputEvent) -> void:
	# 패널 토글 (U/I) — 이동 중에도 항상 동작
	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_focus_next") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_U or event.physical_keycode == KEY_U)):
		_toggle_equipment()
		get_viewport().set_input_as_handled()
		return

	if not _movement or _movement.is_locked:
		return

	if GameState.current_mode == GameState.GameMode.TURNBASED:
		_handle_turn_input(event)
		return

	# 실시간 모드: 키보드 첫 입력은 _input에서 즉시 처리
	if event is InputEventKey and not event.echo and event.pressed:
		for action in DIRECTION_MAP:
			if event.is_action_pressed(action):
				_do_key_move(DIRECTION_MAP[action], false)
				_move_hold_timer = 0.0
				get_viewport().set_input_as_handled()
				return

	_handle_realtime_input(event)


func _process(delta: float) -> void:
	if not _movement or _movement.is_locked:
		return

	var is_turn: bool = (GameState.current_mode == GameState.GameMode.TURNBASED)

	if not is_turn:
		# 홀드 연속 이동: is_action_pressed + 타이머로 반복
		_move_hold_timer += delta
		if _move_hold_timer >= MOVE_HOLD_INTERVAL:
			_move_hold_timer = 0.0
			for action in DIRECTION_MAP:
				if Input.is_action_pressed(action):
					_do_key_move(DIRECTION_MAP[action], false)
					break

		if Input.is_action_just_pressed("attack_action"):
			_pickup_nearest_item()

		if Input.is_action_just_pressed("enter_combat"):
			var gl = get_node("/root/Main/GameLoop")
			if gl and gl.has_method("request_combat_entry"):
				gl.request_combat_entry(_unit)


## ─── Real-time mouse helpers ───

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


## 3D 마우스 위치 → 월드 좌표 (RayCast3D 사용).
func _get_mouse_world_position() -> Vector3:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)

	# 지면(Y=0)과의 교점 계산
	if abs(dir.y) < 0.001:
		return Vector3.ZERO  # 레이 거의 수평

	var t := -from.y / dir.y
	if t < 0:
		return Vector3.ZERO  # 카메라 위쪽

	return from + dir * t


## Handle mouse input events for real-time mode (single-click immediate).
func _handle_realtime_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	if _is_click_on_hud_panel():
		return

	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_realtime_click_move()
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT:
			var path_preview = get_node_or_null("/root/Main/PathPreview")
			if path_preview and path_preview.has_method("clear"):
				path_preview.clear()
			get_viewport().set_input_as_handled()


## 실시간 모드: 단클릭 즉시 이동 + 경로 미리보기 표시.
func _realtime_click_move() -> void:
	if _movement.is_moving:
		return

	var grid_world = _movement.get_grid_world()
	if not grid_world:
		return

	var mouse_world: Vector3 = _get_mouse_world_position()
	var mouse_grid: Vector2i = grid_world.world_to_grid(mouse_world)

	# 우선 픽업 시도
	var inv = _unit.get_node_or_null("Inventory")
	if inv and _click_pickup_at(mouse_grid):
		return

	# 경로 미리보기 표시 + 즉시 이동 시작
	var target_world: Vector3 = grid_world.grid_to_world(mouse_grid)
	var path_preview = get_node_or_null("/root/Main/PathPreview")
	if path_preview and path_preview.has_method("preview_to"):
		path_preview.preview_to(mouse_grid)
	_movement.navigate_to(target_world)


## ─── Inventory & Equipment ───

func _toggle_inventory() -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud:
		var inv_panel = hud.get_node_or_null("InventoryPanel")
		if inv_panel and inv_panel.has_method("toggle"):
			inv_panel.toggle()


func _toggle_equipment() -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	print("[PlayerController] _toggle_equipment: hud=", hud != null, " eq_panel=", hud != null and hud.get_node_or_null("EquipmentPanel") != null)
	if hud:
		var eq_panel = hud.get_node_or_null("EquipmentPanel")
		if eq_panel and eq_panel.has_method("toggle"):
			eq_panel.toggle()


func _pickup_nearest_item() -> void:
	var grid_world = _movement.get_grid_world() if _movement else null
	if not grid_world:
		return

	var inv = _unit.get_node_or_null("Inventory")
	if not inv:
		return

	var player_gp: Vector2i = grid_world.world_to_grid(_unit.global_position)

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

	_try_loot_corpse(player_gp, grid_world, inv)


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
		return false

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


func _do_pickup_item(map_node: Node) -> void:
	if not is_instance_valid(map_node):
		return

	var item = map_node.get("item")
	if not item or typeof(item) != TYPE_OBJECT or not ("id" in item) or not ("item_name" in item):
		return

	if "item_type" in item and item.item_type == 4:
		var amount = item.value
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

	var inv = _unit.get_node_or_null("Inventory")
	if not inv:
		return

	if inv.has_method("add_item") and inv.add_item(item):
		print("[PlayerController] Picked up: %s" % item.item_name)
		if map_node.has_method("animate_pickup"):
			map_node.animate_pickup()
		else:
			map_node.queue_free()
		var event_log = get_node_or_null("/root/Main/HUD/EventLog")
		if event_log and event_log.has_method("add_entry"):
			event_log.add_entry("Picked up %s" % item.item_name, Color(0.4, 1.0, 0.4))


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


func _handle_turn_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _is_click_on_hud_panel():
			return
		get_viewport().set_input_as_handled()
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_turn_click()
				return
			MOUSE_BUTTON_RIGHT:
				var path_preview = get_node_or_null("/root/Main/PathPreview")
				if path_preview and path_preview.has_method("clear"):
					path_preview.clear()
				var hud = get_node_or_null("/root/Main/HUD")
				if hud:
					var tgt = hud.get_node_or_null("Targeting")
					if tgt and tgt.has_method("clear_target"):
						tgt.clear_target()
				return

	if event.is_action_pressed("attack_action"):
		_reset_turn_confirm()
		if _try_attack_adjacent():
			_auto_end_turn_if_ap_empty()
			return
		var g = _movement.get_grid_world() if _movement else null
		if g:
			var pg: Vector2i = g.world_to_grid(_unit.global_position)
			var inv = _unit.get_node_or_null("Inventory")
			if inv and _try_loot_corpse(pg, g, inv):
				_auto_end_turn_if_ap_empty()
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("skip_turn"):
		var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
		if ap > 0:
			if not _turn_end_confirm:
				_turn_end_confirm = true
				turn_indicator_set("Press Space again to end turn")
				get_viewport().set_input_as_handled()
				return
		_turn_end_confirm = false
		turn_indicator_set("")
		_end_player_turn()
		return

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

	for action_name in DIRECTION_MAP:
		if event.is_action_pressed(action_name):
			_reset_turn_confirm()
			var dir: Vector2i = DIRECTION_MAP[action_name]
			if _movement.move_one_tile(dir, _unit):
				get_viewport().set_input_as_handled()
				_auto_end_turn_if_ap_empty()
			return


## ─── Turn-based mouse click ───

func _handle_turn_click() -> void:
	if not _movement or not _movement.get_grid_world():
		return

	var grid_world = _movement.get_grid_world()
	var mouse_world: Vector3 = _get_mouse_world_position()
	var mouse_grid: Vector2i = grid_world.world_to_grid(mouse_world)

	_reset_turn_confirm()

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

	var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
	if ap <= 0 or not grid_world.is_walkable(mouse_grid):
		return

	var from_grid: Vector2i = grid_world.world_to_grid(_unit.global_position)
	var path: Array = grid_world.find_path_grid(from_grid, mouse_grid)
	if path.is_empty():
		return

	_move_along_path(path)


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


func turn_indicator_set(text: String) -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("set_turn_indicator"):
		hud.set_turn_indicator(text)


func _show_center_prompt(text: String) -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("show_center_prompt"):
		hud.show_center_prompt(text)


func _hide_center_prompt() -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("hide_center_prompt"):
		hud.hide_center_prompt()


## ─── Turn management ───

func _end_player_turn() -> void:
	get_viewport().set_input_as_handled()
	_hide_center_prompt()
	EventBus.player_ended_turn.emit(_unit)


func _auto_end_turn_if_ap_empty() -> bool:
	var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
	if ap <= 0:
		if not _turn_end_confirm:
			_turn_end_confirm = true
			_show_center_prompt("AP 0 — Press SPACE to end turn")
			get_viewport().set_input_as_handled()
		return false
	return true


## ─── Attack ───

func _try_attack_adjacent() -> bool:
	if not _movement:
		return false

	var grid_world = _movement.get_grid_world()
	if not grid_world:
		return false

	var ap = _unit.get("current_action_points") if "current_action_points" in _unit else 0
	if ap < 1:
		return false

	var my_pos: Vector2i = grid_world.world_to_grid(_unit.global_position)

	var _do_attack = func(occupant: Node, occ_pos: Vector2i) -> void:
		_unit.current_action_points -= 1
		EventBus.ap_changed.emit(_unit)
		var elv_diff: int = grid_world.get_elevation(my_pos) - grid_world.get_elevation(occ_pos) if grid_world.has_method("get_elevation") else 0
		var back: bool = CombatResolver.is_back_attack(my_pos, occupant)
		var cover: int = grid_world.calculate_cover(my_pos, occ_pos, _unit, occupant) if grid_world.has_method("calculate_cover") else 0
		var result = CombatResolver.resolve_attack(_unit, occupant, 1, elv_diff, back, cover)
		var hit = result[CombatResolver.KEY_HIT]
		if hit:
			if result[CombatResolver.KEY_CRIT]:
				print("[Combat] CRIT! %s -> %s (%d dmg)" % [_unit.unit_name, occupant.unit_name, result[CombatResolver.KEY_DAMAGE]])
			elif result[CombatResolver.KEY_GRAZE]:
				print("[Combat] Graze %s -> %s (%d dmg)" % [_unit.unit_name, occupant.unit_name, result[CombatResolver.KEY_DAMAGE]])
		else:
			EventBus.unit_evaded.emit(occupant, _unit)

	# 1. 바라보는 방향 우선 공격 — 3D: facing_direction is Vector3
	var facing_dir: Vector3 = _unit.get("facing_direction") if "facing_direction" in _unit else Vector3(0, 0, 1)
	var facing_tile: Vector2i = my_pos + Vector2i(roundi(facing_dir.x), roundi(facing_dir.z))
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
