# map_decorator.gd — Places KayKit 3D buildings and decorations on the terrain grid.
# Called after terrain generation to populate the world.
extends Node
class_name MapDecorator

## Building placement data: grid position, model path, scale, Y rotation.
const BUILDINGS: Array[Dictionary] = [
	# ── Village center (near player spawn at grid 30,61) ──
	{grid=Vector2i(28,58), path="green/building_tavern_green", scale=1.6, rot=0.0},
	{grid=Vector2i(32,58), path="blue/building_church_blue", scale=1.6, rot=0.0},
	{grid=Vector2i(28,62), path="green/building_home_A_green", scale=1.4, rot=0.0},
	{grid=Vector2i(32,62), path="green/building_home_B_green", scale=1.4, rot=0.0},
	{grid=Vector2i(26,60), path="neutral/building_destroyed", scale=1.4, rot=0.0},
	{grid=Vector2i(34,60), path="blue/building_blacksmith_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(30,55), path="blue/building_barracks_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(30,65), path="green/building_well_green", scale=1.3, rot=0.0},
	# ── Outskirts ──
	{grid=Vector2i(24,55), path="blue/building_lumbermill_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(36,65), path="blue/building_windmill_blue", scale=1.5, rot=0.0},
	# ── Towers (defense) ──
	{grid=Vector2i(23,50), path="green/building_tower_A_green", scale=1.5, rot=0.0},
	{grid=Vector2i(37,70), path="blue/building_tower_B_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(37,50), path="blue/building_tower_base_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(40,58), path="blue/building_watermill_blue", scale=1.5, rot=0.0},
]

## Decoration scatter config.
const NATURE_DECORATIONS: Array[Dictionary] = [
	{path="nature/trees_A_small", scale=0.8, weight=12},
	{path="nature/trees_A_medium", scale=0.9, weight=8},
	{path="nature/trees_A_large", scale=1.0, weight=4},
	{path="nature/trees_B_small", scale=0.8, weight=10},
	{path="nature/trees_B_medium", scale=0.9, weight=6},
	{path="nature/trees_B_large", scale=1.0, weight=3},
	{path="nature/tree_single_A", scale=0.7, weight=5},
	{path="nature/tree_single_B", scale=0.7, weight=4},
	{path="nature/hill_single_A", scale=0.6, weight=3},
	{path="nature/hill_single_B", scale=0.6, weight=2},
	{path="nature/rock_single_A", scale=0.5, weight=3},
	{path="nature/rock_single_B", scale=0.5, weight=2},
	{path="nature/rock_single_C", scale=0.5, weight=2},
	{path="nature/rock_single_D", scale=0.5, weight=1},
	{path="nature/rock_single_E", scale=0.5, weight=1},
	{path="props/barrel", scale=0.5, weight=1},
	{path="props/crate_A_small", scale=0.5, weight=1},
	{path="props/sack", scale=0.5, weight=1},
]

const GLTF_BASE: String = "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/"
const DECO_BASE: String = "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/"

## Scatter density: tiles checked per decoration (larger = sparser).
@export var scatter_step: int = 4
@export var scatter_padding: int = 3  # tiles from map edge
@export var village_radius: int = 6  # tiles around center kept clear of nature

var _grid_world: Node = null
var _terrain: Node = null
var _rng: RandomNumberGenerator = null


func decorate(grid_world: Node, terrain_node: Node) -> void:
	if not grid_world or not terrain_node:
		push_error("[MapDecorator] grid_world or terrain missing")
		return

	_grid_world = grid_world
	_terrain = terrain_node
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	print("[MapDecorator] Placing buildings...")
	for b in BUILDINGS:
		_place_building(b)

	print("[MapDecorator] Scattering decorations...")
	_scatter_nature()

	print("[MapDecorator] Done — %d buildings + nature decorations" % [BUILDINGS.size()])


## Place a single building on the grid.
func _place_building(b: Dictionary) -> void:
	var full_path: String = GLTF_BASE + b.path + ".gltf"
	var model = load(full_path)
	if not model:
		push_warning("[MapDecorator] Skipping (open Godot editor to generate .import): %s" % full_path)
		return

	var instance: Node3D = model.instantiate()
	if not instance:
		return

	var world_pos: Vector3 = _grid_world.grid_to_world(b.grid)
	world_pos.y = _get_height_at(world_pos)
	instance.position = world_pos
	if b.has("scale"):
		instance.scale = Vector3(b.scale, b.scale, b.scale)
	if b.has("rot"):
		instance.rotation.y = b.rot

	add_child(instance)
	_grid_world.set_blocked(b.grid, true)


## Scatter trees, rocks, and props across unoccupied terrain tiles.
func _scatter_nature() -> void:
	var total_weights: int = 0
	for d in NATURE_DECORATIONS:
		total_weights += d.weight
	if total_weights <= 0:
		return

	# Village center — no nature scatter here
	var center: Vector2i = Vector2i(30, 60)

	var sx: int = _grid_world.grid_width if "grid_width" in _grid_world else 63
	var sz: int = _grid_world.grid_height if "grid_height" in _grid_world else 126

	for x in range(scatter_padding, sx - scatter_padding, scatter_step):
		for z in range(scatter_padding, sz - scatter_padding, scatter_step):
			var gp := Vector2i(x, z)

			# Skip village area
			var dx: int = abs(x - center.x)
			var dz: int = abs(z - center.y)
			if dx <= village_radius and dz <= village_radius:
				continue

			# Skip occupied/blocked/walkable? try to place only on walkable grass
			if not _grid_world.is_walkable(gp, true):
				continue

			# Skip water tiles (height ≤ WATER_HEIGHT)
			var wp: Vector3 = _grid_world.grid_to_world(gp)
			if _get_height_at(wp) <= -1.0:
				continue

			# Random chance (50%) to place something
			if _rng.randf() > 0.5:
				continue

			# Pick weighted random decoration
			var roll: int = _rng.randi_range(0, total_weights - 1)
			var accumulated: int = 0
			var chosen: Dictionary = NATURE_DECORATIONS[0]  # fallback
			for d in NATURE_DECORATIONS:
				accumulated += d.weight
				if roll < accumulated:
					chosen = d
					break

			_place_decoration(gp, chosen)


func _place_decoration(gp: Vector2i, d: Dictionary) -> void:
	var full_path: String = DECO_BASE + d.path + ".gltf"
	var model = load(full_path)
	if not model:
		return

	var instance: Node3D = model.instantiate()
	if not instance:
		return

	var world_pos: Vector3 = _grid_world.grid_to_world(gp)
	world_pos.y = _get_height_at(world_pos)
	instance.position = world_pos
	var s: float = d.get("scale", 1.0)
	instance.scale = Vector3(s, s, s)
	instance.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(instance)


func _get_height_at(world_pos: Vector3) -> float:
	if _terrain and _terrain.has_method("get_height_at"):
		return _terrain.get_height_at(world_pos)
	return world_pos.y
