# test_equipment.gd — 장비 시스템(headless) 테스트.
# 무기/방어구 장착 → stat 변화 → 해제 → 인벤토리 반환까지 검증한다.
extends Node

var _player = null
var _inventory = null
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST: Equipment System (Weapon / Armor)")
	print(sep)

	_setup()
	await get_tree().process_frame

	if not _player or not _inventory:
		push_error("FATAL: Setup incomplete")
		_finish()
		return
	_passed += 1

	await _test_initial_stats()
	await _test_equip_sword()
	await _test_equip_armor()
	await _test_unequip_weapon()
	await _test_re_equip_sword()
	_finish()


func _finish() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST RESULTS: ", _passed, " passed, ", _failed, " failed")
	print(sep)
	get_tree().quit(1 if _failed > 0 else 0)


func _setup() -> void:
	_player = load("res://source/features/shared/unit.gd").new()
	_player.unit_name = "TestPlayer"
	_player.is_player = true
	_player.max_hp = 100
	_player.current_hp = 100
	_player.attack = 10
	_player.defense = 5
	add_child(_player)   # _ready() runs: current_hp = max_hp

	_inventory = load("res://source/features/shared/inventory/inventory.gd").new()
	_inventory.name = "Inventory"
	_player.add_child(_inventory)

	# Add items to inventory
	var sword = load("res://source/data/items/resources/iron_sword.tres")
	var armor = load("res://source/data/items/resources/leather_armor.tres")
	_inventory.add_item(sword, 1)
	_inventory.add_item(armor, 1)

	print("  Setup: Player(atk=%d, def=%d) + Sword(dmg_bonus=5) + Armor(def_bonus=3) in inventory"
		% [_player.attack, _player.defense])


func _test_initial_stats() -> void:
	print("\n--- TEST: Initial stats (no equipment) ---")
	var atk = _player.get_attack()
	var def_ = _player.get_defense()
	if atk == 10 and def_ == 5:
		print("[PASS] Base stats: atk=%d, def=%d" % [atk, def_])
		_passed += 1
	else:
		push_error("FAIL: Expected atk=10, def=5, got atk=%d, def=%d" % [atk, def_])
		_failed += 1


func _test_equip_sword() -> void:
	print("\n--- TEST: Equip Iron Sword (damage_bonus=5) ---")
	var result = _inventory.equip_item("iron_sword", _player)
	if not result.get("success", false):
		push_error("FAIL: equip_item returned false: %s" % result.get("message", ""))
		_failed += 1; return

	# Attack should be 10 + 5 = 15
	var atk = _player.get_attack()
	if atk == 15:
		print("[PASS] Attack increased: 10 -> %d (bonus=5)" % atk)
		_passed += 1
	else:
		push_error("FAIL: Expected atk=15, got %d" % atk)
		_failed += 1

	# Sword should be removed from inventory
	var qty = _inventory.get_item_count("iron_sword")
	if qty == 0:
		print("[PASS] Sword removed from inventory (qty=%d)" % qty)
		_passed += 1
	else:
		push_error("FAIL: Sword still in inventory (qty=%d)" % qty)
		_failed += 1


func _test_equip_armor() -> void:
	print("\n--- TEST: Equip Leather Armor (defense_bonus=3) ---")
	var result = _inventory.equip_item("leather_armor", _player)
	if not result.get("success", false):
		push_error("FAIL: equip_item returned false")
		_failed += 1; return

	var def_ = _player.get_defense()
	if def_ == 8:  # 5 + 3
		print("[PASS] Defense increased: 5 -> %d (bonus=3)" % def_)
		_passed += 1
	else:
		push_error("FAIL: Expected def=8, got %d" % def_)
		_failed += 1

	# Both stats should reflect both items
	var atk = _player.get_attack()
	if atk == 15 and def_ == 8:
		print("[PASS] Both equipment active: atk=%d, def=%d" % [atk, def_])
		_passed += 1
	else:
		push_error("FAIL: Expected atk=15, def=8, got atk=%d, def=%d" % [atk, def_])
		_failed += 1


func _test_unequip_weapon() -> void:
	print("\n--- TEST: Unequip weapon ---")
	var ok = _inventory.unequip_item("equipped_weapon", _player)
	if not ok:
		push_error("FAIL: unequip_item returned false")
		_failed += 1; return

	var atk = _player.get_attack()
	if atk == 10:
		print("[PASS] Attack returned to base: %d (weapon bonus removed)" % atk)
		_passed += 1
	else:
		push_error("FAIL: Expected atk=10, got %d" % atk)
		_failed += 1

	# Sword should be back in inventory
	var qty = _inventory.get_item_count("iron_sword")
	if qty == 1:
		print("[PASS] Sword returned to inventory (qty=%d)" % qty)
		_passed += 1
	else:
		push_error("FAIL: Sword not in inventory (qty=%d)" % qty)
		_failed += 1


func _test_re_equip_sword() -> void:
	print("\n--- TEST: Re-equip sword after unequip (verify full cycle) ---")
	# After unequip, sword is back in inventory (qty=1), weapon slot empty.
	var result = _inventory.equip_item("iron_sword", _player)
	if not result.get("success", false):
		push_error("FAIL: Re-equip failed: %s" % result.get("message", ""))
		_failed += 1; return

	var atk = _player.get_attack()
	if atk == 15:
		print("[PASS] Re-equipped sword: atk=%d (full cycle: equip→unequip→re-equip)" % atk)
		_passed += 1
	else:
		push_error("FAIL: Expected atk=15, got %d" % atk)
		_failed += 1
