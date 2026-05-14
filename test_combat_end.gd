# test_combat_end.gd — Headless test for combat victory/defeat detection.
extends Node

var _grid_world = null
var _turn_manager = null
var _passed: int = 0
var _failed: int = 0
var _victory_fired: bool = false
var _defeat_fired: bool = false


func _ready() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST: Combat End Conditions (Victory / Defeat)")
	print(sep)

	_grid_world = load("res://source/features/shared/grid_world.gd").new()
	add_child(_grid_world)
	await get_tree().process_frame

	if not _grid_world:
		push_error("FAIL: GridWorld not created")
		_finish()
		return
	_passed += 1
	print("[PASS] GridWorld ready")

	await _test_victory_when_enemy_dies()
	await _test_defeat_when_player_dies()
	_finish()


func _make_unit(name: String, is_player: bool, grid_pos: Vector2i, hp: int, spd: int) -> Node:
	var unit = load("res://source/features/shared/unit.gd").new()
	unit.unit_name = name
	unit.is_player = is_player
	unit.max_hp = hp
	unit.current_hp = hp
	unit.speed = spd
	unit.max_action_points = 4
	unit.current_action_points = 4
	unit.attack = 10 if is_player else 3
	unit.defense = 5

	var movement = load("res://source/features/shared/unit_movement.gd").new()
	movement.name = "UnitMovement"
	movement.grid_world_path = NodePath("")
	unit.add_child(movement)
	unit.global_position = _grid_world.grid_to_world(grid_pos)
	_grid_world.set_occupied(grid_pos, unit)
	add_child(unit)
	movement._grid_world = _grid_world

	if not is_player:
		var ai = load("res://source/features/shared/enemy_ai.gd").new()
		ai.name = "EnemyAI"
		unit.add_child(ai)
		ai._grid_world = _grid_world

	return unit


func _test_victory_when_enemy_dies() -> void:
	print("\n--- TEST: Combat victory when all enemies die ---")

	_turn_manager = load("res://source/features/turnbased/turn_manager.gd").new()
	add_child(_turn_manager)

	var player = _make_unit("Player", true, Vector2i(5, 5), 100, 12)
	var enemy = _make_unit("Enemy", false, Vector2i(5, 6), 10, 6)

	_victory_fired = false
	EventBus.combat_victory.connect(func(): _victory_fired = true, CONNECT_ONE_SHOT)

	_turn_manager.add_combatant(player)
	_turn_manager.add_combatant(enemy)
	_turn_manager.start_combat()
	await get_tree().process_frame

	if not _turn_manager.is_combat_active:
		push_error("FAIL: Combat not active")
		_failed += 1
		return
	print("  Combatants: ", _turn_manager.combatants.size(),
		" | Enemy HP: ", enemy.current_hp)

	# First hit: attack(10) - defense(5) = 5 damage → enemy 10→5 HP
	enemy.take_damage(player.attack, player)
	await get_tree().process_frame
	print("  After hit 1: Enemy HP = ", enemy.current_hp)

	if enemy.current_hp <= 0:
		push_error("FAIL: Enemy died too early")
		_failed += 1
		return

	# Second hit kills (5 - 5 = 0 → die())
	enemy.take_damage(player.attack, player)
	await get_tree().process_frame

	if _victory_fired:
		_passed += 1
		print("[PASS] combat_victory signal fired after enemy death")
	else:
		push_error("FAIL: combat_victory not fired")
		_failed += 1

	if not _turn_manager.is_combat_active:
		_passed += 1
		print("[PASS] Combat deactivated after victory")
	else:
		push_error("FAIL: Combat still active after victory")
		_failed += 1


func _test_defeat_when_player_dies() -> void:
	print("\n--- TEST: Combat defeat when player dies ---")

	_turn_manager = load("res://source/features/turnbased/turn_manager.gd").new()
	add_child(_turn_manager)

	# Low-HP player that dies in one hit
	var weak_player = _make_unit("WeakPlayer", true, Vector2i(8, 8), 1, 12)
	# Enemy adjacent, can attack immediately
	var attacker = _make_unit("Attacker", false, Vector2i(8, 9), 20, 6)

	_defeat_fired = false
	EventBus.combat_defeat.connect(func(): _defeat_fired = true, CONNECT_ONE_SHOT)

	_turn_manager.add_combatant(weak_player)
	_turn_manager.add_combatant(attacker)
	_turn_manager.start_combat()
	await get_tree().process_frame

	if not _turn_manager.is_combat_active:
		push_error("FAIL: Combat not active in defeat test")
		_failed += 1
		return

	# Simulate enemy attack: deal damage directly to weak player
	weak_player.take_damage(attacker.attack, attacker)
	await get_tree().process_frame

	if _defeat_fired:
		_passed += 1
		print("[PASS] combat_defeat signal fired after weak player death")
	else:
		# Check if player actually died
		if not is_instance_valid(weak_player) or not weak_player.get("is_alive"):
			push_error("FAIL: Player died but defeat signal not fired")
			_failed += 1
		else:
			push_warning("WARN: Defeat not fired and player still alive (unexpected)")
			_failed += 1


func _finish() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST RESULTS: ", _passed, " passed, ", _failed, " failed")
	print(sep)
	get_tree().quit(1 if _failed > 0 else 0)

