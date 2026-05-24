# path_preview.gd — Shows frozen path preview on first mouse click. 3D version.
extends Node3D

var _player: Node = null
var _grid_world: Node = null
var _path: Array[Vector2i] = []
var _preview_mesh: MeshInstance3D = null


func _ready() -> void:
	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.name = "PathPreviewMesh"
	add_child(_preview_mesh)


func setup(grid_world: Node, player_node: Node) -> void:
	_grid_world = grid_world
	_player = player_node


func preview_to(target_grid: Vector2i) -> void:
	if not _grid_world or not _player or not is_instance_valid(_player):
		return
	var from_grid: Vector2i = _grid_world.world_to_grid(_player.global_position)
	if from_grid == target_grid:
		_path.clear()
		visible = false
		_preview_mesh.mesh = null
		return
	_path = _grid_world.find_path_grid(from_grid, target_grid)
	visible = not _path.is_empty()
	_draw_path()


func clear() -> void:
	_path.clear()
	visible = false
	_preview_mesh.mesh = null


func _draw_path() -> void:
	if _path.is_empty() or not _grid_world:
		_preview_mesh.mesh = null
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.4)
	line_mat.flags_unshaded = true
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	st.set_material(line_mat)

	# Line from player through all path points
	var prev_pos: Vector3 = _player.global_position
	for point in _path:
		var world_pos: Vector3 = _grid_world.grid_to_world(point)
		st.add_vertex(prev_pos)
		st.add_vertex(world_pos)
		prev_pos = world_pos

	# Dots at each step
	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
	dot_mat.flags_unshaded = true
	dot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.1
	dot_mesh.height = 0.05

	for point in _path:
		var world_pos: Vector3 = _grid_world.grid_to_world(point)
		var dot := MeshInstance3D.new()
		dot.mesh = dot_mesh
		dot.material_override = dot_mat
		dot.position = Vector3(world_pos.x, 0.05, world_pos.z)
		# Add as sibling, not child of preview_mesh
		if not has_node("Dot_%d_%d" % [point.x, point.y]):
			dot.name = "Dot_%d_%d" % [point.x, point.y]
			add_child(dot)

	st.index()
	_preview_mesh.mesh = st.commit()
