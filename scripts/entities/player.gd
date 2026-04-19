extends CharacterBody3D

var grid_position: Vector2i = Vector2i(0, 0)
var current_hp: int = 10
var max_hp: int = 10
var current_ap: int = 10
var max_ap: int = 10
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 300
var xp_table: Array = [0, 300, 900, 2700, 6500, 14000, 23000, 34000, 48000, 64000, 85000, 100000, 120000, 140000, 165000, 195000, 225000, 265000, 305000, 355000]

var move_range: int = 5
var attack_range: int = 1
var current_path: Array = []
var path_index: int = 0
var input_direction: Vector2 = Vector2.ZERO
var tile_size: float = 2.0
var move_speed: float = 5.0

var initiative: int = 0
var character_class: String = "fighter"
var stealth_level: int = 0

var equipped_weapon: Dictionary = {}
var equipped_armor: Dictionary = {}
var equipped_shield: Dictionary = {}
var base_ac: int = 10
var weapon_damage: String = "1d6"
var attack_bonus: int = 0

var stats = {"str": 10, "dex": 14, "con": 12, "int": 10, "wis": 10, "cha": 10}

func _ready():
	add_to_group("players")
	equipped_weapon = {"id": "shortsword", "damage": "1d6"}
	equipped_armor = {"id": "leather", "ac": 11}
	equipped_shield = {}

func _physics_process(delta):
	if input_direction != Vector2.ZERO:
		var dir = Vector3(input_direction.x, 0, input_direction.y).normalized()
		velocity = dir * move_speed
		move_and_slide()
		grid_position = Vector2i(round(global_position.x / tile_size), round(global_position.z / tile_size))
	else:
		velocity = Vector3.ZERO

func _unhandled_input(event):
	var ix = 0
	var iy = 0
	if event.is_action_pressed("ui_left"): ix -= 1
	if event.is_action_pressed("ui_right"): ix += 1
	if event.is_action_pressed("ui_up"): iy -= 1
	if event.is_action_pressed("ui_down"): iy += 1
	input_direction = Vector2(ix, iy)

func set_path(path: Array):
	current_path = path
	path_index = 0

func move_along_path() -> bool:
	if path_index >= current_path.size():
		current_path.clear()
		return false
	var next_pos = current_path[path_index]
	path_index += 1
	global_position = Vector3(next_pos.x * tile_size, 0.5, next_pos.y * tile_size)
	grid_position = next_pos
	return true

func process_turn():
	current_ap = max_ap
	restore_ap(max_ap / 2)

func roll_initiative():
	initiative = randi_range(1, 20) + get_ability_modifier("dex")

func on_round_start():
	current_ap = max_ap
	restore_ap(max_ap / 2)

func can_move_to(tile_cost: int, distance: int) -> bool:
	if tile_cost < 0: return false
	if distance > move_range: return false
	if current_ap < tile_cost: return false
	return true

func get_ability_modifier(stat_name: String) -> int:
	var stat = stats.get(stat_name, 10)
	return floor((stat - 10) / 2)

func restore_ap(amount: int):
	current_ap = min(current_ap + amount, max_ap)

func use_ap(cost: int) -> bool:
	if current_ap >= cost:
		current_ap -= cost
		return true
	return false

func add_xp(amount: int) -> bool:
	current_xp += amount
	if level < xp_table.size() and current_xp >= xp_table[level]:
		level += 1
		xp_to_next_level = xp_table[level] if level < xp_table.size() else -1
		max_hp += randi_range(2, 8)
		current_hp = max_hp
		return true
	return false

func take_damage(amount: int) -> bool:
	current_hp -= amount
	return current_hp <= 0
