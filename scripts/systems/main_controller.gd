# MainController - Main game controller

extends Node

enum GameState { EXPLORATION, COMBAT, PAUSED }

var current_state: GameState = GameState.EXPLORATION
var walkable_map: Array = []
var map_width: int = 20
var map_height: int = 20
var tile_size: float = 2.0
var player: Node
var ui_manager_ref: Control
var pathfinding: Node
var wfc_system: Node
var floor_container: Node3D
var wall_container: Node3D
var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var door_material: StandardMaterial3D
var cover_material: StandardMaterial3D

func _ready():
	player = $Player
	pathfinding = load("res://scripts/systems/pathfinding.gd").new()
	add_child(pathfinding)
	pathfinding.set_grid_size(map_width, map_height)
	
	wfc_system = load("res://scripts/systems/wfc_system.gd").new()
	wfc_system.name = "WFCSystem"
	add_child(wfc_system)
	
	_check_tutorial_trigger()

func _check_tutorial_trigger():
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		if not game_manager.is_tutorial_completed() and game_manager.is_first_entry():
			game_manager.set_first_entry_done()
			print("[MainController] First entry - starting Tutorial automatically")
			get_tree().call_group("scenarios", "start_tutorial")
	wfc_system.width = map_width
	wfc_system.height = map_height
	
	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.25, 0.25, 0.3, 1)
	wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.35, 0.2, 0.2, 1)
	door_material = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.55, 0.45, 0.33, 1)
	cover_material = StandardMaterial3D.new()
	cover_material.albedo_color = Color(0.3, 0.3, 0.3, 1)
	
	floor_container = Node3D.new()
	floor_container.name = "FloorTiles"
	add_child(floor_container)
	wall_container = Node3D.new()
	wall_container.name = "WallTiles"
	add_child(wall_container)
	
	_generate_map()
	_generate_terrain()
	player.grid_position = Vector2i(1, 1)
	player.global_position = Vector3(1 * tile_size, 0.5, 1 * tile_size)
	var ui_manager = $CanvasUI/UIManager
	if ui_manager:
		ui_manager.bind_player(player)
		ui_manager.bind_walkable_map(walkable_map, map_width, map_height)
	add_to_group("main")
	BattleSystem.combat_ended.connect(_on_combat_ended)
	ui_manager_ref = ui_manager

func _generate_map():
	walkable_map.clear()
	var tile_grid = wfc_system.generate()
	walkable_map = wfc_system.get_walkable_map()
	print("[WFC] Map generated with WFC system")

func _generate_terrain():
	for y in range(map_height):
		for x in range(map_width):
			var tile_type = wfc_system.output_grid[y][x]
			match tile_type:
				0: _create_wall(x, y)
				1: _create_floor(x, y)
				2: _create_door(x, y)
				4: _create_cover(x, y)
				_: _create_floor(x, y)

func _create_floor(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(tile_size * 0.9, 0.2, tile_size * 0.9)
	mesh_instance.mesh = box
	mesh_instance.material_override = floor_material
	mesh_instance.position = Vector3(x * tile_size, -0.1, y * tile_size)
	floor_container.add_child(mesh_instance)
	
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(tile_size * 0.9, 0.2, tile_size * 0.9)
	collision.position = Vector3(x * tile_size, -0.1, y * tile_size)
	floor_container.add_child(collision)

func _create_wall(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(tile_size, tile_size, tile_size)
	mesh_instance.mesh = box
	mesh_instance.material_override = wall_material
	mesh_instance.position = Vector3(x * tile_size, tile_size / 2, y * tile_size)
	wall_container.add_child(mesh_instance)
	
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(tile_size, tile_size, tile_size)
	collision.position = Vector3(x * tile_size, tile_size / 2, y * tile_size)
	wall_container.add_child(collision)

func _create_door(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(tile_size * 0.8, tile_size * 1.5, tile_size * 0.2)
	mesh_instance.mesh = box
	mesh_instance.material_override = door_material
	mesh_instance.position = Vector3(x * tile_size, tile_size * 0.75, y * tile_size)
	floor_container.add_child(mesh_instance)
	
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(tile_size * 0.8, tile_size * 1.5, tile_size * 0.2)
	collision.position = Vector3(x * tile_size, tile_size * 0.75, y * tile_size)
	floor_container.add_child(collision)

func _create_cover(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(tile_size * 0.6, tile_size * 0.8, tile_size * 0.6)
	mesh_instance.mesh = box
	mesh_instance.material_override = cover_material
	mesh_instance.position = Vector3(x * tile_size, tile_size * 0.4, y * tile_size)
	floor_container.add_child(mesh_instance)

func _unhandled_input(event):
	if current_state == GameState.COMBAT:
		return
	if event.is_action_pressed("ui_left"):
		_move_direction(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		_move_direction(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up"):
		_move_direction(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		_move_direction(Vector2i(0, 1))
	if event.is_action_pressed("ui_accept"):
		player.process_turn()

func _move_direction(dir: Vector2i):
	var new_pos = player.grid_position + dir
	if new_pos.x >= 0 and new_pos.x < map_width and new_pos.y >= 0 and new_pos.y < map_height:
		if walkable_map[new_pos.y][new_pos.x] >= 0:
			player.grid_position = new_pos
			player.global_position = Vector3(new_pos.x * tile_size, 0.5, new_pos.y * tile_size)

func _physics_process(_delta):
	var camera = get_node("Camera3D")
	if camera and player:
		camera.global_position = camera.global_position.lerp(Vector3(player.global_position.x, 15, player.global_position.z + 10), 0.1)

func _on_combat_ended(victory: bool):
	if victory:
		if ui_manager_ref and ui_manager_ref.has_method("add_system_log"):
			ui_manager_ref.add_system_log("Combat Victory!")
		current_state = GameState.EXPLORATION
	else:
		if ui_manager_ref and ui_manager_ref.has_method("add_system_log"):
			ui_manager_ref.add_system_log("Player Died!")
		_show_death_screen()

func _show_death_screen():
	current_state = GameState.PAUSED
	var overlay = CanvasLayer.new()
	overlay.name = "DeathOverlay"
	add_child(overlay)
	var panel = PanelContainer.new()
	panel.anchor_left = 0.3
	panel.anchor_top = 0.3
	panel.anchor_right = 0.7
	panel.anchor_bottom = 0.7
	overlay.add_child(panel)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	var death_label = Label.new()
	death_label.text = "YOU DIED"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 48)
	death_label.modulate = Color(1, 0, 0)
	vbox.add_child(death_label)
	var restart_btn = Button.new()
	restart_btn.text = "RESTART"
	restart_btn.custom_minimum_size = Vector2(200, 60)
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	vbox.add_child(restart_btn)
