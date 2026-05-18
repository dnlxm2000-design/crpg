# realtime_manager.gd — Manages real-time game mode (exploration, live AI, physics).
# Stoneshard-style: continuous click-to-move, fluid exploration.
extends Node

const ItemData = preload("res://source/data/items/item_data.gd")

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

	# Register on grid
	if _grid_world and _grid_world.has_method("set_occupied"):
		var grid_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)
		_grid_world.set_occupied(grid_pos, unit)


func unregister_unit(unit: Node) -> void:
	units.erase(unit)
	if _grid_world and _grid_world.has_method("set_occupied"):
		var grid_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)
		_grid_world.set_occupied(grid_pos, null)


## Spawn the player unit at a given world position.
## race: 종족 ("Human", "Dwarf", "Elf", "Halfling", "HalfElf", "HalfOrc")
## class_id: 직업 ("fighter", "mage", "ranger", "rogue")
func spawn_player(at_position: Vector2, race: String = "Human", class_id: String = "fighter") -> Node:
	var player = load("res://source/features/shared/unit.gd").new()
	player.unit_name = "Player"
	player.is_player = true
	player.race = race
	player.max_hp = 100
	player.current_hp = 100
	player.speed = 12
	player.max_action_points = 4
	player.current_action_points = 4
	player.corpse_color = Color(0.15, 0.4, 0.7)  # Blue-tinted corpse
	player.global_position = at_position

	# 직업 적용 (스킬 부여 + 스탯 보정)
	var class_def = ClassData.CLASSES.get(class_id)
	if class_def:
		_apply_class_to_unit(player, class_def, class_id)

	# Attach movement component (name "UnitMovement" for PlayerController lookup)
	var movement = load("res://source/features/shared/unit_movement.gd").new()
	movement.name = "UnitMovement"
	movement.move_speed = 120.0
	movement.ap_cost_per_tile = 1
	player.add_child(movement)

	# Attach player controller
	var controller = load("res://source/features/shared/player_controller.gd").new()
	controller.name = "PlayerController"
	player.add_child(controller)

	# Attach inventory component
	var inventory = load("res://source/features/shared/inventory/inventory.gd").new()
	inventory.name = "Inventory"
	player.add_child(inventory)

	# ── 직업 시작 아이템 부여 ──
	_give_starting_items(inventory, class_id)

	# ── Placeholder 시각 요소 ──
	# TODO: setup_placeholder_visual 대신 AnimatedSprite2D + SpriteSheet 로 교체
	player.setup_placeholder_visual(Color(0.2, 0.6, 1.0))
	# z_index 제거: Main의 y_sort에 위임

	# Camera2D (follows player with smooth isometric tracking)
	var camera := Camera2D.new()
	camera.enabled = true
	# 아이소메트릭 월드: 63×126 → x:-4032~2016, y:0~3024
	camera.limit_left = -4032
	camera.limit_top = -512
	camera.limit_right = 2016
	camera.limit_bottom = 3024
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)

	player.name = "PlayerUnit"
	# Main에 직접 추가: y_sort로 지형과 정렬되도록
	var main_node := get_node_or_null("/root/Main")
	if main_node:
		main_node.add_child(player)
	else:
		add_child(player)

	player_ref = player
	register_unit(player)

	print("[RealTimeManager] Player spawned at %s (race=%s, class=%s)" % [at_position, race, class_id])
	return player


## 직업 데이터를 Unit에 적용 (스킬 부여 + 스탯 보정).
func _apply_class_to_unit(unit: Node, class_def: Dictionary, class_id: String) -> void:
	unit.character_class = class_id
	# 스킬 부여
	for skill_id in class_def.skill_levels:
		unit.learned_skills[skill_id] = class_def.skill_levels[skill_id]
	# 스탯 보정 적용
	for attr in class_def.stat_modifiers:
		var current = unit.get(attr)
		unit.set(attr, current + class_def.stat_modifiers[attr])
	# HP 재계산 (CON 보정 반영)
	if unit.has_method("get_max_hp"):
		var new_max = unit.get_max_hp()
		unit.max_hp = new_max
		unit.current_hp = new_max
	print("[RealTimeManager] Class '%s' applied: skills=%s, stats=%s" % [class_id, unit.learned_skills, class_def.stat_modifiers])


## 직업별 시작 아이템을 인벤토리에 추가.
func _give_starting_items(inventory: Node, class_id: String) -> void:
	var starting = ItemData.CLASS_STARTING_ITEMS.get(class_id, [])
	for entry in starting:
		var item_id: String = entry.item_id
		var qty: int = entry.get("quantity", 1)
		var item_def = ItemData.ITEMS.get(item_id)
		if not item_def:
			print("[RealTimeManager] WARNING: unknown starting item '%s'" % item_id)
			continue
		# Create a Resource-based item or dict-based item
		var item_res = _load_item_resource(item_id)
		if item_res:
			for i in qty:
				inventory.add_item(item_res)
		else:
			# Fallback: dict-based item
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


## .tres 리소스에서 아이템 로드 (폴백: dict 기반).
func _load_item_resource(item_id: String) -> Resource:
	var path = "res://source/data/items/resources/%s.tres" % item_id
	if ResourceLoader.exists(path):
		return load(path)
	return null
