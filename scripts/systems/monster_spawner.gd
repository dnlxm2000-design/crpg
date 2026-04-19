# MonsterSpawner - Session-based monster spawning system

extends Node

var world_sim: Node = null
var base_monsters_data: Dictionary = {}
var session_monsters_data: Dictionary = {}

const DEFAULT_SPAWN_COUNT = 3
const MAX_LAYER_MONSTERS = 10

enum SpawnCategory {
	BEAST,
	HUMANOID,
	UNDEAD,
	ABERRATION,
	FIEND,
	CONSTRUCT,
	MIXED
}

var layer_monster_pools = {
	0: { # Surface (Silverhaven)
		"primary": [],
		"secondary": ["rabbit", "deer"]
	},
	1: { # Layer 1: Underground Prison
		"primary": ["goblin", "skeleton", "kobold"],
		"secondary": ["rat", "giant_spider", "zombie"]
	},
	2: { # Layer 2: Ancient Ruins
		"primary": ["orc", "dark_elf", "bugbear"],
		"secondary": ["wolf", "boar", "ghoul"]
	},
	3: { # Layer 3: Abyss Gate
		"primary": ["mind_flayer_minion", "shadow_apostle"],
		"secondary": ["demon_hunter", "void_construct", "abyssal_spawn"]
	}
}

func _ready():
	_load_data()

func _load_data():
	var file = FileAccess.open("res://data/monsters.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if json and json is Dictionary:
			base_monsters_data = json.get("monsters", {})
	
	if base_monsters_data.is_empty():
		base_monsters_data = _get_default_monsters()
	
	file = FileAccess.open("res://data/monsters_session.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if json and json is Dictionary:
			session_monsters_data = json.get("session_monsters", {})

func _get_default_monsters() -> Dictionary:
	return {
		"goblin": {"name": "고블린", "cr": "0.25", "hp": 7, "ac": 15, "attack": "1d6+3", "xp": 50},
		"skeleton": {"name": "스켈레톤", "cr": "0.25", "hp": 13, "ac": 13, "attack": "1d6+2", "xp": 50},
		"zombie": {"name": "좀비", "cr": "0.25", "hp": 22, "ac": 8, "attack": "1d6+1", "xp": 50}
	}

func set_world_simulation(ref: Node):
	world_sim = ref

func calculate_spawn_count(layer_idx: int, base_count: int = DEFAULT_SPAWN_COUNT) -> int:
	if not world_sim:
		return base_count
	
	var fog = world_sim.fog_density
	var orc = world_sim.orc_disposition
	var grid = world_sim.grid_resonance
	
	var fog_mod = 1.0 + (fog * 0.3) if fog >= 0.7 else 1.0
	var orc_mod = 1.0 + ((orc - 3) * 0.2) if orc >= 4 else 1.0
	var grid_mod = 1.0 + (grid * 0.3) if grid >= 0.7 else 1.0
	
	var final_count = int(base_count * fog_mod * orc_mod * grid_mod)
	return clamp(final_count, 1, MAX_LAYER_MONSTERS)

func get_spawn_list(layer_idx: int, count: int) -> Array:
	var spawn_list: Array = []
	
	var layer_data = layer_monster_pools.get(layer_idx, {})
	var primary_pool = layer_data.get("primary", [])
	var secondary_pool = layer_data.get("secondary", [])
	
	var primary_count = int(count * 0.7)
	var secondary_count = count - primary_count
	
	for i in range(primary_count):
		var monster_id = primary_pool[randi() % primary_pool.size()]
		spawn_list.append(_create_spawn_entry(monster_id, layer_idx))
	
	for i in range(secondary_count):
		if randf() < 0.5:
			var monster_id = secondary_pool[randi() % secondary_pool.size()]
			spawn_list.append(_create_spawn_entry(monster_id, layer_idx))
	
	if world_sim:
		_spawn_session_monsters(spawn_list, layer_idx)
	
	return spawn_list

func _create_spawn_entry(monster_id: String, layer_idx: int) -> Dictionary:
	var monster_data = base_monsters_data.get(monster_id, {})
	
	return {
		"id": monster_id,
		"x": randi_range(2, 18),
		"y": randi_range(2, 18),
		"awake": false,
		"hp": monster_data.get("hp", 10),
		"max_hp": monster_data.get("hp", 10),
		"name": monster_data.get("name", monster_id),
		"ac": monster_data.get("ac", 10),
		"cr": monster_data.get("cr", "1")
	}

func _spawn_session_monsters(spawn_list: Array, layer_idx: int):
	if not world_sim:
		return
	
	var fog = world_sim.fog_density
	var orc = world_sim.orc_disposition
	var grid = world_sim.grid_resonance
	
	var session_count = 0
	
	if fog >= 0.7:
		session_count += _add_session_monster(spawn_list, "fog_beast")
		session_count += _add_session_monster(spawn_list, "noise_creature")
	
	if orc >= 4:
		session_count += _add_session_monster(spawn_list, "demon_hunter")
	
	if fog >= 0.5:
		session_count += _add_session_monster(spawn_list, "noise_creature")
	
	if grid >= 0.7:
		session_count += _add_session_monster(spawn_list, "void_construct")
	
	if grid >= 0.5:
		session_count += _add_session_monster(spawn_list, "abyssal_spawn")
	
	print("[MonsterSpawner] Session-based monsters added: ", session_count)

func _add_session_monster(spawn_list: Array, monster_id: String) -> int:
	var monster_data = session_monsters_data.get(monster_id, {})
	if monster_data.is_empty():
		return 0
	
	spawn_list.append({
		"id": monster_id,
		"x": randi_range(2, 18),
		"y": randi_range(2, 18),
		"awake": false,
		"hp": monster_data.get("hp", 10),
		"max_hp": monster_data.get("hp", 10),
		"name": monster_data.get("name", monster_id),
		"ac": monster_data.get("ac", 10),
		"cr": monster_data.get("cr", "1"),
		"session_monster": true
	})
	
	return 1

func get_monster_by_id(monster_id: String) -> Dictionary:
	var monster = base_monsters_data.get(monster_id, {})
	if monster.is_empty():
		monster = session_monsters_data.get(monster_id, {})
	return monster

func get_category_by_id(monster_id: String) -> String:
	var monster = get_monster_by_id(monster_id)
	return monster.get("category", "unknown")

func get_spawn_locations(layer_idx: int, room_count: int) -> Array:
	var locations: Array = []
	
	for i in range(room_count):
		locations.append({
			"x": randi_range(3, 17),
			"y": randi_range(3, 17)
		})
	
	return locations
