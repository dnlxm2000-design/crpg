# test_movement.gd — Automated movement test
# Run: Godot_v4.6.2-stable_win64_console.exe --headless --path . -s test_movement.gd
extends SceneTree

func _init() -> void:
	print("=== MOVEMENT TEST ===")
	
	# Load the main scene
	var main_scene = load("res://source/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	
	# Wait a frame for _ready() to fire
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find player
	var rt = main.get_node("RealTimeManager")
	var player = rt.get_node("PlayerUnit")
	if not player:
		print("FAIL: Player not spawned")
		quit()
		return
	
	print("Player found: ", player.name, " at position: ", player.global_position)
	
	# Find movement component
	var movement = player.get_node("UnitMovement")
	if not movement:
		print("FAIL: UnitMovement not found")
		quit()
		return
	
	print("UnitMovement found: grid_world=", movement.get_grid_world() != null)
	
	# Test 1: navigate_to
	print("\n--- Test 1: navigate_to ---")
	var from_pos = player.global_position
	var initial_grid = movement.get_grid_world().world_to_grid(from_pos)
	print("Initial grid: ", initial_grid)
	
	var target_world = movement.get_grid_world().grid_to_world(initial_grid + Vector2i(3, 2))
	print("Navigating to: ", target_world)
	movement.navigate_to(target_world)
	
	# Run frames to let movement happen
	for i in range(60):
		await get_tree().process_frame
		if not movement.is_moving:
			break
	
	var final_pos = player.global_position
	print("Final position: ", final_pos)
	print("Moved: ", from_pos.distance_to(final_pos) > 1.0)
	
	# Test 2: move_one_tile
	print("\n--- Test 2: move_one_tile ---")
	var before = player.global_position
	print("Before: ", before)
	
	var moved = movement.move_one_tile(Vector2i(0, 1), player)
	var after = player.global_position
	print("Moved: ", moved, " | After: ", after, " | Changed: ", before.distance_to(after) > 1.0)
	
	# Test 3: arrow keys via input map
	print("\n--- Test 3: Input actions ---")
	var action = InputMap.action_get_events("move_right")
	print("move_right events: ", action.size())
	if action.size() > 0:
		print("  keycode: ", action[0].as_text())
	
	print("\n=== TEST COMPLETE ===")
	quit()
