extends CharacterBody3D

signal died()
signal turn_ended()

@export var enemy_name: String = "Goblin"
@export var cr: float = 0.25
@export var xp_reward: int = 50

var character_name: String = "Goblin"
var grid_position: Vector2i = Vector2i(0, 0)
var current_hp: int = 10
var max_hp: int = 10
var current_ap: int = 10
var max_ap: int = 10
var stats = {"str": 10, "dex": 10, "con": 10, "int": 10, "wis": 10, "cha": 10}

var initiative: int = 0
var aggro_range: int = 10
var attack_range: int = 1
var tile_size: float = 2.0

func _init():
	add_to_group("enemies")

func _ready():
	character_name = enemy_name

func get_ability_modifier(stat_name: String) -> int:
	var stat = stats.get(stat_name, 10)
	return floor((stat - 10) / 2)

func roll_initiative():
	initiative = randi_range(1, 20) + get_ability_modifier("dex")

func on_round_start():
	current_ap = max_ap
	restore_ap(max_ap / 2)

func restore_ap(amount: int):
	current_ap = min(current_ap + amount, max_ap)

func take_ai_turn():
	var targets = get_tree().get_nodes_in_group("players")
	if targets.size() == 0:
		return
	
	var nearest = _find_nearest_target(targets)
	if not nearest:
		return
	
	var distance = _get_distance_to(nearest)
	
	if distance <= attack_range:
		_attack_target(nearest)
	else:
		_move_toward(nearest.grid_position)
	
	turn_ended.emit()

func _find_nearest_target(targets: Array) -> Node:
	var nearest = null
	var min_dist = 9999
	for t in targets:
		var dist = _get_distance_to(t)
		if dist < min_dist:
			min_dist = dist
			nearest = t
	return nearest

func _get_distance_to(target: Node) -> int:
	return abs(grid_position.x - target.grid_position.x) + abs(grid_position.y - target.grid_position.y)

func _attack_target(target: Node):
	if current_ap < 2:
		return
	
	current_ap -= 2
	var attack_roll = randi_range(1, 20) + get_ability_modifier("dex") + 2
	var damage = randi_range(1, 6) + get_ability_modifier("str")
	
	print("Enemy attacks: roll=%d, damage=%d" % [attack_roll, damage])
	
	target.take_damage(damage)

func _move_toward(target_pos: Vector2i):
	if current_ap < 1:
		return
	
	current_ap -= 1
	var dx = target_pos.x - grid_position.x
	var dy = target_pos.y - grid_position.y
	
	if abs(dx) > abs(dy):
		grid_position.x += sign(dx)
	else:
		grid_position.y += sign(dy)
	
	global_position = Vector3(grid_position.x * tile_size, 0.5, grid_position.y * tile_size)

func take_damage(amount: int) -> bool:
	current_hp -= amount
	if current_hp <= 0:
		died.emit()
		var players = get_tree().get_nodes_in_group("players")
		for p in players:
			if p.has_method("add_xp"):
				p.add_xp(xp_reward)
		queue_free()
		return true
	return false
	if distance <= attack_range:
		_attack(nearest)
	# Move toward if within aggro range
	elif distance <= aggro_range:
		_move_toward(nearest.grid_position)
	
	turn_ended.emit()

# Find nearest player by distance
func _find_nearest_target(targets: Array) -> Node:
	var nearest = null
	var min_dist = 9999
	for t in targets:
		var dist = _get_distance_to(t)
		if dist < min_dist:
			min_dist = dist
			nearest = t
	return nearest

# Calculate grid distance (Manhattan distance)
func _get_distance_to(target: Node) -> int:
	return abs(grid_position.x - target.grid_position.x) + abs(grid_position.y - target.grid_position.y)

# Move toward target using pathfinding
func _move_toward(target_pos: Vector2i):
	var pathfinding = get_tree().get_first_node_in_group("pathfinding")
	if not pathfinding:
		_try_simple_move(target_pos)
		return
	
	var walkable_map = _get_walkable_map()
	if walkable_map.is_empty():
		_try_simple_move(target_pos)
		return
	
	# Find path and move
	var path = pathfinding.find_path(grid_position, target_pos, walkable_map)
	if path.size() > 0 and path.size() - 1 <= current_ap:
		var move_steps = min(path.size() - 1, current_ap)
		for i in range(move_steps):
			if current_ap >= 1:
				var next_pos = path[i + 1]
				var world_pos = Vector3(next_pos.x * tile_size, 0.5, next_pos.y * tile_size)
				global_position = global_position.lerp(world_pos, 0.5)
				grid_position = next_pos
				use_ap(1)
				await get_tree().create_timer(0.2).timeout

# Simple movement fallback (no pathfinding)
func _try_simple_move(target_pos: Vector2i):
	var dx = target_pos.x - grid_position.x
	var dy = target_pos.y - grid_position.y
	if abs(dx) >= abs(dy):
		grid_position.x += sign(dx)
	else:
		grid_position.y += sign(dy)
	global_position = Vector3(grid_position.x * tile_size, 0.5, grid_position.y * tile_size)

# Get walkable map from main controller
func _get_walkable_map() -> Array:
	var main = get_tree().get_first_node_in_group("main")
	if main and "walkable_map" in main:
		return main.walkable_map
	return []

# Attack target
func _attack(target: Node):
	if use_ap(2):  # Attack costs 2 AP
		var damage = _calculate_damage()
		target.take_damage(damage)
		print(character_name, " attacks ", target.character_name, " for ", damage, " damage")
		if target.current_hp <= 0:
			target.died.emit()

# Calculate melee damage (1d6 + STR mod)
func _calculate_damage() -> int:
	return randi_range(1, 6) + get_ability_modifier("str")

# Override take_damage for death handling
func take_damage(amount: int) -> bool:
	var result = super.take_damage(amount)
	if current_hp <= 0:
		died.emit()
		_award_xp_to_player()
		queue_free()
	return result

func _award_xp_to_player():
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.has_method("add_xp"):
			var leveled_up = p.add_xp(xp_reward)
			if leveled_up:
				print("[LEVEL UP] ", p.character_name, " reached level ", p.level)