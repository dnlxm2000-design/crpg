@tool
extends MeshInstance3D

## Terrain mesh generator using vertex-color-based texture blending.
## Based on gd-retroterrain by NickToony (MIT)

const TILE_SIZE: float = 2.0

@export var map_size: Vector2i = Vector2i(63, 126)
@export var noise: FastNoiseLite
@export var smooth: bool = true
@export var grid: bool = true
## Reference to water plane node — auto-created if null.
@export var water_plane: Node3D

## Above this height → grass; height ≤ 0 → sand.
const WATER_HEIGHT: float = -1.5

var coords: Array[Vector3] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_generate()
	_ensure_water_plane()


func _generate() -> void:
	_ensure_noise()
	generate_coords()


func generate_coords() -> void:
	var sx := map_size.x
	var sz := map_size.y
	var stride := sz + 1
	coords.resize((sx + 1) * stride)

	for x in range(sx + 1):
		for z in range(sz + 1):
			var raw: float = noise.get_noise_2d(x, z)
			var h: float = floor(raw * 15.0) / 2.0

			# Flatten map edges to water level so water meets terrain naturally
			if x == 0 or x == sx or z == 0 or z == sz:
				h = WATER_HEIGHT

			coords[x * stride + z] = Vector3(x * TILE_SIZE, h, z * TILE_SIZE)

	generate_mesh()
	_sync_water_plane()


## Auto-create a water plane as a child if none was wired.
func _ensure_water_plane() -> void:
	if water_plane:
		return
	var wp := MeshInstance3D.new()
	wp.name = "WaterPlane"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	quad.subdivide_width = 200
	quad.subdivide_depth = 200
	quad.orientation = 1  # ORIENTATION_Y — horizontal (XZ)
	wp.mesh = quad

	var mat := ShaderMaterial.new()
	var shader := load("res://source/features/shared/effects/water.gdshader")
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("albedo", Color(0.02, 0.38, 0.52))
		mat.set_shader_parameter("albedo2", Color(0.11, 0.27, 0.39))
		mat.set_shader_parameter("color_deep", Color(0.0, 0.2, 0.27))
		mat.set_shader_parameter("color_shallow", Color(0.0, 0.42, 0.56))
	wp.material_override = mat

	add_child(wp)
	water_plane = wp
	_sync_water_plane()


## Position and scale water plane to match terrain bounds.
func _sync_water_plane() -> void:
	if not water_plane:
		return
	var sx := map_size.x
	var sz := map_size.y
	var wsx := sx * TILE_SIZE
	var wsz := sz * TILE_SIZE
	water_plane.position = Vector3(wsx / 2.0, WATER_HEIGHT, wsz / 2.0)
	water_plane.scale = Vector3(wsx, 1, wsz)


func vertex_color(height: float) -> Color:
	if height > 6.0:
		return Color.RED     # rock
	if height > 0.0:
		return Color.BLACK   # grass
	return Color.GREEN       # sand


func generate_mesh() -> void:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var sx := map_size.x
	var sz := map_size.y
	var stride := sz + 1

	for x in range(sx - 1):
		for z in range(sz - 1):
			var coord_id := x * stride + z

			var top_left := coords[coord_id]
			var top_left_uv := Vector2(0, 0)
			var top_right := coords[coord_id + 1]
			var top_right_uv := Vector2(1, 0)
			var bottom_left := coords[coord_id + stride]
			var bottom_left_uv := Vector2(0, 1)
			var bottom_right := coords[coord_id + stride + 1]
			var bottom_right_uv := Vector2(1, 1)

			var vertices: Array[Vector3]
			var uvs: Array[Vector2]

			if triangulation_check(top_left, bottom_right):
				vertices = [
					bottom_left, bottom_right, top_left,
					bottom_right, top_right, top_left,
				]
				uvs = [
					bottom_left_uv, bottom_right_uv, top_left_uv,
					bottom_right_uv, top_right_uv, top_left_uv,
				]
			else:
				vertices = [
					bottom_left, top_right, top_left,
					bottom_left, bottom_right, top_right,
				]
				uvs = [
					bottom_left_uv, top_right_uv, top_left_uv,
					bottom_left_uv, bottom_right_uv, top_right_uv,
				]

			for i in range(vertices.size()):
				surface_tool.set_uv(uvs[i])
				surface_tool.set_color(vertex_color(vertices[i].y))

				if not smooth:
					surface_tool.set_smooth_group(-1)

				surface_tool.add_vertex(vertices[i])

	surface_tool.generate_normals()

	var array_mesh := ArrayMesh.new()
	surface_tool.commit(array_mesh)
	mesh = array_mesh

	# Assign flat-color shader material (no textures needed)
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = load("res://source/features/shared/effects/terrain.gdshader")
	shader_mat.set_shader_parameter("lineThickness", 0.02)
	shader_mat.set_shader_parameter("lineVisibility", 0.5 if grid else 0.0)
	mesh.surface_set_material(0, shader_mat)
	material_override = shader_mat

	print("[Terrain] Generated: ", sx, "x", sz, " tiles")


func triangulation_check(a: Vector3, b: Vector3) -> bool:
	return a.y == b.y


## Get terrain surface height at a world XZ position.
func get_height_at(world_pos: Vector3) -> float:
	_ensure_noise()
	var gx := floori(world_pos.x / TILE_SIZE)
	var gz := floori(world_pos.z / TILE_SIZE)
	gx = clampi(gx, 0, map_size.x - 1)
	gz = clampi(gz, 0, map_size.y - 1)
	var raw: float = noise.get_noise_2d(gx, gz)
	return floor(raw * 15.0) / 2.0


func _ensure_noise() -> void:
	if noise:
		return
	noise = FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.015
