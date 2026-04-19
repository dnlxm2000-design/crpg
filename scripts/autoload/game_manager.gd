# GameManager - 게임 전역 상태 관리 (Autoload singleton)

extends Node

var current_scene: String = "tutorial"
var party_data: Dictionary = {}
var flags: Dictionary = {
	"tutorial_completed": false,
	"first_entry": true,
	"session_started": false
}
var races_data: Dictionary = {}
var backgrounds_data: Dictionary = {}

func _ready():
	_load_flags()
	load_party()
	load_races()

func _load_flags():
	var file = FileAccess.open("res://data/flags.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and json is Dictionary:
			flags.merge(json, true)
		file.close()

func save_flags():
	var file = FileAccess.open("res://data/flags.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(flags, "\t"))
		file.close()

func is_tutorial_completed() -> bool:
	return flags.get("tutorial_completed", false)

func set_tutorial_completed():
	flags["tutorial_completed"] = true
	save_flags()

func is_first_entry() -> bool:
	return flags.get("first_entry", true)

func set_first_entry_done():
	flags["first_entry"] = false
	save_flags()

func load_races():
	var file = FileAccess.open("res://data/races.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if json and json is Dictionary:
			races_data = json.get("races", {})
	
	if races_data.is_empty():
		races_data = _get_default_races()
	
	file = FileAccess.open("res://data/backgrounds.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if json and json is Dictionary:
			backgrounds_data = json.get("backgrounds", {})
	
	if backgrounds_data.is_empty():
		backgrounds_data = _get_default_backgrounds()

func _get_default_races() -> Dictionary:
	return {
		"human": {"name": "인간", "name_en": "Human", "ability_score_increases": {"STR": 1, "DEX": 1, "CON": 1, "INT": 1, "WIS": 1, "CHA": 1}, "select_kingdom": true, "select_bloodline": true, "bloodline_options": ["ironbloods", "ether_guardians", "solar_walkers", "mist_sailors"], "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "eterea", "name": "에테리아", "ability_bonus": {"WIS": 2}}, {"id": "solaris", "name": "솔라리스", "ability_bonus": {"STR": 1, "DEX": 1}}, {"id": "mystral", "name": "미스트랄", "ability_bonus": {"DEX": 1, "CHA": 1}}]},
		"elf": {"name": "엘프", "name_en": "Elf", "ability_score_increases": {"STR": 0, "DEX": 2, "CON": 0, "INT": 0, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "silverleaf", "name": "은빛 잎 왕국", "description": "강력한 결계 안에서 시간이 멈춘 듯한 삶을 사는 보존주의자들", "ability_bonus": {"WIS": 2}}, {"id": "noise_walker", "name": "노이즈 워커", "description": "보이드 노이즈에 오염된 지역에서 기계화된 신체로 살아가는 감시자들", "ability_bonus": {"CON": 1, "INT": 1}}, {"id": "luminas_remnant", "name": "루미나스 유민", "description": "과거 마도공학 아카데미 출신, 흩어진 마법 스크롤 회수자들", "ability_bonus": {"INT": 2}}, {"id": "mistral_stalker", "name": "미스트랄 추격대", "description": "실버하벤 인근 숲에서 활동하는 실용적 생존자들", "ability_bonus": {"DEX": 1, "WIS": 1}}, {"id": "grid_architect", "name": "그리드 아키텍트", "description": "파괴된 에테르 그리드를 수리하려는 고집스러운 기술자들", "ability_bonus": {"INT": 1, "DEX": 1}}, {"id": "red_dew", "name": "붉은 이슬 부족", "description": "제물로 바쳐졌던 엘프들의 후손, 영혼 장례 의식자들", "ability_bonus": {"WIS": 1, "CHA": 1}}, {"id": "crystal_vein", "name": "수정 혈맥 부족", "description": "드워프와 협력하여 마력 수정 가치를 지키는 자원 보존자들", "ability_bonus": {"STR": 1, "INT": 1}}, {"id": "mist_sailor", "name": "안개 세일러", "description": "안개와 바다의 경계에서 배를 타는 유목 민족", "ability_bonus": {"DEX": 2}}], "background_options": [{"id": "preserve_keeper", "name": "수호자", "ability_bonus": {"WIS": 1, "DEX": 1}}, {"id": "arcane_scholar", "name": "마법 학자", "ability_bonus": {"INT": 2}}]},
		"dwarf": {"name": "드워프", "name_en": "Dwarf", "ability_score_increases": {"STR": 0, "DEX": 0, "CON": 2, "INT": 0, "WIS": 1, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "granite_guard", "name": "그라니트 가드", "ability_bonus": {"CON": 1, "STR": 1}}, {"id": "amber_fortress", "name": "엠버 포지", "ability_bonus": {"INT": 1, "WIS": 1}}, {"id": "sky_hammer", "name": "스카이 해머", "ability_bonus": {"DEX": 1, "CHA": 1}}], "background_options": [{"id": "granite_miner", "name": "광부", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "amber_smith", "name": "대장장이", "ability_bonus": {"STR": 1, "INT": 1}}, {"id": "sky_rune_mage", "name": "룬 마법사", "ability_bonus": {"INT": 1, "WIS": 1}}]},
		"halfling": {"name": "하플링", "name_en": "Halfling", "ability_score_increases": {"STR": 0, "DEX": 2, "CON": 0, "INT": 0, "WIS": 0, "CHA": 1}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "misty_realm", "name": "안개의 자치령", "ability_bonus": {"DEX": 1, "CHA": 1}}], "background_options": [{"id": "informer", "name": "정보상", "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "smuggler", "name": "밀수상", "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "porter", "name": "항구 노동자", "ability_bonus": {"STR": 1, "CON": 1}}]},
		"orc": {"name": "오크", "name_en": "Orc", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 1, "INT": -1, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "clan_options": [{"id": "iron_skull", "name": "아이언스컬", "ability_bonus": {"STR": 2}}, {"id": "blood_moon", "name": "블러드 문", "ability_bonus": {"CON": 1, "CHA": 1}}, {"id": "bone_walker", "name": "본 워커", "ability_bonus": {"INT": 1}}, {"id": "sky_fang", "name": "스카이 팽", "ability_bonus": {"DEX": 2}}, {"id": "silver_tongue", "name": "실버 텅", "ability_bonus": {"CHA": 1}}], "background_options": [{"id": "orc_warrior", "name": "전사", "ability_bonus": {"STR": 2}}, {"id": "orc_shaman", "name": "주술사", "ability_bonus": {"WIS": 1, "INT": 1}}]},
		"troll": {"name": "트롤", "name_en": "Troll", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 2, "INT": -2, "WIS": 0, "CHA": -1}, "select_kingdom": true, "select_background": true, "clan_options": [{"id": "silver_silent", "name": "은빛침묵 부족", "ability_bonus": {"WIS": 2}}, {"id": "blood_echo", "name": "피의 숨결 부족", "ability_bonus": {"CON": 2}}, {"id": "moss_root", "name": "이끼 뿌리 부족", "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "iron_bone", "name": "강철 뼈 부족", "ability_bonus": {"STR": 1, "INT": 1}}, {"id": "moon_veil", "name": "환영의 달 부족", "ability_bonus": {"DEX": 2}}, {"id": "ember_ash", "name": "재가루 부족", "ability_bonus": {"INT": 1, "CHA": 1}}, {"id": "tide_caller", "name": "바다 파도 부족", "ability_bonus": {"CON": 1, "CHA": 1}}, {"id": "soul_stalker", "name": "영혼 사냥꾼 부족", "ability_bonus": {"WIS": 2}}, {"id": "dune_wraith", "name": "모래 바람 부족", "ability_bonus": {"DEX": 2}}, {"id": "frost_fang", "name": "서리 이빨 부족", "ability_bonus": {"CON": 2}}]},
		"half_orc": {"name": "하프오크", "name_en": "Half-Orc", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 1, "INT": 0, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "orc_horde", "name": "오크 호드", "ability_bonus": {"STR": 2, "CHA": -1}}], "background_options": [{"id": "escaped_slave", "name": "탈출한 노예", "requires_kingdom": true, "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "outlaw", "name": "부랑아", "requires_kingdom": true, "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "commoner", "name": "고아", "requires_kingdom": false, "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "mercenary", "name": "용병", "requires_kingdom": false, "ability_bonus": {"STR": 1, "DEX": 1}}]},
		"half_troll": {"name": "하프트롤", "name_en": "Half-Troll", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 2, "INT": -1, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "orc_horde", "name": "오크 호드", "ability_bonus": {"STR": 2, "CHA": -1}}], "background_options": [{"id": "escaped_slave", "name": "탈출한 노예", "requires_kingdom": true, "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "outlaw", "name": "부랑아", "requires_kingdom": true, "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "commoner", "name": "고아", "requires_kingdom": false, "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "mercenary", "name": "용병", "requires_kingdom": false, "ability_bonus": {"STR": 1, "DEX": 1}}]},
		"gnome": {"name": "노움", "name_en": "Gnome", "ability_score_increases": {"STR": -1, "DEX": 0, "CON": 2, "INT": 2, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "select_bloodline": true, "bloodline_options": ["ironbloods", "ether_guardians", "solar_walkers", "mist_sailors"], "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "amber_fortress", "name": "엠버 포지", "ability_bonus": {"INT": 1, "WIS": 1}}], "background_options": [{"id": "alchemist", "name": "연금술사", "ability_bonus": {"INT": 2}}, {"id": "illusionist", "name": "일루져니스트", "ability_bonus": {"DEX": 1, "INT": 1}}]},
		"drow": {"name": "다크엘프", "name_en": "Drow", "ability_score_increases": {"STR": 0, "DEX": 2, "CON": 0, "INT": 1, "WIS": 0, "CHA": 1}, "select_background": true, "background_options": [{"id": "noize_survivor", "name": "노이즈 오염 지역", "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "abyss_cultist", "name": "심연의 사도", "ability_bonus": {"INT": 1, "CHA": 1}}]}
	}

func _get_default_backgrounds() -> Dictionary:
	return {
		"ironbloods": {"name": "아이언블러드", "ability_scores": {"CON": 2, "STR": 1}},
		"ether_guardians": {"name": "에테르 가디언", "ability_scores": {"WIS": 2, "INT": 1}},
		"solar_walkers": {"name": "솔라 워커", "ability_scores": {"CHA": 2, "DEX": 1}},
		"mist_sailors": {"name": "미스트 세일러", "ability_scores": {"DEX": 2, "CON": 1}}
	}

func get_races() -> Dictionary:
	return races_data

func get_backgrounds() -> Dictionary:
	return backgrounds_data

# TODO: JSON 파일에서 파티 데이터 로드
func load_party():
	pass

# TODO: JSON 파일에 파티 데이터 저장
func save_game():
	pass
