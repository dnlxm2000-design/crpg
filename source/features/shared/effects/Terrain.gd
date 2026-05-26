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
## Water feature carving enabled.
@export var features_enabled: bool = true

var coords: Array[Vector3] = []
## Grid positions of river tiles (for decorator queries)
var river_tiles: Array[Vector2i] = []
## Grid positions of lake tiles (for decorator queries)
var lake_tiles: Array[Vector2i] = []

# ── Lake definitions: center (grid), radius ──
const LAKES: Array[Dictionary] = [
	{center=Vector2i(48, 20), radius=7},   # 큰 호수 (북동쪽)
	{center=Vector2i(25, 58), radius=3},   # 작은 연못 (마을 서쪽)
	{center=Vector2i(22, 100), radius=8},  # 큰 호수 (남쪽)
]

# ── River definitions: waypoints (grid) ──
const RIVERS: Array[Array] = [
	# 강 1: 북동쪽 호수 → 마을 동쪽 → 남쪽
	[
		Vector2i(48, 20),
		Vector2i(44, 26), Vector2i(40, 32), Vector2i(38, 40),
		Vector2i(36, 48), Vector2i(34, 56), Vector2i(33, 64),
		Vector2i(32, 72), Vector2i(30, 80), Vector2i(28, 88),
		Vector2i(26, 96), Vector2i(23, 103),
	],
]


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

	# ── Carve lakes and rivers ──
	if features_enabled:
		_apply_water_features()

	generate_mesh()
	_sync_water_plane()


# ══════════════════════════════════════════════
#  Water feature carving (lakes + rivers)
# ══════════════════════════════════════════════

func _apply_water_features() -> void:
	for lake in LAKES:
		_carve_lake(lake.center, lake.radius)
	for river_points in RIVERS:
		_carve_river(river_points)


## Carve a circular lake depression into the heightmap.
func _carve_lake(center: Vector2i, radius: int) -> void:
	var sx := map_size.x
	var sz := map_size.y
	var stride := sz + 1
	var inner := float(radius)
	var outer := inner + 2.0

	var x0 := maxi(0, center.x - radius - 3)
	var x1 := mini(sx, center.x + radius + 3)
	var z0 := maxi(0, center.y - radius - 3)
	var z1 := mini(sz, center.y + radius + 3)

	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var dx := x - center.x
			var dz := z - center.y
			var dist := sqrt(float(dx * dx + dz * dz))

			var idx := x * stride + z
			var orig_y := coords[idx].y

			var new_y: float
			if dist <= inner:
				new_y = WATER_HEIGHT
				lake_tiles.append(Vector2i(x, z))
			elif dist < outer:
				var t := (dist - inner) / (outer - inner)
				t = t * t * (3.0 - 2.0 * t)  # smoothstep
				new_y = lerp(WATER_HEIGHT, orig_y, t)
			else:
				continue

			coords[idx] = Vector3(coords[idx].x, new_y, coords[idx].z)


## Carve a river channel along a list of waypoints.
func _carve_river(waypoints: Array) -> void:
	if waypoints.size() < 2:
		return
	var sx := map_size.x
	var sz := map_size.y
	var stride := sz + 1

	# River carving radius (half-width in tiles)
	var river_radius: float = 2.5
	var bank_radius: float = 4.0

	# Subdivide waypoints for smooth curves
	var pts := _subdivide_path(waypoints, 0.5)

	# For each river point, carve a circle
	var seen: Array[Vector2i] = []
	for p in pts:
		var cx := clampi(p.x, 0, sx)
		var cz := clampi(p.y, 0, sz)
		var x0 := maxi(0, cx - ceili(bank_radius))
		var x1 := mini(sx, cx + ceili(bank_radius))
		var z0 := maxi(0, cz - ceili(bank_radius))
		var z1 := mini(sz, cz + ceili(bank_radius))

		for x in range(x0, x1 + 1):
			for z in range(z0, z1 + 1):
				var dx := x - cx
				var dz := z - cz
				var dist := sqrt(float(dx * dx + dz * dz))

				if dist > bank_radius:
					continue

				var idx := x * stride + z
				var orig_y := coords[idx].y
				var new_y: float

				if dist <= river_radius:
					# Riverbed: at water level with slight variation
					var variation := (noise.get_noise_2d(float(x) * 0.5, float(z) * 0.5)) * 0.3
					new_y = WATER_HEIGHT + variation
					var gp := Vector2i(x, z)
					if not gp in seen:
						river_tiles.append(gp)
						seen.append(gp)
				elif dist <= bank_radius:
					# Bank: smooth rise to terrain
					var t := (dist - river_radius) / (bank_radius - river_radius)
					t = t * t * (3.0 - 2.0 * t)
					new_y = lerp(WATER_HEIGHT, orig_y, t)
				else:
					continue

				# Only lower, never raise terrain
				if new_y < orig_y:
					coords[idx] = Vector3(coords[idx].x, new_y, coords[idx].z)


## Subdivide a polyline path by inserting interpolated points.
func _subdivide_path(points: Array, step: float) -> Array:
	var result: Array = []
	if points.is_empty():
		return result
	result.append(points[0])
	for i in range(1, points.size()):
		var a := points[i - 1] as Vector2i
		var b := points[i] as Vector2i
		var dx := float(b.x - a.x)
		var dz := float(b.y - a.y)
		var seg_len := sqrt(dx * dx + dz * dz)
		var steps := maxi(1, ceili(seg_len / step))
		for j in range(1, steps):
			var t := float(j) / float(steps)
			var px := roundi(float(a.x) + dx * t)
			var pz := roundi(float(a.y) + dz * t)
			result.append(Vector2i(px, pz))
		result.append(b)
	return result


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
