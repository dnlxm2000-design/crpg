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
## Use Curve3D-based river carving (true) or linear waypoints (false, fallback).
@export var river_curve_enabled: bool = true
## Riverbed radius at start (narrow).
@export var river_width_start: float = 1.5
## Riverbed radius at end (wide).
@export var river_width_end: float = 3.0
## Bank smoothing radius beyond riverbed edge.
@export var river_bank_width: float = 1.5

var coords: Array[Vector3] = []
## Grid positions of river tiles (for decorator queries)
var river_tiles: Array[Vector2i] = []
## Grid positions of lake tiles (for decorator queries)
var lake_tiles: Array[Vector2i] = []

# ── Lake definitions: center (grid), radius ──
const LAKES: Array[Dictionary] = [
	{center=Vector2i(48, 20), radius=7},   # 큰 호수 (북동쪽)
	{center=Vector2i(18, 72), radius=3},   # 작은 연못 (마을 서쪽, 건물 회피)
	{center=Vector2i(22, 100), radius=8},  # 큰 호수 (남쪽)
]

# ── River definitions: waypoints (grid) ──
const RIVERS: Array[Array] = [
	# 강 1: 북동쪽 호수(48,20) → 마을 동쪽 우회 → 남쪽 호수(22,100)
	# 마을 중심부(24~36, 55~65)는 건물 밀집 지역 — 강은 동쪽으로 우회
	[
		Vector2i(48, 20),
		Vector2i(46, 26), Vector2i(44, 32), Vector2i(42, 40),
		Vector2i(40, 48), Vector2i(41, 56), Vector2i(40, 64),
		Vector2i(37, 72), Vector2i(35, 80), Vector2i(32, 88),
		Vector2i(28, 96), Vector2i(24, 103),
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


## Returns true if the grid tile was carved by a river or lake.
func is_water_tile(gp: Vector2i) -> bool:
	return gp in river_tiles or gp in lake_tiles


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


## Dispatch to selected river carving method.
func _carve_river(waypoints: Array) -> void:
	if waypoints.size() < 2:
		return
	if river_curve_enabled:
		_carve_river_curve(waypoints)
	else:
		_carve_river_linear(waypoints)


## Carve river using Curve3D (Catmull-Rom smooth interpolation).
func _carve_river_curve(waypoints: Array) -> void:
	# Build Curve3D from waypoints (z is height, so waypoint y → curve z)
	var curve := Curve3D.new()
	for i in range(waypoints.size()):
		var wp := waypoints[i] as Vector2i
		var pos := Vector3(float(wp.x * TILE_SIZE), 0.0, float(wp.y * TILE_SIZE))
		curve.add_point(pos)

	curve.bake_interval = 0.5
	var total := curve.get_baked_length()
	var seen: Array[Vector2i] = []
	var step := 0.5  # sample every 0.5 world units

	for d in range(0, ceili(total / step)):
		var t := float(d) * step
		if t > total:
			t = total
		var p := curve.sample_baked(t)
		var gx := clampi(roundi(p.x / TILE_SIZE), 0, map_size.x)
		var gz := clampi(roundi(p.z / TILE_SIZE), 0, map_size.y)

		# Variable width: narrow at start, wide at end
		var progress := t / maxf(total, 0.01)
		var radius := lerpf(river_width_start, river_width_end, progress)

		_carve_river_at_point(Vector2i(gx, gz), radius, seen)


## Carve river using linear waypoint subdivision (fallback).
func _carve_river_linear(waypoints: Array) -> void:
	var river_radius: float = 2.5
	var bank_radius: float = 4.0
	var pts := _subdivide_path(waypoints, 0.5)
	var seen: Array[Vector2i] = []
	for p in pts:
		var gp := Vector2i(clampi(p.x, 0, map_size.x), clampi(p.y, 0, map_size.y))
		_carve_river_at_point(gp, river_radius, seen)


## Carve a single river cross-section at a grid position.
func _carve_river_at_point(gp: Vector2i, river_radius: float, seen: Array[Vector2i]) -> void:
	var sx := map_size.x
	var sz := map_size.y
	var stride := sz + 1
	var bank_radius := river_radius + river_bank_width

	var cx := gp.x
	var cz := gp.y
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
				var variation := (noise.get_noise_2d(float(x) * 0.5, float(z) * 0.5)) * 0.3
				new_y = WATER_HEIGHT + variation
				var tile := Vector2i(x, z)
				if not tile in seen:
					river_tiles.append(tile)
					seen.append(tile)
			elif dist <= bank_radius:
				var t := (dist - river_radius) / (bank_radius - river_radius)
				t = t * t * (3.0 - 2.0 * t)
				new_y = lerp(WATER_HEIGHT, orig_y, t)
			else:
				continue

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
