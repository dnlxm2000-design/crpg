# test_combat_inventory.gd — 전투 중 인벤토리 아이템 사용(headless) 테스트.
# 힐 포션 사용이 AP 소모, HP 회복, 아이템 제거까지 올바르게 동작하는지 검증한다.
extends Node

var _grid_world = null
var _turn_manager = null
var _player = null
var _enemy = null
var _inventory = null
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST: Combat Inventory Use (Health Potion)")
	print(sep)

	_setup_scene()
	await get_tree().process_frame
	await get_tree().process_frame

	# unit.gd _ready()가 current_hp = max_hp로 초기화하므로 다시 설정
	_player.current_hp = 50
	_player.current_action_points = 4

	if not _grid_world or not _player or not _inventory:
		push_error("FATAL: Setup incomplete")
		_finish()
		return

	_passed += 1  # Setup OK

	await _test_add_potion()
	await _test_use_potion_in_combat()
	await _test_ap_consumed()
	await _test_hp_healed()
	await _test_item_consumed()
	_finish()


func _finish() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST RESULTS: ", _passed, " passed, ", _failed, " failed")
	print(sep)
	get_tree().quit(1 if _failed > 0 else 0)


func _setup_scene() -> void:
	# ── GridWorld ──
	_grid_world = load("res://source/features/shared/grid_world.gd").new()
	add_child(_grid_world)

	# ── TurnManager ──
	_turn_manager = load("res://source/features/turnbased/turn_manager.gd").new()
	add_child(_turn_manager)
	await get_tree().process_frame

	# ── Player ──
	_player = load("res://source/features/shared/unit.gd").new()
	_player.unit_name = "TestPlayer"
	_player.is_player = true
	_player.max_hp = 100
	_player.current_hp = 50       # Start injured
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

	# ── Inventory ──
	_inventory = load("res://source/features/shared/inventory/inventory.gd").new()
	_inventory.name = "Inventory"
	_player.add_child(_inventory)

	# ── Enemy ──
	_enemy = load("res://source/features/shared/unit.gd").new()
	_enemy.unit_name = "TestEnemy"
	_enemy.is_player = false
	_enemy.max_hp = 20
	_enemy.current_hp = 20
	_enemy.speed = 8

	var enemy_movement = load("res://source/features/shared/unit_movement.gd").new()
	enemy_movement.name = "UnitMovement"
	enemy_movement.move_speed = 60.0
	enemy_movement.ap_cost_per_tile = 1
	enemy_movement.grid_world_path = NodePath("")
	_enemy.add_child(enemy_movement)

	var enemy_gp = Vector2i(10, 12)
	_enemy.global_position = _grid_world.grid_to_world(enemy_gp)
	_grid_world.set_occupied(enemy_gp, _enemy)
	add_child(_enemy)
	enemy_movement._grid_world = _grid_world

	print("  Setup OK: Player(HP: 50/100, AP: 4) + Inventory + Enemy at 2 tiles")

	# ── GameState ──
	# Autoload GameState expected; set to TURNBASED after combat starts


func _test_add_potion() -> void:
	print("\n--- TEST: Add Health Potion to inventory ---")
	var potion = load("res://source/data/items/resources/health_potion.tres")
	var ok: bool = _inventory.add_item(potion)
	if ok and _inventory.get_item_count("health_potion") == 1:
		print("[PASS] Health Potion added to inventory (qty=1)")
		_passed += 1
	else:
		push_error("FAIL: Could not add Health Potion")
		_failed += 1


func _test_use_potion_in_combat() -> void:
	print("\n--- TEST: Use Health Potion in combat mode ---")

	# Start combat
	_turn_manager.add_combatant(_player)
	_turn_manager.add_combatant(_enemy)
	_turn_manager.start_combat()
	await get_tree().process_frame
	await get_tree().process_frame

	if not _turn_manager.is_combat_active:
		push_error("FAIL: Combat did not start"); _failed += 1; return

	# Set GameState to TURNBASED so AP cost is enforced
	GameState.current_mode = GameState.GameMode.TURNBASED

	var current_ap = _player.current_action_points
	var current_hp = _player.current_hp

	# Use potion
	var used: bool = _inventory.use_item("health_potion", _player)
	if used:
		print("[PASS] use_item returned true")
		_passed += 1
	else:
		push_error("FAIL: use_item returned false (AP=%d, HP=%d)" % [current_ap, current_hp])
		_failed += 1


func _test_ap_consumed() -> void:
	print("\n--- TEST: AP consumed ---")
	var expected_ap = 4 - 1  # 4 AP start, potion costs 1
	var actual_ap = _player.current_action_points
	if actual_ap == expected_ap:
		print("[PASS] AP consumed: 4 -> %d (cost 1)" % actual_ap)
		_passed += 1
	else:
		push_error("FAIL: Expected AP=%d, got AP=%d" % [expected_ap, actual_ap])
		_failed += 1


func _test_hp_healed() -> void:
	print("\n--- TEST: HP healed ---")
	var expected_hp = 50 + 25  # Start 50, heal 25
	var actual_hp = _player.current_hp
	if actual_hp == expected_hp:
		print("[PASS] HP healed: 50 -> %d (heal 25)" % actual_hp)
		_passed += 1
	else:
		push_error("FAIL: Expected HP=%d, got HP=%d" % [expected_hp, actual_hp])
		_failed += 1


func _test_item_consumed() -> void:
	print("\n--- TEST: Item consumed from inventory ---")
	var qty = _inventory.get_item_count("health_potion")
	if qty == 0:
		print("[PASS] Health Potion removed from inventory (qty=0)")
		_passed += 1
	else:
		push_error("FAIL: Expected qty=0, got qty=%d" % qty)
		_failed += 1
