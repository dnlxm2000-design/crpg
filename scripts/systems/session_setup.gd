# SessionSetup - Session variable configuration

extends Control

var session_name: String = "New Session"
var fog_density: float = 0.5
var grid_resonance: float = 0.5
var orc_disposition: int = 3

var name_input: LineEdit
var fog_slider: HSlider
var fog_value: Label
var grid_slider: HSlider
var grid_value: Label
var orc_slider: HSlider
var orc_value: Label
var start_button: Button

func _ready():
	_get_nodes()
	_connect_signals()

func _get_nodes():
	name_input = find_child("SessionNameInput", true, true)
	fog_slider = find_child("FogSlider", true, true)
	fog_value = find_child("FogValue", true, true)
	grid_slider = find_child("GridSlider", true, true)
	grid_value = find_child("GridValue", true, true)
	orc_slider = find_child("OrcSlider", true, true)
	orc_value = find_child("OrcValue", true, true)
	start_button = find_child("StartButton", true, true)

func _connect_signals():
	if fog_slider:
		fog_slider.value_changed.connect(_on_fog_changed)
	if grid_slider:
		grid_slider.value_changed.connect(_on_grid_changed)
	if orc_slider:
		orc_slider.value_changed.connect(_on_orc_changed)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)

func _on_fog_changed(value: float):
	fog_density = value
	if fog_value:
		fog_value.text = "%.1f" % value

func _on_grid_changed(value: float):
	grid_resonance = value
	if grid_value:
		grid_value.text = "%.1f" % value

func _on_orc_changed(value: float):
	orc_disposition = int(value)
	if orc_value:
		orc_value.text = str(orc_disposition)

func _on_start_pressed():
	session_name = name_input.text if name_input and not name_input.text.is_empty() else "New Session"
	
	_start_game()

func _start_game():
	_initialize_simulation()
	_save_session_config()
	_change_to_character_creation()

func _initialize_simulation():
	_create_simulation_nodes()
	_configure_simulation()

func _create_simulation_nodes():
	# Autoload nodes already exist - no need to create new ones
	pass

func _configure_simulation():
	# Use autoload nodes instead of local variables
	var ws = get_node("/root/WorldSimulation")
	if ws and ws.has_method("initialize_new_session"):
		ws.initialize_new_session(fog_density, grid_resonance, orc_disposition)
	
	var ms = get_node("/root/MonsterSpawner")
	if ms and ms.has_method("set_world_simulation"):
		ms.set_world_simulation(ws)
	
	var ls = get_node("/root/LootSystem")
	if ls and ls.has_method("set_world_simulation"):
		ls.set_world_simulation(ws)

func _save_session_config():
	var config = {
		"session_name": session_name,
		"fog_density": fog_density,
		"grid_resonance": grid_resonance,
		"orc_disposition": orc_disposition,
		"created": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open("res://data/session_config.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config, "\t"))
		file.close()

func _change_to_character_creation():
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
