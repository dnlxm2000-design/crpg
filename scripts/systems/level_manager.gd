# LevelManager - Dungeon layer management

extends Node

# Layer enumeration
enum Layer { SURFACE, LAYER1, LAYER2, LAYER3 }

var current_layer: Layer = Layer.SURFACE
var layer_maps: Dictionary = {}

# Layer metadata
var layer_info = {
	Layer.SURFACE: {"name": "실버하벤", "floor_count": 1, "theme": "village"},
	Layer.LAYER1: {"name": "지하 감옥", "floor_count": 3, "theme": "dungeon"},
	Layer.LAYER2: {"name": "고대 유적", "floor_count": 3, "theme": "ruins"},
	Layer.LAYER3: {"name": "심연의 문", "floor_count": 3, "theme": "abyss"}
}

var current_floor: int = 0

func _ready():
	add_to_group("game_systems")
	_generate_layer_maps()

# Generate all layer maps at startup
func _generate_layer_maps():
	for layer_idx in range(Layer.SURFACE, Layer.LAYER3 + 1):
		var floor_count = layer_info[layer_idx]["floor_count"]
		layer_maps[layer_idx] = []
		
		for floor_idx in range(floor_count):
			var map_data = _generate_floor_map(layer_idx, floor_idx)
			layer_maps[layer_idx].append(map_data)

# Generate floor map with tiles, rooms, enemies
func _generate_floor_map(layer_idx: int, floor_idx: int) -> Dictionary:
	var width = 20 + (layer_idx * 5)
	var height = 20 + (layer_idx * 5)
	
	var map_data = {
		"layer": layer_idx,
		"floor": floor_idx,
		"width": width,
		"height": height,
		"tiles": [],
		"rooms": [],
		"enemies": [],
		"items": [],
		"events": []
	}
	
	for y in range(height):
		var row = []
		for x in range(width):
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				row.append(0)
			else:
				row.append(1)
		map_data.tiles.append(row)
	
	_generate_rooms(map_data, layer_idx)
	_spawn_enemies_by_layer(map_data, layer_idx, floor_idx)
	
	return map_data

# Generate random rooms in floor
func _generate_rooms(map_data: Dictionary, layer_idx: int):
	var room_count = 3 + randi_range(0, 2)
	
	for i in range(room_count):
		var room = {
			"x": randi_range(2, map_data.width - 8),
			"y": randi_range(2, map_data.height - 8),
			"width": randi_range(3, 6),
			"height": randi_range(3, 6),
			"type": _get_random_room_type(layer_idx)
		}
		map_data.rooms.append(room)

# Random room type based on layer depth
func _get_random_room_type(layer_idx: int) -> String:
	var types = ["armory", "treasure", "prison", "laboratory", "shrine"]
	if layer_idx >= Layer.LAYER2:
		types.append("boss")
	return types[randi() % types.size()]

# Spawn enemies based on layer difficulty
func _spawn_enemies_by_layer(map_data: Dictionary, layer_idx: int, floor_idx: int):
	var enemy_count = 2 + (layer_idx * 2) + floor_idx
	
	match layer_idx:
		Layer.LAYER1 as int:
			_spawn_basic_enemies(map_data, enemy_count, ["goblin", "skeleton"])
		Layer.LAYER2 as int:
			_spawn_basic_enemies(map_data, enemy_count, ["orc", "dark_elf"])
		Layer.LAYER3 as int:
			_spawn_basic_enemies(map_data, enemy_count, ["shadow_apostle", "void_creature"])

# Spawn random enemies at random positions
func _spawn_basic_enemies(map_data: Dictionary, count: int, types: Array):
	for i in range(count):
		var enemy = {
			"type": types[randi() % types.size()],
			"x": randi_range(2, map_data.width - 2),
			"y": randi_range(2, map_data.height - 2),
			"awake": false
		}
		map_data.enemies.append(enemy)

# Get current map data
func get_current_map() -> Dictionary:
	if layer_maps.has(current_layer) and current_floor < layer_maps[current_layer].size():
		return layer_maps[current_layer][current_floor]
	return {}

# Travel to specific layer and floor
func travel_to_layer(layer_idx: Layer, floor_idx: int = 0):
	current_layer = layer_idx
	current_floor = floor_idx
	print("[던전] ", layer_info[layer_idx]["name"], " - ", floor_idx + 1, "층으로 이동")
	_load_current_layer()

# Move up one floor (or to previous layer)
func travel_up():
	if current_floor > 0:
		current_floor -= 1
		_load_current_layer()
	elif current_layer > Layer.SURFACE:
		var idx = int(current_layer) - 1
		current_layer = idx as Layer
		current_floor = layer_info[current_layer]["floor_count"] - 1
		_load_current_layer()

# Move down one floor (or to next layer)
func travel_down():
	if current_floor < layer_info[current_layer]["floor_count"] - 1:
		current_floor += 1
		_load_current_layer()
	elif current_layer < Layer.LAYER3:
		var idx = int(current_layer) + 1
		current_layer = idx as Layer
		current_floor = 0
		_load_current_layer()

# Load current layer map into game
func _load_current_layer():
	var map_data = get_current_map()
	if map_data.is_empty():
		return
	
	get_tree().call_group("map", "load_map", map_data)
	print("[던전] 로드 완료: ", layer_info[current_layer]["name"])

# Check if layer is unlocked based on scenario completion
func is_layer_unlocked(layer_idx: Layer) -> bool:
	var sm = get_node("/root/StoryManager")
	var idx = int(layer_idx)
	match idx:
		0: return true  # SURFACE
		1: return sm.get_scenario_status(0)  # LAYER1
		2: return sm.get_scenario_status(1)  # LAYER2
		3: return sm.get_scenario_status(2)  # LAYER3
	return false
