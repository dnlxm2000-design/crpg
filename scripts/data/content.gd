# Content - 게임 콘텐츠 데이터 로더

extends Node

var bloodlines_data: Dictionary = {}
var monsters_data: Dictionary = {}
var items_data: Dictionary = {}

func _ready():
	load_all_data()

func load_all_data():
	load_bloodlines()
	load_monsters()
	load_items()

# bloodlines.json 파일에서 혈통 데이터 로드
# 파일이 없으면 기본 데이터 사용
func load_bloodlines():
	if _file_exists("res://data/bloodlines.json"):
		var file = FileAccess.open("res://data/bloodlines.json", FileAccess.READ)
		if file:
			var json = JSON.parse_string(file.get_as_text())
			if json:
				bloodlines_data = json
				print("Loaded ", bloodlines_data.size(), " bloodlines from file")
			file.close()
		else:
			_create_default_bloodlines()
	else:
		print("bloodlines.json not found, using default data")
		_create_default_bloodlines()

# monsters_additional.json 파일에서 몬스터 데이터 로드
# 파일이 없으면 기본 데이터 사용
func load_monsters():
	if _file_exists("res://data/monsters_additional.json"):
		var file = FileAccess.open("res://data/monsters_additional.json", FileAccess.READ)
		if file:
			var json = JSON.parse_string(file.get_as_text())
			if json:
				monsters_data = json
				print("Loaded ", monsters_data.size(), " monsters from file")
			file.close()
		else:
			_create_default_monsters()
	else:
		print("monsters_additional.json not found, using default data")
		_create_default_monsters()

# 파일 존재 여부 확인 유틸리티
func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

# 하드코딩된 아이템 데이터
func load_items():
	items_data = {
		"weapons": {
			"shortsword": {"name": "단검", "damage": "1d6", "type": "simple", "cost": 10},
			"longsword": {"name": "롱소드", "damage": "1d8", "type": "martial", "cost": 15},
			"battleaxe": {"name": "배틀액스", "damage": "1d10", "type": "martial", "cost": 20}
		},
		"armors": {
			"leather": {"name": "가죽 갑옷", "ac": 2, "type": "light", "cost": 10},
			"chainmail": {"name": "사슬 갑옷", "ac": 4, "type": "medium", "cost": 50},
			"plate": {"name": "판금 갑옷", "ac": 6, "type": "heavy", "cost": 150}
		},
		"consumables": {
			"health_potion": {"name": "HP 포션", "effect": "heal", "value": 5, "cost": 25},
			"antidote": {"name": "해독제", "effect": "cure_poison", "cost": 15}
		}
	}

# 기본 4대 혈통 데이터
func _create_default_bloodlines():
	bloodlines_data = {
		"ironblood": {
			"name": "아이언브러드",
			"bonuses": {"str": 2, "dex": -1, "con": 1, "cha": -1},
			"features": ["cold_resist", "armor_skin"]
		},
		"ether_guardian": {
			"name": "에테르 가디언",
			"bonuses": {"int": 2, "wis": 1, "str": -1},
			"features": ["ether_sight", "magic_affinity"]
		},
		"solar_walker": {
			"name": "솔라 워커",
			"bonuses": {"str": 1, "dex": 1, "int": -1},
			"features": ["heat_resist", "eagle_eye"]
		},
		"mist_sailor": {
			"name": "미스트 세일러",
			"bonuses": {"dex": 2, "wis": 1, "cha": 1, "str": -1},
			"features": ["mist_detect", "luck"]
		}
	}

# 기본 몬스터 데이터
func _create_default_monsters():
	monsters_data = {
		"goblin": {
			"name": "고블린",
			"cr": 0.25,
			"hp": 7,
			"ac": 11,
			"speed": 30,
			"stats": {"str": 8, "dex": 14, "con": 10, "int": 10, "wis": 8, "cha": 8},
			"attacks": [{"name": "단검", "damage": "1d6"}]
		},
		"orc": {
			"name": "아이런스컬 오크",
			"cr": 1,
			"hp": 15,
			"ac": 13,
			"speed": 30,
			"stats": {"str": 16, "dex": 12, "con": 14, "int": 7, "wis": 11, "cha": 10},
			"attacks": [{"name": "그레이트액스", "damage": "1d12"}]
		}
	}

# ID로 혈통 데이터 조회
func get_bloodline(id: String) -> Dictionary:
	return bloodlines_data.get(id, {})

# ID로 몬스터 데이터 조회
func get_monster(id: String) -> Dictionary:
	return monsters_data.get(id, {})

# ID로 아이템 데이터 조회
func get_item(id: String) -> Dictionary:
	for category in items_data.values():
		if category.has(id):
			return category[id]
	return {}