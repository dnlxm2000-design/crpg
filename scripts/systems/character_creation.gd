# CharacterCreation - Character creation system

extends Control

func _ready():
	_load_data()
	_get_nodes()
	_setup_options()

var races_data: Dictionary = {}
var backgrounds_data: Dictionary = {}
var current_race: String = "human"
var current_bloodline: String = ""
# Bloodline region and starting location (for region-based bloodlines)
var current_bloodline_region: String = ""
var current_bloodline_starting_location: String = ""
var current_kingdom: String = ""
var current_clan: String = ""
var current_background: String = ""
var current_class: String = "fighter"
var character_name: String = ""

var selection_phase: int = 0  # 0: race, 1: bloodline/kingdom/clan, 2: background, 3: kingdom (conditional)

var stats: Dictionary = {
	"STR": 10,
	"DEX": 10,
	"CON": 10,
	"INT": 10,
	"WIS": 10,
	"CHA": 10
}

var base_stats: Dictionary = {
	"STR": 10,
	"DEX": 10,
	"CON": 10,
	"INT": 10,
	"WIS": 10,
	"CHA": 10
}

var stat_costs: Dictionary = {
	8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9
}

var max_points: int = 27
var used_points: int = 0
var available_points: int = 27

var race_nodes: Dictionary = {}
var bloodline_nodes: Dictionary = {}
var kingdom_nodes: Dictionary = {}
var background_nodes: Dictionary = {}
var class_nodes: Dictionary = {}
var stat_nodes: Dictionary = {}
var name_node: LineEdit
var points_label: Label
var create_button: Button

var selected_background_data: Dictionary = {}

var race_keys: Array = ["human", "elf", "dwarf", "halfling", "orc", "troll", "half_orc", "half_troll", "gnome", "drow"]

func _load_data():
	var gm = get_node("/root/GameManager")
	if gm and gm.has_method("get_races"):
		races_data = gm.get_races()
		backgrounds_data = gm.get_backgrounds()
		max_points = 27
		print("[DEBUG] races_data from GM: ", races_data.size(), " keys")
	
	races_data = _get_default_races()
	max_points = 27
	print("[DEBUG] Force using _get_default_races (has kingdom_options)")
	
	if races_data.size() > 0:
		var elf_data = races_data.get("elf", {})
		print("[DEBUG] elf has kingdom_options: ", elf_data.has("kingdom_options"))
		print("[DEBUG] elf kingdom_options: ", elf_data.get("kingdom_options", []).size())
	
	if backgrounds_data.is_empty():
		var file = FileAccess.open("res://data/backgrounds.json", FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.parse_string(text)
			if json and json is Dictionary:
				backgrounds_data = json.get("backgrounds", {})
	
	if backgrounds_data.is_empty():
		backgrounds_data = _get_default_backgrounds()
	
	print("[DEBUG] races_data loaded, keys count: ", races_data.size())
	print("[DEBUG] races_data keys: ", races_data.keys())
	
	if races_data.size() > 0:
		var sample_race = races_data.get("dwarf", {})
		print("[DEBUG] sample dwarf data: ", sample_race)
		print("[DEBUG] dwarf has kingdom_options: ", sample_race.has("kingdom_options"))

func _get_default_races() -> Dictionary:
	return {
		"human": {"name": "인간", "ability_score_increases": {"STR": 1, "DEX": 1, "CON": 1, "INT": 1, "WIS": 1, "CHA": 1}, "select_kingdom": true, "select_bloodline": true, "bloodline_options": ["ironbloods", "ether_guardians", "solar_walkers", "mist_sailors"], "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "eterea", "name": "에테리아", "ability_bonus": {"WIS": 2}}, {"id": "solaris", "name": "솔라리스", "ability_bonus": {"STR": 1, "DEX": 1}}, {"id": "mystral", "name": "미스트랄", "ability_bonus": {"DEX": 1, "CHA": 1}}]},
		"elf": {"name": "엘프", "name_en": "Elf", "ability_score_increases": {"STR": 0, "DEX": 2, "CON": 0, "INT": 0, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "silverleaf", "name": "은빛 잎 왕국", "description": "강력한 결계 안에서 시간이 멈춘 듯한 삶을 사는 보존주의자들", "ability_bonus": {"WIS": 2}}, {"id": "noise_walker", "name": "노이즈 워커", "description": "보이드 노이즈에 오염된 지역에서 기계화된 신체로 살아가는 감시자들", "ability_bonus": {"CON": 1, "INT": 1}}, {"id": "luminas_remnant", "name": "루미나스 유민", "description": "과거 마도공학 아카데미 출신, 흩어진 마법 스크롤 회수자들", "ability_bonus": {"INT": 2}}, {"id": "mistral_stalker", "name": "미스트랄 추격대", "description": "실버하벤 인근 숲에서 활동하는 실용적 생존자들", "ability_bonus": {"DEX": 1, "WIS": 1}}, {"id": "grid_architect", "name": "그리드 아키텍트", "description": "파괴된 에테르 그리드를 수리하려는 고집스러운 기술자들", "ability_bonus": {"INT": 1, "DEX": 1}}, {"id": "red_dew", "name": "붉은 이슬 부족", "description": "제물로 바쳐졌던 엘프들의 후손, 영혼 장례 의식자들", "ability_bonus": {"WIS": 1, "CHA": 1}}, {"id": "crystal_vein", "name": "수정 혈맥 부족", "description": "드워프와 협력하여 마력 수정 가치를 지키는 자원 보존자들", "ability_bonus": {"STR": 1, "INT": 1}}, {"id": "mist_sailor", "name": "안개 세일러", "description": "안개와 바다의 경계에서 배를 타는 유목 민족", "ability_bonus": {"DEX": 2}}], "background_options": [{"id": "preserve_keeper", "name": "수호자", "ability_bonus": {"WIS": 1, "DEX": 1}}, {"id": "arcane_scholar", "name": "마법 학자", "ability_bonus": {"INT": 2}}]},
		"dwarf": {"name": "드워프", "name_en": "Dwarf", "ability_score_increases": {"STR": 0, "DEX": 0, "CON": 2, "INT": 0, "WIS": 1, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "granite_guard", "name": "그라니트 가드", "ability_bonus": {"CON": 1, "STR": 1}}, {"id": "amber_fortress", "name": "엠버 포지", "ability_bonus": {"INT": 1, "WIS": 1}}, {"id": "sky_hammer", "name": "스카이 해머", "ability_bonus": {"DEX": 1, "CHA": 1}}], "background_options": [{"id": "granite_miner", "name": "광부", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "amber_smith", "name": "대장장이", "ability_bonus": {"STR": 1, "INT": 1}}, {"id": "sky_rune_mage", "name": "룬 마법사", "ability_bonus": {"INT": 1, "WIS": 1}}]},
		"halfling": {"name": "하플링", "name_en": "Halfling", "ability_score_increases": {"STR": 0, "DEX": 2, "CON": 0, "INT": 0, "WIS": 0, "CHA": 1}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "misty_realm", "name": "안개의 자치령", "ability_bonus": {"DEX": 1, "CHA": 1}}], "background_options": [{"id": "informer", "name": "정보상", "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "smuggler", "name": "밀수상", "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "porter", "name": "항구 노동자", "ability_bonus": {"STR": 1, "CON": 1}}]},
		"orc": {"name": "오크", "name_en": "Orc", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 1, "INT": -2, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "clan_options": [{"id": "iron_skull", "name": "아이언스컬", "ability_bonus": {"STR": 2}}, {"id": "blood_moon", "name": "블러드 문", "ability_bonus": {"CON": 1, "CHA": 1}}, {"id": "bone_walker", "name": "본 워커", "ability_bonus": {"INT": 1}}, {"id": "sky_fang", "name": "스카이 팽", "ability_bonus": {"DEX": 2}}, {"id": "silver_tongue", "name": "실버 텅", "ability_bonus": {"CHA": 1}}], "background_options": [{"id": "orc_warrior", "name": "전사", "ability_bonus": {"STR": 2}}, {"id": "orc_shaman", "name": "주술사", "ability_bonus": {"WIS": 1, "INT": 1}}]},
		"troll": {"name": "트롤", "name_en": "Troll", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 1, "INT": 0, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "clan_options": [{"id": "silver_silent", "name": "은빛침묵 부족", "ability_bonus": {"WIS": 2}}, {"id": "blood_echo", "name": "피의 숨결 부족", "ability_bonus": {"CON": 2}}, {"id": "moss_root", "name": "이끼 뿌리 부족", "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "iron_bone", "name": "강철 뼈 부족", "ability_bonus": {"STR": 1, "INT": 1}}, {"id": "moon_veil", "name": "환영의 달 부족", "ability_bonus": {"DEX": 2}}, {"id": "ember_ash", "name": "재가루 부족", "ability_bonus": {"INT": 1, "CHA": 1}}, {"id": "tide_caller", "name": "바다 파도 부족", "ability_bonus": {"CON": 1, "CHA": 1}}, {"id": "soul_stalker", "name": "영혼 사냥꾼 부족", "ability_bonus": {"WIS": 2}}, {"id": "dune_wraith", "name": "모래 바람 부족", "ability_bonus": {"DEX": 2}}, {"id": "frost_fang", "name": "서리 이빨 부족", "ability_bonus": {"CON": 2}}]},
		"half_orc": {"name": "하프오크", "name_en": "Half-Orc", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 1, "INT": 0, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "orc_horde", "name": "오크 호드", "ability_bonus": {"STR": 2, "CHA": -1}}], "background_options": [{"id": "escaped_slave", "name": "탈출한 노예", "requires_kingdom": true, "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "outlaw", "name": "부랑아", "requires_kingdom": true, "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "commoner", "name": "고아", "requires_kingdom": false, "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "mercenary", "name": "용병", "requires_kingdom": false, "ability_bonus": {"STR": 1, "DEX": 1}}]},
		"half_troll": {"name": "하프트롤", "name_en": "Half-Troll", "ability_score_increases": {"STR": 2, "DEX": 0, "CON": 1, "INT": 0, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "orc_horde", "name": "오크 호드", "ability_bonus": {"STR": 2, "CHA": -1}}], "background_options": [{"id": "escaped_slave", "name": "탈출한 노예", "requires_kingdom": true, "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "outlaw", "name": "부랑아", "requires_kingdom": true, "ability_bonus": {"DEX": 1, "CHA": 1}}, {"id": "commoner", "name": "고아", "requires_kingdom": false, "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "mercenary", "name": "용병", "requires_kingdom": false, "ability_bonus": {"STR": 1, "DEX": 1}}]},
		"gnome": {"name": "노움", "name_en": "Gnome", "ability_score_increases": {"STR": 0, "DEX": 1, "CON": 0, "INT": 2, "WIS": 0, "CHA": 0}, "select_kingdom": true, "select_background": true, "select_bloodline": true, "bloodline_options": ["ironbloods", "ether_guardians", "solar_walkers", "mist_sailors"], "kingdom_options": [{"id": "iron_guard", "name": "아이언가드", "ability_bonus": {"STR": 1, "CON": 1}}, {"id": "amber_fortress", "name": "엠버 포지", "ability_bonus": {"INT": 1, "WIS": 1}}], "background_options": [{"id": "alchemist", "name": "연금술사", "ability_bonus": {"INT": 2}}, {"id": "illusionist", "name": "일루져니스트", "ability_bonus": {"DEX": 1, "INT": 1}}]},
		"drow": {"name": "다크엘프", "name_en": "Drow", "ability_score_increases": {"STR": 0, "DEX": 2, "CON": 0, "INT": 0, "WIS": 0, "CHA": 1}, "select_background": true, "background_options": [{"id": "noize_survivor", "name": "노이즈 오염 지역", "ability_bonus": {"CON": 1, "WIS": 1}}, {"id": "abyss_cultist", "name": "심연의 사도", "ability_bonus": {"INT": 1, "CHA": 1}}]}
	}

func _get_default_backgrounds() -> Dictionary:
	return {
		"ironbloods": {"name": "아이언브러드", "ability_scores": {"CON": 2, "STR": 1}},
		"ether_guardians": {"name": "에테르 가디언", "ability_scores": {"WIS": 2, "INT": 1}},
		"solar_walkers": {"name": "솔라 워커", "ability_scores": {"CHA": 2, "DEX": 1}},
		"mist_sailors": {"name": "미스트 세일러", "ability_scores": {"DEX": 2, "CON": 1}}
	}

func _get_nodes():
	race_nodes = {
		"label": find_child("RaceLabel", true, true),
		"option": find_child("RaceOption", true, true)
	}
	class_nodes = {
		"label": find_child("ClassLabel", true, true),
		"option": find_child("ClassOption", true, true)
	}
	bloodline_nodes = {
		"label": find_child("BloodlineLabel", true, true),
		"option": find_child("BloodlineOption", true, true)
	}
	kingdom_nodes = {
		"label": find_child("KingdomLabel", true, true),
		"option": find_child("KingdomOption", true, true)
	}
	background_nodes = {
		"label": find_child("BackgroundLabel", true, true),
		"option": find_child("BackgroundOption", true, true)
	}
	
	print("[DEBUG] kingdom_nodes: ", kingdom_nodes)
	print("[DEBUG] kingdom_nodes option null?: ", kingdom_nodes.get("option") == null)
	print("[DEBUG] kingdom_nodes label null?: ", kingdom_nodes.get("label") == null)
	
	print("[DEBUG] kingdom_nodes lookup: ", kingdom_nodes)
	print("[DEBUG] kingdom_nodes option: ", kingdom_nodes.get("option"))
	print("[DEBUG] kingdom_nodes label: ", kingdom_nodes.get("label"))
	
	print("[DEBUG] race_nodes['option']: ", race_nodes["option"])
	print("[DEBUG] kingdom_nodes['option']: ", kingdom_nodes["option"])
	print("[DEBUG] background_nodes['option']: ", background_nodes["option"])
	
	var stats_container = find_child("StatsContainer", true, true)
	if stats_container:
		for stat_key in ["STR", "DEX", "CON", "INT", "WIS", "CHA"]:
			var stat_box = stats_container.get_node(stat_key)
			if stat_box:
				stat_nodes[stat_key] = {
					"label": stat_box.get_node("Label"),
					"value": stat_box.get_node("Value"),
					"minus": stat_box.get_node("ButtonMinus"),
					"plus": stat_box.get_node("ButtonPlus")
				}
	
	name_node = find_child("NameInput", true, true)
	points_label = find_child("PointsRemaining", true, true)
	create_button = find_child("CreateButton", true, true)

func _setup_options():
	_populate_race_options()
	_populate_class_options()
	
	if race_nodes.has("option") and race_nodes["option"]:
		race_nodes["option"].item_selected.connect(_on_race_selected)
	
	if class_nodes.has("option") and class_nodes["option"]:
		class_nodes["option"].item_selected.connect(_on_class_selected)
	
	if bloodline_nodes.has("option") and bloodline_nodes["option"]:
		bloodline_nodes["option"].item_selected.connect(_on_bloodline_selected)
	
	if kingdom_nodes.has("option") and kingdom_nodes["option"]:
		kingdom_nodes["option"].item_selected.connect(_on_kingdom_selected)
	
	if background_nodes.has("option") and background_nodes["option"]:
		background_nodes["option"].item_selected.connect(_on_background_selected)
	
	if create_button:
		create_button.pressed.connect(_on_create_button_pressed)
	
	_connect_stat_buttons()
	_update_points_display()

func _create_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1)
	style.border_color = Color(0.4, 0.4, 0.5, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

func _populate_class_options():
	var option = class_nodes["option"]
	if not option:
		return
	
	option.clear()
	var class_names = ["전사", "도적", "마법사", "사제", "레인저", "야만전사", "성기사", "음유시인"]
	for i in range(class_names.size()):
		option.add_item(class_names[i], i)
	
	option.select(0)
	
	print("[DEBUG] All UI setup complete")
	print("[DEBUG] Labels visible - checking if dropdown works")

func _on_create_button_pressed():
	_create_character()

func _populate_race_options():
	var option = race_nodes["option"]
	if not option:
		return
	
	option.clear()
	var race_names = ["인간", "엘프", "드워프", "하플링", "오크", "트롤", "하프오크", "하프트롤", "노움", "다크엘프"]
	for i in range(race_names.size()):
		option.add_item(race_names[i], i)
	
	option.select(0)
	_on_race_selected(0)

func _on_race_selected(index):
	var option = race_nodes["option"]
	if not option:
		print("[ERROR] race_nodes option is null!")
		return
	
	var race_id = race_keys[index] if index < race_keys.size() else "human"
	current_race = race_id
	
	print("\n========================================")
	print("=== DEBUG: _on_race_selected ===")
	print("========================================")
	print("[DEBUG] race_id: ", race_id)
	print("[DEBUG] races_data.keys: ", races_data.keys())
	
	var race_data = races_data.get(race_id, {})
	print("[DEBUG] race_data: ", race_data)
	print("[DEBUG] race_data.keys: ", race_data.keys())
	print("[DEBUG] race_data has kingdom_options: ", race_data.has("kingdom_options"))
	
	var kingdom_opts = race_data.get("kingdom_options", [])
	var clan_opts = race_data.get("clan_options", [])
	print("[DEBUG] kingdom_opts: ", kingdom_opts)
	print("[DEBUG] kingdom_opts.size(): ", kingdom_opts.size())
	print("[DEBUG] clan_opts.size(): ", clan_opts.size())
	
	current_bloodline = ""
	current_kingdom = ""
	current_clan = ""
	current_background = ""
	selection_phase = 0
	
	print("[DEBUG] Hiding bloodline BEFORE kingdom...")
	if bloodline_nodes.has("option") and bloodline_nodes["option"]:
		bloodline_nodes["option"].visible = false
		bloodline_nodes["option"].disabled = true
		print("[DEBUG] bloodline option hidden")
	if bloodline_nodes.has("label") and bloodline_nodes["label"]:
		bloodline_nodes["label"].visible = false
		print("[DEBUG] bloodline label hidden")
	
	print("[DEBUG] Setting default kingdom to silverleaf...")
	current_kingdom = "silverleaf"
	
	if race_id == "orc":
		current_clan = "iron_skull"
		current_kingdom = "iron_skull"
		print("[DEBUG] Orc - using clan iron_skull")
	elif race_id == "troll":
		current_clan = "silver_silent"
		current_kingdom = "silver_silent"
		print("[DEBUG] Troll - using clan silver_silent")
	
	print("[DEBUG] Calling _update_kingdom_selection...")
	_update_kingdom_selection(race_data)
	selection_phase = 1
	
	print("[DEBUG] After _update_kingdom_selection")
	print("[DEBUG] kingdom_nodes.option.visible: ", kingdom_nodes.get("option").visible if kingdom_nodes.get("option") else "NULL")
	print("[DEBUG] kingdom_nodes.label.visible: ", kingdom_nodes.get("label").visible if kingdom_nodes.get("label") else "NULL")
	
	_apply_race_bonus(race_data)
	_update_stat_display()
	_update_points_display()

func _populate_bloodline_options(options: Array):
	var option = bloodline_nodes.get("option")
	if not option:
		print("[DEBUG] bloodline option is null!")
		return
	
	option.clear()
	option.disabled = false
	
	for i in range(options.size()):
		var opt = options[i]
		var opt_name = "unknown"
		if opt is Dictionary:
			opt_name = opt.get("name", opt.get("id", "bloodline"))
		else:
			opt_name = opt
		option.add_item(opt_name, i)
		if opt is Dictionary:
			option.set_item_metadata(i, opt.get("id", ""))
	
	if options.size() > 0:
		option.select(0)
		_show_bloodline_info(options[0])
		_on_bloodline_selected(0)

func _show_bloodline_info(bloodline_id: String):
	var data = backgrounds_data.get(bloodline_id, {})
	if data.is_empty():
		return
	
	# Create popup window
	var popup = PopupPanel.new()
	popup.size = Vector2(350, 300)
	add_child(popup)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(350, 300)
	popup.add_child(vbox)
	
	# Add margin container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	margin.add_child(inner_vbox)
	
	# Title
	var title = Label.new()
	title.text = data.get("name", bloodline_id) + " 정보"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(title)
	
	var separator = HSeparator.new()
	inner_vbox.add_child(separator)
	
	# Ability scores
	var abilities = data.get("ability_scores", {})
	var ability_text = "능력치 보정:\n"
	for stat in abilities.keys():
		var val = abilities[stat]
		var _sign = "+" if val > 0 else ""
		ability_text += "  " + stat + ": " + _sign + str(val) + "\n"
	
	var ability_label = Label.new()
	ability_label.text = ability_text
	inner_vbox.add_child(ability_label)
	
	# Traits from bloodline.md
	var traits_info = ""
	if bloodline_id == "ironbloods":
		traits_info = "특성:\n• 추위 저항: Cold 데미지 50% 감소\n• 단단한 피부: 마법 외피 (피해 3 감소) 1/day\n• 돌진: Charge 거리 +5ft"
	elif bloodline_id == "ether_guardians":
		traits_info = "특성:\n• 에테르 시야: 암흑 +30ft, 마법 오라 감지\n• 마법 감응 +5%: 마법 성공률 +5%\n• 지식 탐색: 역사/마법 INT 체크 +2"
	elif bloodline_id == "solar_walkers":
		traits_info = "특성:\n• 더위 저항: Fire/Cold 데미지 50% 감소\n• 동체 시력: 은신 적 감지 +5, 후방 공격 +1d4\n• 명중의 축복: 원거리 첫 히트 +2 대미지"
	elif bloodline_id == "mist_sailors":
		traits_info = "특성:\n• 안개 탐지: 시야 감소 구간에서 DEX +3\n• 행운의 아류: 1일 1회 d20 리롤 1/day\n• 밀수 천재: 계약밴드 스킬 +2"
	
	var traits_label = Label.new()
	traits_label.text = traits_info
	inner_vbox.add_child(traits_label)
	
	# Recommended classes
	var class_info = "\n권장 클래스:\n"
	if bloodline_id == "ironbloods":
		class_info += "  ★★★★★ Fighter\n  ★★★★★ Barbarian\n  ★★★★☆ Paladin"
	elif bloodline_id == "ether_guardians":
		class_info += "  ★★★★★ Wizard\n  ★★★★★ Warlock\n  ★★★★☆ Bard"
	elif bloodline_id == "solar_walkers":
		class_info += "  ★★★★★ Ranger\n  ★★★★★ Rogue\n  ★★★★☆ Fighter"
	elif bloodline_id == "mist_sailors":
		class_info += "  ★★★★★ Rogue\n  ★★★★★ Bard\n  ★★★★☆ Ranger"
	
	var class_label = Label.new()
	class_label.text = class_info
	inner_vbox.add_child(class_label)
	
	# Position popup near the bloodline option
	var bloodline_opt = bloodline_nodes.get("option")
	if bloodline_opt:
		var screen_pos = bloodline_opt.get_screen_position()
		popup.position = screen_pos + Vector2(0, bloodline_opt.size.y)
	
	# Auto close after 8 seconds
	await get_tree().create_timer(8.0).timeout
	popup.queue_free()

func _on_bloodline_selected(index):
	var option = bloodline_nodes["option"]
	if not option:
		return
	
	var race_data = races_data.get(current_race, {})
	var bloodline_options = race_data.get("bloodline_options", [])
	if index >= bloodline_options.size():
		return
	var bl = bloodline_options[index]
	if bl is Dictionary:
		current_bloodline = bl.get("id", "")
		current_bloodline_region = bl.get("region", "")
		current_bloodline_starting_location = bl.get("starting_location", "")
		var bonus = bl.get("ability_bonus", {})
		for stat in bonus.keys():
			var v = bonus[stat]
			if base_stats.has(stat):
				base_stats[stat] = base_stats[stat] + v
				stats[stat] = base_stats[stat]
	else:
		current_bloodline = bl
		current_bloodline_region = ""
		current_bloodline_starting_location = ""
	
	print("[DEBUG] bloodline selected: ", current_bloodline)
	print("[DEBUG] bloodline region: ", current_bloodline_region)
	print("[DEBUG] bloodline starting_location: ", current_bloodline_starting_location)
	
	_update_stat_display()
	_update_kingdom_selection(race_data)

func _on_class_selected(index):
	var option = class_nodes["option"]
	if not option:
		return
	
	var class_ids = ["fighter", "rogue", "wizard", "cleric", "ranger", "barbarian", "paladin", "bard"]
	current_class = class_ids[index] if index < class_ids.size() else "fighter"

func _update_kingdom_selection(race_data: Dictionary):
	print("\n=== _update_kingdom_selection START ===")
	
	var kingdom_opts = race_data.get("kingdom_options", [])
	var clan_opts = race_data.get("clan_options", [])
	var bg_opts = race_data.get("background_options", [])
	
	print("[DEBUG] kingdom_opts.size(): ", kingdom_opts.size())
	print("[DEBUG] clan_opts.size(): ", clan_opts.size())
	print("[DEBUG] bg_opts.size(): ", bg_opts.size())
	
	print("[DEBUG] kingdom_nodes: ", kingdom_nodes)
	print("[DEBUG] kingdom_nodes option: ", kingdom_nodes.get("option"))
	print("[DEBUG] kingdom_nodes label: ", kingdom_nodes.get("label"))
	
	if kingdom_nodes.get("option") == null or kingdom_nodes.get("label") == null:
		print("[ERROR] kingdom_nodes is NULL!")
		return
	
	print("[DEBUG] Before: kingdom_nodes option.visible = ", kingdom_nodes.get("option").visible)
	print("[DEBUG] Before: kingdom_nodes label.visible = ", kingdom_nodes.get("label").visible)
	
	if kingdom_opts.size() > 0:
		print("[DEBUG] Processing kingdom_opts (size=", kingdom_opts.size(), ")")
		_populate_kingdom_options(kingdom_opts)
		kingdom_nodes["option"].visible = true
		kingdom_nodes["label"].visible = true
		kingdom_nodes["label"].text = "왕국"
		print("[DEBUG] Set Kingdom UI visible = true")
	elif clan_opts.size() > 0:
		_populate_kingdom_options(clan_opts)
		kingdom_nodes["option"].visible = true
		kingdom_nodes["label"].visible = true
		kingdom_nodes["label"].text = "부족"
		print("[DEBUG] Set Clan UI visible = true")
	else:
		print("[DEBUG] No options - hiding UI")
		kingdom_nodes["option"].visible = false
		kingdom_nodes["label"].visible = false
	
	if bg_opts.size() > 0:
		_populate_background_options(bg_opts)
		background_nodes["option"].visible = true
		background_nodes["label"].visible = true
	else:
		background_nodes["option"].visible = false
		background_nodes["label"].visible = false
	
	print("[DEBUG] After: kingdom_nodes option.visible = ", kingdom_nodes.get("option").visible)
	print("[DEBUG] After: kingdom_nodes label.visible = ", kingdom_nodes.get("label").visible)
	print("=== _update_kingdom_selection END ===\n")

func _populate_kingdom_options(options: Array):
	var option = kingdom_nodes.get("option")
	if not option:
		print("[DEBUG] ERROR: kingdom_nodes option is null!")
		return
	
	print("[DEBUG] Populating kingdom options, count: ", options.size())
	
	option.clear()
	option.disabled = false
	
	for i in range(options.size()):
		var opt = options[i]
		var opt_name = "unknown"
		if opt is Dictionary:
			if opt.has("name") and opt.has("name_en"):
				opt_name = str(opt.get("name")) + " / " + str(opt.get("name_en"))
			else:
				opt_name = opt.get("name", opt.get("id", "bloodline"))
		else:
			opt_name = opt
		option.add_item(opt_name, i)
		if opt is Dictionary:
			option.set_item_metadata(i, opt.get("id", ""))
	
	if options.size() > 0:
		option.select(0)
		# 재귀호출 방지 - _on_kingdom_selected 호출 안 함

func _populate_background_options(options: Array):
	var option = background_nodes.get("option")
	if not option:
		return
	
	option.clear()
	option.disabled = false
	
	for i in range(options.size()):
		var opt = options[i]
		var opt_name = opt.get("name", "unknown") if opt is Dictionary else opt
		option.add_item(opt_name, i)
		if opt is Dictionary:
			option.set_item_metadata(i, opt.get("id", ""))
	
	if options.size() > 0:
		option.select(0)
		_on_background_selected(0)

func _on_kingdom_selected(index):
	if current_kingdom != "" and current_kingdom == "silverleaf":
		print("[DEBUG] Skipping - already set")
		return
	
	var option = kingdom_nodes["option"]
	if not option:
		return
	
	var race_data = races_data.get(current_race, {})
	var kingdom_opts = race_data.get("kingdom_options", [])
	var clan_opts = race_data.get("clan_options", [])
	
	var options = kingdom_opts if kingdom_opts.size() > 0 else clan_opts
	if index < options.size():
		var opt = options[index]
		current_kingdom = opt.get("id", "") if opt is Dictionary else ""
		current_clan = current_kingdom
		
		var ability_bonus = opt.get("ability_bonus", {}) if opt is Dictionary else {}
		_apply_kingdom_bonus(ability_bonus)
		
		# 트롤: bloodline 숨김 (clan 선택이므로). 오크는 Bloodline 확장을 허용합니다.
		if current_race == "troll":
			if bloodline_nodes.has("option") and bloodline_nodes["option"]:
				bloodline_nodes["option"].visible = false
				bloodline_nodes["option"].disabled = true
			if bloodline_nodes.has("label") and bloodline_nodes["label"]:
				bloodline_nodes["label"].visible = false
			print("[DEBUG] Hiding bloodline for orc/troll")
		elif current_race == "human":
			_filter_bloodlines_by_kingdom(current_kingdom)
		elif race_data.get("select_bloodline", false):
			_show_bloodline_options(race_data)
		else:
			if bloodline_nodes.has("option") and bloodline_nodes["option"]:
				bloodline_nodes["option"].visible = false
			if bloodline_nodes.has("label") and bloodline_nodes["label"]:
				bloodline_nodes["label"].visible = false
	
	_update_stat_display()

func _filter_bloodlines_by_kingdom(kingdom_id: String):
	var kingdom_to_bloodline = {
		"iron_guard": "ironbloods",
		"eterea": "ether_guardians",
		"mystral": "ether_guardians",
		"nova": "ether_guardians",
		"solaris": "solar_walkers",
		"ventus": "mist_sailors",
		"free_port": "mist_sailors"
	}
	
	var bloodline_id = kingdom_to_bloodline.get(kingdom_id, "")
	
	if bloodline_id != "" and backgrounds_data.has(bloodline_id):
		if bloodline_nodes.has("option") and bloodline_nodes["option"]:
			bloodline_nodes["option"].clear()
			var bloodline_data = backgrounds_data[bloodline_id]
			var bloodline_name = bloodline_data.get("name", bloodline_id)
			bloodline_nodes["option"].add_item(bloodline_name, 0)
			bloodline_nodes["option"].set_item_metadata(0, bloodline_id)
			bloodline_nodes["option"].visible = true
			
			if bloodline_nodes.has("label") and bloodline_nodes["label"]:
				bloodline_nodes["label"].visible = true
				bloodline_nodes["label"].text = "혈통"
			
			current_bloodline = bloodline_id
			_apply_bloodline_bonus()
			_update_stat_display()
			print("[DEBUG] Bloodline filtered: ", bloodline_id)

func _show_bloodline_options(race_data: Dictionary):
	var bloodline_opts = race_data.get("bloodline_options", [])
	if bloodline_opts.size() > 0:
		_populate_bloodline_options(bloodline_opts)
		if bloodline_nodes.has("option") and bloodline_nodes["option"]:
			bloodline_nodes["option"].visible = true
		if bloodline_nodes.has("label") and bloodline_nodes["label"]:
			bloodline_nodes["label"].visible = true

func _on_background_selected(index):
	var option = background_nodes["option"]
	if not option:
		return
	
	var race_data = races_data.get(current_race, {})
	var bg_opts = race_data.get("background_options", [])
	
	if index < bg_opts.size():
		var opt = bg_opts[index]
		current_background = opt.get("id", "") if opt is Dictionary else ""
		
		var requires_kingdom = opt.get("requires_kingdom", false) if opt is Dictionary else false
		var ability_bonus = opt.get("ability_bonus", {}) if opt is Dictionary else {}
		
		_apply_background_bonus(ability_bonus)
		
		if requires_kingdom:
			if kingdom_nodes.has("option") and kingdom_nodes["option"]:
				kingdom_nodes["option"].visible = true
			if kingdom_nodes.has("label") and kingdom_nodes["label"]:
				kingdom_nodes["label"].visible = true
				kingdom_nodes["label"].text = "왕국 (필수)"
		elif not requires_kingdom:
			if kingdom_nodes.has("option") and kingdom_nodes["option"]:
				kingdom_nodes["option"].visible = false
			if kingdom_nodes.has("label") and kingdom_nodes["label"]:
				kingdom_nodes["label"].visible = false
	
	_update_stat_display()

func _apply_kingdom_bonus(bonuses: Dictionary):
	for stat in bonuses.keys():
		var bonus = bonuses[stat]
		if base_stats.has(stat):
			base_stats[stat] = base_stats[stat] + bonus
			stats[stat] = base_stats[stat]

func _apply_background_bonus(bonuses: Dictionary):
	for stat in bonuses.keys():
		var bonus = bonuses[stat]
		if base_stats.has(stat):
			base_stats[stat] = base_stats[stat] + bonus
			stats[stat] = base_stats[stat]

func _connect_stat_buttons():
	for stat_key in stat_nodes.keys():
		var node_data = stat_nodes[stat_key]
		if node_data.has("minus") and node_data["minus"] != null:
			node_data["minus"].pressed.connect(_on_stat_minus.bind(stat_key))
		if node_data.has("plus") and node_data["plus"] != null:
			node_data["plus"].pressed.connect(_on_stat_plus.bind(stat_key))

func _on_stat_minus(stat_key: String):
	var current_value = stats[stat_key]
	if current_value > 8:
		var old_cost = stat_costs.get(current_value, 0)
		var new_cost = stat_costs.get(current_value - 1, 0)
		used_points -= (old_cost - new_cost)
		stats[stat_key] -= 1
		_update_stat_display()
		_update_points_display()

func _on_stat_plus(stat_key: String):
	var current_value = stats[stat_key]
	var cost = stat_costs.get(current_value + 1, 999)
	if current_value < 15 and used_points + cost <= max_points:
		used_points += cost
		stats[stat_key] += 1
		_update_stat_display()
		_update_points_display()

func _apply_race_bonus(race_data: Dictionary):
	var increases = race_data.get("ability_score_increases", {})
	for stat in base_stats.keys():
		base_stats[stat] = 10 + increases.get(stat, 0)
		stats[stat] = base_stats[stat]
	used_points = 0
	available_points = max_points

func _apply_bloodline_bonus():
	if current_bloodline.is_empty():
		return
	
	var bloodline_data = backgrounds_data.get(current_bloodline, {})
	var increases = bloodline_data.get("ability_scores", {})
	var new_base = {}
	
	print("[DEBUG] bloodline ability_scores: ", increases)
	
	for stat in base_stats.keys():
		new_base[stat] = 10 + increases.get(stat, 0)
	
	print("[DEBUG] new_base after bloodline: ", new_base)
	
	_apply_race_bonus(races_data.get(current_race, {}))
	
	for stat in base_stats.keys():
		base_stats[stat] = new_base[stat]
		stats[stat] = new_base[stat]
	
	print("[DEBUG] final base_stats: ", base_stats)
	
	used_points = 0
	_update_points_display()

func _update_stat_display():
	for stat_key in stat_nodes.keys():
		var node_data = stat_nodes.get(stat_key)
		if node_data and node_data.has("value") and node_data["value"]:
			node_data["value"].text = str(int(stats[stat_key]))

func _update_points_display():
	available_points = max_points - used_points
	if points_label:
		points_label.text = "남은 포인트: " + str(available_points)

func _create_character():
	character_name = name_node.text if name_node else "Hero"
	
	if character_name.is_empty():
		character_name = "Hero"
	
	var character_data = {
		"name": character_name,
		"race": current_race,
		"bloodline": current_bloodline,
		"class": current_class,
		"stats": stats.duplicate(true),
		"starting_location": _get_starting_location()
	}
	
	_save_character_data(character_data)
	_change_to_main_scene()

func _get_starting_location() -> String:
	if current_bloodline_starting_location and current_bloodline_starting_location != "":
		return current_bloodline_starting_location
	if not current_bloodline.is_empty():
		var bloodline_data = backgrounds_data.get(current_bloodline, {})
		if bloodline_data and bloodline_data is Dictionary:
			var loc = bloodline_data.get("starting_location", "")
			if loc != "":
				return loc
	return "unknown"

func _save_character_data(data: Dictionary):
	var game_data = FileAccess.open("res://data/savegame.json", FileAccess.WRITE)
	if game_data:
		var json_string = JSON.stringify(data, "\t")
		game_data.store_string(json_string)
		game_data.close()

func _change_to_main_scene():
	get_tree().change_scene_to_file("res://scenes/scene_selector.tscn")
