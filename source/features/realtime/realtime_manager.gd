# realtime_manager.gd — Manages real-time game mode (exploration, live AI, physics).
# Stoneshard-style: continuous click-to-move, fluid exploration.
extends Node

## Is real-time mode currently active?
var active: bool = false

## All units in the real-time world.
var units: Array = []

## Reference to spawned player unit (for test/combat access).
var player_ref: Node = null

var _grid_world: Node = null


func _ready() -> void:
	_grid_world = get_node_or_null("../GameLoop/GridWorld")
	if not _grid_world:
		_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")


func enter() -> void:
	active = true
	print("[RealTimeManager] Real-time mode activated")


func exit() -> void:
	active = false
	print("[RealTimeManager] Real-time mode deactivated")


func register_unit(unit: Node) -> void:
	if unit not in units:
		units.append(unit)
	if _grid_world and _grid_world.has_method("set_occupied"):
		var grid_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)
		_grid_world.set_occupied(grid_pos, unit)


func unregister_unit(unit: Node) -> void:
	units.erase(unit)
	if _grid_world and _grid_world.has_method("set_occupied"):
		var grid_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)
		_grid_world.set_occupied(grid_pos, null)


## Spawn the player unit at a given world position.
func spawn_player(at_position: Vector3, race: String = "Human", class_id: String = "fighter") -> Node:
	var player = load("res://source/features/shared/unit.gd").new()
	player.unit_name = "Player"
	player.is_player = true
	player.race = race
	player.max_hp = 100
	player.current_hp = 100
	player.speed = 12
	player.max_action_points = 4
	player.current_action_points = 4
	player.corpse_color = Color(0.15, 0.4, 0.7)

	# Terrain height Y adjustment
	var terrain_h: float = _get_terrain_height_at(at_position)
	print("[RealTimeManager] Terrain height at spawn: ", terrain_h)
	player.position = Vector3(at_position.x, terrain_h, at_position.z)

	# Class application
	var class_def = ClassData.classes().get(class_id)
	if class_def:
		_apply_class_to_unit(player, class_def, class_id)

	# Movement component
	var movement = load("res://source/features/shared/unit_movement.gd").new()
	movement.name = "UnitMovement"
	movement.move_speed = 4.0
	movement.ap_cost_per_tile = 1
	player.add_child(movement)

	# Player controller
	var controller = load("res://source/features/shared/player_controller.gd").new()
	controller.name = "PlayerController"
	player.add_child(controller)

	# Inventory
	var inventory = load("res://source/features/shared/inventory/inventory.gd").new()
	inventory.name = "Inventory"
	player.add_child(inventory)

	_give_starting_items(inventory, class_id)

	player.setup_placeholder_visual(Color(0.2, 0.6, 1.0))

	player.name = "PlayerUnit"
	var main_node := get_node_or_null("/root/Main")
	if main_node:
		main_node.add_child(player)

		# Camera3D — Main direct child, follows player via script
		var camera := Camera3D.new()
		camera.name = "Camera3D"
		camera.current = true
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 10.0
		camera.near = 0.1
		camera.far = 500.0
		camera.rotation_degrees = Vector3(-60, 45.0, 0.0)
		camera.position = Vector3(at_position.x, 6.0, at_position.z)

		camera.set_script(load("res://source/features/shared/effects/camera_follow.gd"))
		camera.set_meta("follow_target", player)
		main_node.add_child(camera)
	else:
		add_child(player)

	player_ref = player
	register_unit(player)

	print("[RealTimeManager] Player spawned at %s (race=%s, class=%s)" % [at_position, race, class_id])
	return player


func _apply_class_to_unit(unit: Node, class_def: Dictionary, class_id: String) -> void:
	unit.character_class = class_id
	for skill_id in class_def.skill_levels:
		unit.learned_skills[skill_id] = class_def.skill_levels[skill_id]
	for attr in class_def.stat_modifiers:
		var current = unit.get(attr)
		unit.set(attr, current + class_def.stat_modifiers[attr])
	if unit.has_method("get_max_hp"):
		var new_max = unit.get_max_hp()
		unit.max_hp = new_max
		unit.current_hp = new_max
	print("[RealTimeManager] Class '%s' applied: skills=%s, stats=%s" % [class_id, unit.learned_skills, class_def.stat_modifiers])


func _give_starting_items(inventory: Node, class_id: String) -> void:
	var starting = ItemData.class_starting_items().get(class_id, [])
	for entry in starting:
		var item_id: String = entry.item_id
		var qty: int = entry.get("quantity", 1)
		var item_def = ItemData.items().get(item_id)
		if not item_def:
			print("[RealTimeManager] WARNING: unknown starting item '%s'" % item_id)
			continue
		var item_res = _load_item_resource(item_id)
		if item_res:
			for i in qty:
				inventory.add_item(item_res)
		else:
			var item_dict = {
				"id": item_id,
				"item_name": item_def.get("name", item_id),
				"description": item_def.get("description", ""),
				"item_type": item_def.get("type", 0),
				"value": item_def.get("value", 0),
				"heal_amount": item_def.get("heal_amount", 0),
				"ap_cost": item_def.get("ap_cost", 1),
				"stackable": item_def.get("stackable", true),
				"damage_bonus": item_def.get("damage_bonus", 0),
				"defense_bonus": item_def.get("defense_bonus", 0),
				"accuracy_bonus": item_def.get("accuracy_bonus", 0),
				"evasion_bonus": item_def.get("evasion_bonus", 0),
				"weapon_subtype": item_def.get("weapon_subtype", ""),
				"weapon_class": item_def.get("weapon_class", ""),
				"range": item_def.get("range", 1),
				"ammo_type": item_def.get("ammo_type", ""),
			}
			for i in qty:
				inventory.add_item_dict(item_dict)
	print("[RealTimeManager] Starting items for '%s': %d types, %d total" % [class_id, starting.size(), starting.reduce(func(acc, e): return acc + e.get("quantity", 1), 0)])


func _load_item_resource(item_id: String) -> Resource:
	var path = "res://source/data/items/resources/%s.tres" % item_id
	if ResourceLoader.exists(path):
		return load(path)
	return null


## Get terrain height at world position.
func _get_terrain_height_at(world_pos: Vector3) -> float:
	var terrain := get_node_or_null("/root/Main/Terrain")
	if not terrain or not terrain.has_method("get_height_at"):
		var gw := get_node_or_null("/root/Main/GameLoop/GridWorld")
		if gw:
			var grid_pos: Vector2i = gw.world_to_grid(world_pos)
			var elev: int = gw.get_elevation(grid_pos)
			return float(elev) * 1.5
		return 0.0
	return terrain.get_height_at(world_pos)


## Create basic environment with procedural sky.
func _create_basic_environment() -> Environment:
	var env: Environment = Environment.new()
	
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.1, 0.4, 0.8)
	sky_mat.sky_horizon_color = Color(0.6, 0.8, 1.0)
	sky_mat.ground_horizon_color = Color(0.2, 0.4, 0.2)
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6

	return env
