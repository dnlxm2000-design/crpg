@tool
extends EditorScript

# ── Baking configuration ──
# Matches the BUILDINGS array in map_decorator.gd
const GLTF_BASE: String = "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/"
const BUILDINGS: Array[Dictionary] = [
	# ── Village center (MOUSEDON - 강 안쪽 곡면에 군집) ──
	# 강 대각선: (10,20)→(45,80), 마을 중심: (28,42)
	{grid=Vector2i(26,40), path="green/building_tavern_green", scale=1.6, rot=0.0},
	{grid=Vector2i(30,38), path="blue/building_church_blue", scale=1.6, rot=0.0},
	{grid=Vector2i(28,42), path="green/building_home_A_green", scale=1.4, rot=0.0},
	{grid=Vector2i(30,42), path="green/building_home_B_green", scale=1.4, rot=0.0},
	{grid=Vector2i(24,42), path="neutral/building_destroyed", scale=1.4, rot=0.0},
	{grid=Vector2i(32,40), path="blue/building_blacksmith_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(28,36), path="blue/building_barracks_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(28,44), path="green/building_well_green", scale=1.3, rot=0.0},
	# ── Outskirts (강 근처) ──
	{grid=Vector2i(24,36), path="blue/building_lumbermill_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(34,44), path="blue/building_windmill_blue", scale=1.5, rot=0.0},
	# ── Towers (defense - 외곽) ──
	{grid=Vector2i(20,32), path="green/building_tower_A_green", scale=1.5, rot=0.0},
	{grid=Vector2i(38,52), path="blue/building_tower_B_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(36,36), path="blue/building_tower_base_blue", scale=1.5, rot=0.0},
	{grid=Vector2i(36,48), path="blue/building_watermill_blue", scale=1.5, rot=0.0},
]

const TILE_SIZE: float = 2.0


func _run() -> void:
	var scene_root := get_scene()
	if not scene_root:
		print("[BakeBuildings] No scene open. Open main.tscn first.")
		return

	print("[BakeBuildings] Baking into scene: %s" % scene_root.scene_file_path)

	# Remove previous "Buildings" node if exists
	var buildings_parent: Node = scene_root.get_node_or_null("Buildings")
	if buildings_parent:
		print("[BakeBuildings] Removing previous Buildings node...")
		scene_root.remove_child(buildings_parent)
		buildings_parent.queue_free()

	# Create the parent node
	buildings_parent = Node3D.new()
	buildings_parent.name = "Buildings"
	scene_root.add_child(buildings_parent, true)
	buildings_parent.set_owner(scene_root)

	# Find Terrain node for height sampling
	var terrain_node: Node = scene_root.get_node_or_null("Terrain")

	var placed := 0
	for b in BUILDINGS:
		var full_path: String = GLTF_BASE + b.path + ".gltf"
		var packed := load(full_path) as PackedScene
		if not packed:
			print("[BakeBuildings] WARNING: Cannot load %s — run the editor once to import GLTF files." % full_path)
			continue

		var instance := packed.instantiate() as Node3D
		if not instance:
			continue

		# World position (same math as GridWorld.grid_to_world)
		var world_pos := Vector3(b.grid.x * TILE_SIZE, 0.0, b.grid.y * TILE_SIZE)
		if terrain_node and terrain_node.has_method("get_height_at"):
			world_pos.y = terrain_node.get_height_at(world_pos)

		instance.position = world_pos
		if b.has("scale") and typeof(b.scale) == TYPE_FLOAT:
			var s := b.scale as float
			instance.scale = Vector3(s, s, s)
		if b.has("rot") and typeof(b.rot) == TYPE_FLOAT:
			instance.rotation.y = b.rot as float

		# Readable name
		var name_parts: PackedStringArray = b.path.split("/")
		instance.name = "Building_%s" % name_parts[-1]

		buildings_parent.add_child(instance, true)
		_set_owner_recursive(instance, scene_root)
		placed += 1

	if placed > 0:
		print("[BakeBuildings] SUCCESS: %d buildings placed under 'Buildings' node." % placed)
		print("[BakeBuildings] Save the scene (Ctrl+S) to persist.")
	else:
		print("[BakeBuildings] No buildings were placed. Check GLTF paths.")
		buildings_parent.queue_free()


static func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)
