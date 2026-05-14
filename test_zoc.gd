# test_zoc.gd — Headless ZOC (Zone of Control) test.
# ZOC AP 비용, Attack of Opportunity 발동 조건을 검증한다.
extends Node

const ZocController = preload("res://source/features/turnbased/zoc_controller.gd")

var _grid_world = null
var _turn_manager = null
var _player = null
var _enemy = null
var _passed: int = 0
var _failed: int = 0

# AoO tracking
var _aoo_events: Array = []


func _ready() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST: Zone of Control (AP cost + Attack of Opportunity)")
	print(sep)

	_setup_scene()
	await get_tree().process_frame
	await get_tree().process_frame

	if not _grid_world or not _player or not _enemy:
		push_error("FATAL: Setup incomplete")
		_finish()
		return
	_passed += 1

	await _test_zoc_tile_detection()
	await _test_extra_ap_cost_entering_zoc()
	await _test_no_extra_ap_normal_move()
	await _test_attack_of_opportunity()
	await _test_zoc_range_zero_disabled()
	_finish()


func _finish() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST RESULTS: ", _passed, " passed, ", _failed, " failed")
	print(sep)
	get_tree().quit(1 if _failed > 0 else 0)


func _setup_scene() -> void:
	# ── Scene structure matching game paths ──
	# /root/test ← self
	#   GameLoop/  (so unit_movement._get_combatants() finds /root/Main/GameLoop/TurnManager)
	#     TurnManager
	#   GridWorld
	#   Player
	#   Enemy
	var game_loop = Node.new()
	game_loop.name = "GameLoop"
	var main = Node.new()
	main.name = "Main"
	main.add_child(game_loop)
	add_child(main)

	# ── TurnManager at /root/Main/GameLoop/TurnManager ──
	_turn_manager = load("res://source/features/turnbased/turn_manager.gd").new()
	_turn_manager.name = "TurnManager"
	game_loop.add_child(_turn_manager)
	await get_tree().process_frame

	# ── GridWorld (10x10 for compact tests) ──
	_grid_world = load("res://source/features/shared/grid_world.gd").new()
	_grid_world.name = "GridWorld"
	_grid_world.grid_width = 10
	_grid_world.grid_height = 10
	add_child(_grid_world)
	await get_tree().process_frame

	# ── Player at (2, 2) ──
	_player = load("res://source/features/shared/unit.gd").new()
	_player.unit_name = "Player"
	_player.is_player = true
	_player.max_hp = 100
	_player.current_hp = 100
	_player.speed = 12
	_player.max_action_points = 6
	_player.current_action_points = 6
	_player.zoc_range = 1

	var player_movement = load("res://source/features/shared/unit_movement.gd").new()
	player_movement.name = "UnitMovement"
	player_movement.move_speed = 120.0
	player_movement.ap_cost_per_tile = 1
	player_movement.grid_world_path = NodePath("")
	_player.add_child(player_movement)

	_player.global_position = _grid_world.grid_to_world(Vector2i(2, 2))
	_grid_world.set_occupied(Vector2i(2, 2), _player)
	add_child(_player)
	player_movement._grid_world = _grid_world

	# ── Enemy at (2, 4) — 2 tiles below player ──
	_enemy = load("res://source/features/shared/unit.gd").new()
	_enemy.unit_name = "TestEnemy"
	_enemy.is_player = false
	_enemy.max_hp = 50
	_enemy.current_hp = 50
	_enemy.speed = 8
	_enemy.max_action_points = 4
	_enemy.current_action_points = 4
	_enemy.zoc_range = 1    # Controls adjacent 8 tiles
	_enemy.attack = 15

	var enemy_movement = load("res://source/features/shared/unit_movement.gd").new()
	enemy_movement.name = "UnitMovement"
	enemy_movement.move_speed = 120.0
	enemy_movement.ap_cost_per_tile = 1
	enemy_movement.grid_world_path = NodePath("")
	_enemy.add_child(enemy_movement)

	_enemy.global_position = _grid_world.grid_to_world(Vector2i(2, 4))
	_grid_world.set_occupied(Vector2i(2, 4), _enemy)
	add_child(_enemy)
	enemy_movement._grid_world = _grid_world

	# Register combatants
	_turn_manager.add_combatant(_player)
	_turn_manager.add_combatant(_enemy)

	# Connect AoO signal
	EventBus.attack_of_opportunity.connect(_on_attack_of_opportunity)


func _clear_aoo_events() -> void:
	_aoo_events.clear()


func _on_attack_of_opportunity(attacker: Node, target: Node, damage: int, hit: bool) -> void:
	_aoo_events.append({attacker = attacker, target = target, damage = damage, hit = hit})


# ─── Test 1: ZOC tile detection ───
func _test_zoc_tile_detection() -> void:
	print("\n--- TEST: ZOC tile detection ---")

	# Enemy at (2,4) controls adjacent 8 tiles: (1,3)(2,3)(3,3)(1,4)(3,4)(1,5)(2,5)(3,5)
	var enemy_zoc = ZocController.get_zoc_tiles(_enemy, _grid_world)
	print("  Enemy ZOC tiles: ", enemy_zoc)

	if enemy_zoc.size() == 8:
		_passed += 1
		print("[PASS] Enemy controls 8 adjacent tiles")
	else:
		_failed += 1
		push_error("FAIL: Expected 8 ZOC tiles, got ", enemy_zoc.size())

	# (2,3) is adjacent to enemy → should be in ZOC
	var tile_in_zoc: Vector2i = Vector2i(2, 3)
	var tile_above: Vector2i = Vector2i(2, 1)

	var combatants = _turn_manager.combatants
	var in_zoc = ZocController.is_in_enemy_zoc(tile_in_zoc, _player, combatants, _grid_world)
	var not_in_zoc = ZocController.is_in_enemy_zoc(tile_above, _player, combatants, _grid_world)

	if in_zoc and not not_in_zoc:
		_passed += 1
		print("[PASS] ZOC detection: (2,3) in ZOC, (2,1) not in ZOC")
	else:
		_failed += 1
		push_error("FAIL: ZOC detection wrong. in_zoc=", in_zoc, " not_in_zoc=", not_in_zoc)


# ─── Test 2: Extra AP cost for entering ZOC ───
func _test_extra_ap_cost_entering_zoc() -> void:
	print("\n--- TEST: Extra AP cost entering ZOC ---")

	# Player at (2,2). Move to (2,3) which is in enemy's ZOC (enemy at 2,4)
	# Base cost = 1, ZOC extra = 1, total = 2
	var player_movement = _player.get_node("UnitMovement")
	_player.current_action_points = 5

	var extra_cost = ZocController.get_extra_ap_cost(_player, Vector2i(2, 3), _turn_manager.combatants, _grid_world)
	print("  ZOC extra AP cost: ", extra_cost, " (expected: 1)")

	if extra_cost == 1:
		_passed += 1
		print("[PASS] ZOC extra AP cost is 1 for enemy ZOC tile")
	else:
		_failed += 1
		push_error("FAIL: Expected extra cost 1, got ", extra_cost)

	# Move to (2,3) — should cost 2 AP (1 base + 1 ZOC)
	var ap_before = _player.current_action_points
	player_movement.move_one_tile(Vector2i(0, 1), _player)
	var ap_after = _player.current_action_points
	var ap_cost = ap_before - ap_after

	print("  AP before: ", ap_before, " after: ", ap_after, " cost: ", ap_cost, " (expected: 2)")

	if ap_cost == 2:
		_passed += 1
		print("[PASS] Move into ZOC cost 2 AP (base 1 + ZOC 1)")
	else:
		_failed += 1
		push_error("FAIL: Expected AP cost 2, got ", ap_cost)


# ─── Test 3: No extra AP for normal (non-ZOC) tile ───
func _test_no_extra_ap_normal_move() -> void:
	print("\n--- TEST: Normal move (no ZOC) AP cost ---")

	# Player is now at (2,3). Move to (2,2) which is NOT in enemy ZOC
	# (2,2) is at distance 2 from enemy at (2,4) — not adjacent
	var player_movement = _player.get_node("UnitMovement")
	_player.current_action_points = 5

	# Move back to (2,2)
	var ap_before = _player.current_action_points
	player_movement.move_one_tile(Vector2i(0, -1), _player)
	var ap_after = _player.current_action_points
	var ap_cost = ap_before - ap_after

	print("  Move to (2,2): AP cost: ", ap_cost, " (expected: 1)")

	if ap_cost == 1:
		_passed += 1
		print("[PASS] Normal move cost 1 AP (no ZOC)")
	else:
		_failed += 1
		push_error("FAIL: Expected AP cost 1, got ", ap_cost)


# ─── Test 4: Attack of Opportunity ───
func _test_attack_of_opportunity() -> void:
	print("\n--- TEST: Attack of Opportunity ---")

	# Player is at (2,2). Move to (2,3) (enters ZOC) — no AoO expected
	# Then move to (2,4) which is the enemy's own tile — no move, it's occupied
	# Move to (2,2) from (2,3) — leaving ZOC, AoO expected

	# First: enter ZOC at (2,3) — no AoO (entering, not leaving)
	var player_movement = _player.get_node("UnitMovement")
	_player.current_action_points = 5
	_clear_aoo_events()

	# Move to (2,3) — entering ZOC, no AoO
	player_movement.move_one_tile(Vector2i(0, 1), _player)
	print("  AoO events after entering ZOC: ", _aoo_events.size(), " (expected: 0)")

	if _aoo_events.size() == 0:
		_passed += 1
		print("[PASS] No AoO when entering ZOC")
	else:
		_failed += 1
		push_error("FAIL: Unexpected AoO when entering ZOC")

	# Now move from (2,3) to (2,2) — LEAVING ZOC, AoO expected
	var enemy_hp_before = _enemy.current_hp  # Not affected
	_player.current_action_points = 5
	_clear_aoo_events()

	player_movement.move_one_tile(Vector2i(0, -1), _player)
	print("  AoO events after leaving ZOC: ", _aoo_events.size(), " (expected: 1)")

	if _aoo_events.size() == 1:
		var event = _aoo_events[0]
		if event.attacker == _enemy and event.target == _player:
			_passed += 1
			print("[PASS] AoO triggered: enemy attacked player, damage=", event.damage, " hit=", event.hit)
		else:
			_failed += 1
			push_error("FAIL: AoO wrong attacker/target")
	else:
		_failed += 1
		push_error("FAIL: Expected 1 AoO event, got ", _aoo_events.size())


# ─── Test 5: zoc_range = 0 disables ZOC ───
func _test_zoc_range_zero_disabled() -> void:
	print("\n--- TEST: zoc_range = 0 disables ZOC ---")

	# Set enemy zoc_range to 0
	_enemy.zoc_range = 0

	# (2,3) should no longer be in enemy ZOC
	var in_zoc = ZocController.is_in_enemy_zoc(Vector2i(2, 3), _player, _turn_manager.combatants, _grid_world)

	if not in_zoc:
		_passed += 1
		print("[PASS] zoc_range=0 disables ZOC, tile no longer controlled")
	else:
		_failed += 1
		push_error("FAIL: zoc_range=0 should disable ZOC")

	# Restore
	_enemy.zoc_range = 1
