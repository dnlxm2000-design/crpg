# movement_range_overlay.gd — Highlights reachable tiles for the active combatant. 3D version.
extends Node3D

const ZocController = preload("res://source/features/turnbased/zoc_controller.gd")

var _grid_world: Node = null
var _reachable_tiles: Array[Vector2i] = []
var _current_unit: Node = null

# Mesh containers for overlay rendering
var _overlay_mesh: MeshInstance3D = null


func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.ap_changed.connect(_on_ap_changed)
	EventBus.combat_ended.connect(_on_combat_ended)

	_overlay_mesh = MeshInstance3D.new()
	_overlay_mesh.name = "MovementOverlayMesh"
	add_child(_overlay_mesh)


func setup(grid_world: Node) -> void:
	_grid_world = grid_world


func _on_turn_started(unit: Node) -> void:
	_current_unit = unit
	if not unit.get("is_player"):
		_reachable_tiles.clear()
		_overlay_mesh.mesh = null
		return
	_compute_reachable(unit)
	_draw_overlay()


func _on_turn_ended(_unit: Node) -> void:
	_current_unit = null
	_reachable_tiles.clear()
	_overlay_mesh.mesh = null


func _on_ap_changed(unit: Node) -> void:
	if unit == _current_unit and is_instance_valid(unit) and unit.get("is_alive"):
		_compute_reachable(unit)
		_draw_overlay()


func _on_combat_ended() -> void:
	_current_unit = null
	_reachable_tiles.clear()
	_overlay_mesh.mesh = null


func _compute_reachable(unit: Node) -> void:
	_reachable_tiles.clear()
	if not _grid_world or not unit:
		return
	if not unit.get("is_alive"):
		return

	var ap: int = unit.get("current_action_points") if "current_action_points" in unit else 0
	if ap <= 0:
		return

	var ap_cost: int = 1
	var movement = unit.get_node_or_null("UnitMovement")
	if movement and "ap_cost_per_tile" in movement:
		ap_cost = movement.ap_cost_per_tile

	var max_steps: int = floor(ap / ap_cost)
	if max_steps <= 0:
		return

	var start_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)

	var visited: Dictionary = {}
	var key_start: String = "%d,%d" % [start_pos.x, start_pos.y]
	visited[key_start] = true

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
			if new_dist < max_steps:
				queue.append({pos = n, dist = new_dist})

	_reachable_tiles.erase(start_pos)


func _draw_overlay() -> void:
	if not _grid_world:
		return

	var is_turn: bool = (GameState.current_mode == GameState.GameMode.TURNBASED)
	if not is_turn:
		_overlay_mesh.mesh = null
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Reachable tiles (green)
	if not _reachable_tiles.is_empty():
		for tile in _reachable_tiles:
			_add_diamond(st, tile, Color(0.3, 0.8, 0.3, 0.3))

	# Player turn: additional overlays
	if _current_unit and _current_unit.get("is_player"):
		_add_blocked_overlay(st)
		_add_zoc_overlay(st)

	st.index()
	st.generate_normals()
	_overlay_mesh.mesh = st.commit()


func _add_diamond(st: SurfaceTool, tile: Vector2i, color: Color) -> void:
	var c: Vector3 = _grid_world.grid_to_world(tile)
	var half_x: float = 0.5
	var half_z: float = 0.5
	var y: float = 0.02  # Slightly above ground

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.flags_unshaded = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	st.set_material(mat)

	# Quad on XZ plane
	st.add_vertex(Vector3(c.x - half_x, y, c.z - half_z))
	st.add_vertex(Vector3(c.x + half_x, y, c.z - half_z))
	st.add_vertex(Vector3(c.x + half_x, y, c.z + half_z))

	st.add_vertex(Vector3(c.x - half_x, y, c.z - half_z))
	st.add_vertex(Vector3(c.x + half_x, y, c.z + half_z))
	st.add_vertex(Vector3(c.x - half_x, y, c.z + half_z))


func _add_blocked_overlay(st: SurfaceTool) -> void:
	if not _grid_world or not _grid_world.has_method("blocked"):
		return
	var blocked: Dictionary = _grid_world.blocked
	for key in blocked:
		var parts: PackedStringArray = key.split(",")
		if parts.size() < 2:
			continue
		var tile := Vector2i(parts[0].to_int(), parts[1].to_int())
		_add_diamond(st, tile, Color(0.8, 0.15, 0.15, 0.25))


func _add_zoc_overlay(st: SurfaceTool) -> void:
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
		if not _grid_world.is_walkable(tile, true):
			continue
		if not _grid_world.is_walkable(tile):
			continue
		_add_diamond(st, tile, Color(0.9, 0.5, 0.1, 0.25))
