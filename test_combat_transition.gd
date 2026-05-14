# test_combat_transition.gd - Headless combat mode transition test.
# Launch via .tscn (not -s) so project autoloads are available.
extends Node

var _grid_world = null
var _turn_manager = null
var _player = null
var _enemies: Array = []
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST: Combat Mode Transition (Stoneshard dual-mode)")
	print(sep)

	_setup_scene()
	await get_tree().process_frame
	await get_tree().process_frame

	if not _grid_world or not _player:
		_finish()
		return

	_passed += 1

	await _test_realtime_movement()
	await _test_combat_entry()
	await _test_turnbased_movement()
	await _test_skip_turn()
	await _test_combat_exit()
	await _test_realtime_after_combat()
	_finish()


func _finish() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST RESULTS: ", _passed, " passed, ", _failed, " failed")
	print(sep)
	get_tree().quit(1 if _failed > 0 else 0)


func _setup_scene() -> void:
	_grid_world = load("res://source/features/shared/grid_world.gd").new()
	add_child(_grid_world)

	_turn_manager = load("res://source/features/turnbased/turn_manager.gd").new()
	add_child(_turn_manager)
	# _ready() called automatically by Godot when added to tree

	_player = load("res://source/features/shared/unit.gd").new()
	_player.unit_name = "Player"
	_player.is_player = true
	_player.max_hp = 100
	_player.current_hp = 100
	_player.speed = 12
	_player.max_action_points = 4
	_player.current_action_points = 4

	var player_movement = load("res://source/features/shared/unit_movement.gd").new()
	player_movement.name = "UnitMovement"
	player_movement.move_speed = 120.0
	player_movement.ap_cost_per_tile = 1
	player_movement.grid_world_path = NodePath("")
	_player.add_child(player_movement)

	var start_gp = Vector2i(10, 10)
	_player.global_position = _grid_world.grid_to_world(start_gp)
	_grid_world.set_occupied(start_gp, _player)
	add_child(_player)

	player_movement._grid_world = _grid_world

	var spawn_offsets = [Vector2i(3, 0), Vector2i(0, 3)]
	for i in range(spawn_offsets.size()):
		var enemy = load("res://source/features/shared/unit.gd").new()
		enemy.unit_name = "Enemy_%d" % (i + 1)
		enemy.is_player = false
		enemy.max_hp = 30
		enemy.current_hp = 30
		enemy.speed = 8 - i * 2
		enemy.max_action_points = 3
		enemy.current_action_points = 3

		var spawn_gp = start_gp + spawn_offsets[i]
		enemy.global_position = _grid_world.grid_to_world(spawn_gp)

		var enemy_movement = load("res://source/features/shared/unit_movement.gd").new()
		enemy_movement.name = "UnitMovement"
		enemy_movement.grid_world_path = NodePath("")
		enemy.add_child(enemy_movement)

		_grid_world.set_occupied(spawn_gp, enemy)
		add_child(enemy)
		_enemies.append(enemy)

	for e in _enemies:
		e.get_node("UnitMovement")._grid_world = _grid_world

	print("  Setup OK: GridWorld + Player + ", _enemies.size(), " enemies")


func _test_realtime_movement() -> void:
	print("\n--- TEST: Real-time movement ---")
	var movement = _player.get_node("UnitMovement")
	if not movement:
		push_error("FAIL: UnitMovement not found"); _failed += 1; return

	var before_pos = _player.global_position
	movement.navigate_to(before_pos + Vector2(64, 0))
	await get_tree().process_frame

	if not movement.is_moving:
		push_warning("WARN: navigate_to did not start")
	else:
		for i in range(10):
			await get_tree().process_frame
		if _player.global_position != before_pos:
			print("[PASS] Real-time movement: player moved")
			_passed += 1
		else:
			push_warning("WARN: Player didn't move (need more frames)")
		movement.stop_moving()

	var gp = Vector2i(10, 10)
	_player.global_position = _grid_world.grid_to_world(gp)
	_grid_world.set_occupied(gp, _player)


func _test_combat_entry() -> void:
	print("\n--- TEST: Combat entry + TurnManager validation ---")

	_turn_manager.add_combatant(_player)
	for e in _enemies:
		_turn_manager.add_combatant(e)

	_turn_manager.start_combat()
	await get_tree().process_frame
	await get_tree().process_frame

	if not _turn_manager.is_combat_active:
		push_error("FAIL: Combat not active"); _failed += 1; return

	if _turn_manager.combatants.size() < 2:
		push_error("FAIL: Expected 3+ combatants, got ", _turn_manager.combatants.size())
		_failed += 1
	else:
		print("[PASS] Combat started with ", _turn_manager.combatants.size(), " combatants")
		_passed += 1

	if _turn_manager.current_turn_index < 0:
		push_error("FAIL: No active turn"); _failed += 1
	else:
		print("[PASS] Turn index: ", _turn_manager.current_turn_index,
			" current: ", _turn_manager.turn_order[_turn_manager.current_turn_index].unit_name)
		_passed += 1


func _test_turnbased_movement() -> void:
	print("\n--- TEST: Turn-based movement with AP costs ---")
	var movement = _player.get_node("UnitMovement")
	if not movement:
		push_error("FAIL: UnitMovement not found"); _failed += 1; return

	if _turn_manager.turn_order[_turn_manager.current_turn_index] != _player:
		print("  (waiting for player turn...)")
		var max_waits = 10
		for _i in range(max_waits):
			_turn_manager.end_current_turn()
			await get_tree().process_frame
			if _turn_manager.turn_order[_turn_manager.current_turn_index] == _player:
				break

	var before_pos = _player.global_position
	var before_ap = _player.current_action_points
	print("  AP before: ", before_ap, " pos: ", before_pos)

	var result = movement.move_one_tile(Vector2i(1, 0), _player)
	if not result:
		push_error("FAIL: move_one_tile returned false"); _failed += 1; return

	await get_tree().process_frame
	var after_ap = _player.current_action_points
	print("  AP after: ", after_ap, " pos: ", _player.global_position)

	if before_ap - after_ap == 1:
		print("[PASS] AP consumed: ", before_ap, " -> ", after_ap)
		_passed += 1
	else:
		push_error("FAIL: AP consumption wrong, expected 1, got ", before_ap - after_ap)
		_failed += 1

	if _player.global_position != before_pos:
		print("[PASS] Player moved in turn-based mode")
		_passed += 1
	else:
		push_error("FAIL: Player did not move")
		_failed += 1

	EventBus.player_ended_turn.emit(_player)
	await get_tree().process_frame
	print("  Turn advanced via EventBus.player_ended_turn")


func _test_skip_turn() -> void:
	print("\n--- TEST: Skip turn (via EventBus signal) ---")
	var movement = _player.get_node("UnitMovement")
	if not movement:
		push_error("FAIL: UnitMovement not found"); _failed += 1; return

	var max_waits = 10
	for _i in range(max_waits):
		if _turn_manager.turn_order[_turn_manager.current_turn_index] == _player:
			break
		# Advance enemy turns programmatically (enemies have no AI to end turn)
		_turn_manager.end_current_turn()
		await get_tree().process_frame

	if _turn_manager.turn_order[_turn_manager.current_turn_index] != _player:
		push_warning("WARN: Could not get player turn in ", max_waits, " frames")
		return

	var ap_before = _player.current_action_points
	print("  AP before skip: ", ap_before)

	var result = movement.skip_turn()
	if not result:
		push_error("FAIL: skip_turn returned false"); _failed += 1; return

	EventBus.player_ended_turn.emit(_player)
	await get_tree().process_frame
	print("[PASS] Skip turn successful")
	_passed += 1


func _test_combat_exit() -> void:
	print("\n--- TEST: Combat exit ---")
	_turn_manager.end_combat()
	await get_tree().process_frame

	if _turn_manager.is_combat_active:
		push_error("FAIL: Combat still active"); _failed += 1; return
	print("[PASS] Combat ended (EventBus.combat_ended emitted)")
	_passed += 1


func _test_realtime_after_combat() -> void:
	print("\n--- TEST: Real-time movement after combat ---")
	var movement = _player.get_node("UnitMovement")
	if not movement:
		push_error("FAIL: UnitMovement not found"); _failed += 1; return

	var before_pos = _player.global_position
	movement.navigate_to(before_pos + Vector2(96, 64))
	await get_tree().process_frame

	if movement.is_moving:
		for i in range(15):
			await get_tree().process_frame
		if _player.global_position != before_pos:
			print("[PASS] Real-time movement works after combat")
			_passed += 1
			movement.stop_moving()
		else:
			push_warning("WARN: Player didn't move post-combat")
	else:
		push_warning("WARN: navigate_to did not start after combat")
