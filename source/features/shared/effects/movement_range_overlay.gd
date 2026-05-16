# movement_range_overlay.gd — Highlights reachable tiles for the active combatant.
# BFS from the unit's position, limited by remaining AP / ap_cost_per_tile.
# Attach as child of GridWorld or Main.
# 전투 중: 이동 가능(초록), 이동 불가(빨강), 적 ZOC(주황) 표시.
extends Node2D

var _grid_world: Node = null
var _reachable_tiles: Array[Vector2i] = []
var _current_unit: Node = null


func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.ap_changed.connect(_on_ap_changed)
	EventBus.combat_ended.connect(_on_combat_ended)


func setup(grid_world: Node) -> void:
	_grid_world = grid_world


## Calculate reachable tiles when a unit's turn starts.
## Only shows overlay for the player — enemy reachable tiles are hidden.
func _on_turn_started(unit: Node) -> void:
	_current_unit = unit
	if not unit.get("is_player"):
		# Enemy turn: hide overlay, don't reveal enemy info
		_reachable_tiles.clear()
		queue_redraw()
		return
	_compute_reachable(unit)
	queue_redraw()


## Clear overlay when turn ends.
func _on_turn_ended(_unit: Node) -> void:
	_current_unit = null
	_reachable_tiles.clear()
	queue_redraw()


## Recalculate when AP changes (e.g. after movement or attack).
func _on_ap_changed(unit: Node) -> void:
	if unit == _current_unit and is_instance_valid(unit) and unit.get("is_alive"):
		_compute_reachable(unit)
		queue_redraw()


## Clear when combat ends entirely.
func _on_combat_ended() -> void:
	_current_unit = null
	_reachable_tiles.clear()
	queue_redraw()


## BFS from the unit's grid position, limited by remaining movement budget.
func _compute_reachable(unit: Node) -> void:
	_reachable_tiles.clear()
	if not _grid_world or not unit:
		return
	if not unit.get("is_alive"):
		return

	var ap: int = unit.get("current_action_points") if "current_action_points" in unit else 0
	if ap <= 0:
		return

	# Determine AP cost per tile for this unit
	var ap_cost: int = 1
	var movement = unit.get_node_or_null("UnitMovement")
	if movement and "ap_cost_per_tile" in movement:
		ap_cost = movement.ap_cost_per_tile

	var max_steps: int = floor(ap / ap_cost)
	if max_steps <= 0:
		return

	var start_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)

	# BFS with depth limit = max_steps
	var visited: Dictionary = {}
	var key_start: String = "%d,%d" % [start_pos.x, start_pos.y]
	visited[key_start] = true

	# FIFO queue: [{pos, dist}]
	var queue: Array[Dictionary] = [{pos = start_pos, dist = 0}]

	while queue.size() > 0:
		var current: Dictionary = queue.pop_front()

		var neighbors: Array[Vector2i] = _grid_world.get_neighbors(current.pos)
		for n in neighbors:
			var key: String = "%d,%d" % [n.x, n.y]
			if key in visited:
				continue

			var new_dist: int = current.dist + 1
			if new_dist > max_steps:
				continue

			visited[key] = true
			_reachable_tiles.append(n)
			# Also push neighbor to expand from it
			# But don't expand if we're at max depth
			if new_dist < max_steps:
				queue.append({pos = n, dist = new_dist})

	# Exclude the unit's own tile
	_reachable_tiles.erase(start_pos)


func _draw() -> void:
	if not _grid_world:
		return

	var is_turn: bool = (GameState.current_mode == GameState.GameMode.TURNBASED)
	if not is_turn:
		return

	# ── 이동 가능 타일 (기존 초록) ──
	if not _reachable_tiles.is_empty():
		for tile in _reachable_tiles:
			_draw_diamond(tile, Color(0.3, 0.8, 0.3, 0.3), Color(0.3, 0.8, 0.3, 0.6))

	# ── 플레이어 턴에서만 추가 정보 표시 ──
	if _current_unit and _current_unit.get("is_player"):
		_draw_blocked_overlay()
		_draw_zoc_overlay()


## 이동 불가 타일(blocked)을 빨간색으로 표시.
func _draw_blocked_overlay() -> void:
	if not _grid_world or not _grid_world.has_method("blocked"):
		return
	var blocked: Dictionary = _grid_world.blocked
	for key in blocked:
		var parts: PackedStringArray = key.split(",")
		if parts.size() < 2:
			continue
		var tile := Vector2i(parts[0].to_int(), parts[1].to_int())
		_draw_diamond(tile, Color(0.8, 0.15, 0.15, 0.25), Color(0.8, 0.15, 0.15, 0.5))


## 적 ZOC 타일을 주황색으로 표시.
func _draw_zoc_overlay() -> void:
	if not _grid_world or not _current_unit:
		return
	var tm = get_node_or_null("/root/Main/GameLoop/TurnManager")
	if not tm:
		return
	var combatants: Array = tm.get("combatants") if "combatants" in tm else []
	if combatants.is_empty():
		return

	var zoc_map = ZocController.get_enemy_zoc_map(_current_unit, combatants, _grid_world)
	for key in zoc_map:
		var parts: PackedStringArray = key.split(",")
		if parts.size() < 2:
			continue
		var tile := Vector2i(parts[0].to_int(), parts[1].to_int())
		# 범위 밖 또는 blocked 타일은 제외
		if not _grid_world.is_walkable(tile, true):
			continue
		# 적이 점유한 타일(적 본체 위치)은 제외 — ZOC는 빈 타일만
		if not _grid_world.is_walkable(tile):
			continue
		_draw_diamond(tile, Color(0.9, 0.5, 0.1, 0.25), Color(0.9, 0.5, 0.1, 0.5))


func _draw_diamond(tile: Vector2i, fill: Color, stroke: Color) -> void:
	var c: Vector2 = _grid_world.grid_to_world(tile)
	var diamond := PackedVector2Array([
		Vector2(c.x,      c.y - 16),
		Vector2(c.x + 32, c.y),
		Vector2(c.x,      c.y + 16),
		Vector2(c.x - 32, c.y),
	])
	draw_colored_polygon(diamond, fill)
	draw_polyline(diamond, stroke, 1.5, true)
