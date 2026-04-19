# SceneSelector - Scenario selection screen

extends Control

signal scenario_selected(type: int)

var buttons: Array = []

func _ready():
	add_to_group("game_systems")
	_setup_ui()

# Create selection UI with 4 scenario buttons
func _setup_ui():
	var center = $Center
	if not center:
		center = CenterContainer.new()
		center.name = "Center"
		center.anchor_right = 1.0
		center.anchor_bottom = 1.0
		add_child(center)
	
	var grid = GridContainer.new()
	grid.name = "Grid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	
	for child in center.get_children():
		child.queue_free()
	center.add_child(grid)
	
	# 시나리오 데이터
	var scenarios = [
		{"id": 0, "title": "튜토리얼", "desc": "기본 조작 배우기", "difficulty": "튜토리얼"},
		{"id": 1, "title": "시나리오 A", "desc": "실버 텅 외교관", "difficulty": "쉬움"},
		{"id": 2, "title": "시나리오 B", "desc": "증폭기 정지", "difficulty": "보통"},
		{"id": 3, "title": "시나리오 C", "desc": "부유 도시", "difficulty": "어려움"},
		{"id": 99, "title": "실버하벤", "desc": "탐험으로 돌아가기", "difficulty": ""}
	]
	
	# Create buttons for each scenario
	for s in scenarios:
		var btn = _create_scenario_button(s)
		grid.add_child(btn)
		buttons.append(btn)

# Create scenario button
func _create_scenario_button(data: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(180, 120)
	btn.text = data.title + "\n" + data.desc + "\n[" + data.difficulty + "]"
	btn.pressed.connect(_on_button_pressed.bind(data.id))
	return btn

func _on_button_pressed(scenario_id: int):
	_on_scenario_selected(scenario_id)

# Handle scenario selection
func _on_scenario_selected(id: int):
	visible = false
	
	match id:
		0: # Tutorial
			get_tree().call_group("scenarios", "start_tutorial")
		1: # 시나리오 A
			get_tree().call_group("scenarios", "start_scenario", 1)
		2: # 시나리오 B  
			get_tree().call_group("scenarios", "start_scenario", 2)
		3: # 시나리오 C
			get_tree().call_group("scenarios", "start_scenario", 3)
		99: # Silverhaven으로 돌아가기
			get_tree().change_scene_to_file("res://scenes/main.tscn")
			return
	
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")