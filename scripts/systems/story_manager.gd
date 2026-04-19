# StoryManager - Scenario and story progression manager

extends Node

# Scenario enumeration
enum ScenarioType { TUTORIAL, A, B, C }

var current_scenario: ScenarioType = ScenarioType.TUTORIAL
var scenario_completed: Dictionary = {
	"tutorial": false,
	"A": false,
	"B": false,
	"C": false
}

var player_choices: Dictionary = {}

# Faction relations: -100 (hostile) to +100 (friendly)
var faction_relations: Dictionary = {
	"recovery": 50,      # 수복파
	"merchants": 50,     # 상인 연맹
	"adaptation": 50,     # 적응파
	"orcs": 0,           # 오크 부족
	"shadow_order": 0     # 심연의 사도
}

func _ready():
	add_to_group("game_systems")

# Start specified scenario
func start_scenario(scenario: ScenarioType):
	current_scenario = scenario
	match scenario:
		ScenarioType.TUTORIAL:
			_start_tutorial()
		ScenarioType.A:
			_start_scenario_a()
		ScenarioType.B:
			_start_scenario_b()
		ScenarioType.C:
			_start_scenario_c()

# Tutorial: 아이런스컬 습격
# Tutorial 시나리오 시작
func _start_tutorial():
	print("[시나리오] Tutorial - 아이런스컬 습격")
	get_tree().call_group("scenarios", "start_tutorial")

# 시나리오 A: 실버 텅 외교관의 등장
func _start_scenario_a():
	print("[시나리오] A - 실버 텅 외교관의 등장")
	player_choices.clear()

# 시나리오 B: 증폭기 정지 + 지하 기계 발견
func _start_scenario_b():
	print("[시나리오] B - 증폭기 정지 + 지하 기계 발견")

# 시나리오 C: 노바 부유 도시 잔해
func _start_scenario_c():
	print("[시나리오] C - 노바 부유 도시 잔해")

# Store player choice and apply effects
func make_choice(choice_id: String, value: Variant):
	player_choices[choice_id] = value
	_apply_choice_effects(choice_id, value)

# Apply faction relation changes based on choice
func _apply_choice_effects(choice_id: String, _value: Variant):
	match choice_id:
		"treaty_accepted":
			faction_relations["orcs"] += 50
			faction_relations["recovery"] -= 30
		"treaty_rejected":
			faction_relations["orcs"] -= 50
			faction_relations["recovery"] += 20
		"conditional_negotiation":
			faction_relations["orcs"] += 20
			faction_relations["recovery"] += 10
		"machine_destroyed":
			faction_relations["shadow_order"] -= 30
		"machine_stopped":
			faction_relations["shadow_order"] += 10

# Mark current scenario as completed
func complete_scenario():
	var key = ""
	match current_scenario:
		ScenarioType.TUTORIAL: key = "tutorial"
		ScenarioType.A: key = "A"
		ScenarioType.B: key = "B"
		ScenarioType.C: key = "C"
	
	scenario_completed[key] = true
	print("[시나리오] 완료: ", key)

# Check if scenario is completed
func get_scenario_status(scenario: ScenarioType) -> bool:
	var key = ""
	match scenario:
		ScenarioType.TUTORIAL: key = "tutorial"
		ScenarioType.A: key = "A"
		ScenarioType.B: key = "B"
		ScenarioType.C: key = "C"
	return scenario_completed.get(key, false)

# Get faction relation value
func get_faction_relation(faction: String) -> int:
	return faction_relations.get(faction, 0)

# Modify faction relation
func modify_faction(faction: String, amount: int):
	if faction_relations.has(faction):
		faction_relations[faction] = clamp(faction_relations[faction] + amount, -100, 100)
