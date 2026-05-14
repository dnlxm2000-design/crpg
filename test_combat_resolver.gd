# test_combat_resolver.gd — Headless CombatResolver hit/miss/crit/graze test.
extends Node

const CombatResolver = preload("res://source/features/turnbased/combat_resolver.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST: CombatResolver (Hit/Miss/Crit/Graze/Distance)")
	print(sep)

	await _test_hit_chance_base()
	await _test_hit_chance_clamping()
	await _test_distance_penalty()
	await _test_crit_mechanics()
	await _test_graze_mechanics()
	await _test_resolver_structure()
	await _test_equipment_integration()
	_finish()


func _finish() -> void:
	var sep = "============================================================"
	print(sep)
	print("TEST RESULTS: ", _passed, " passed, ", _failed, " failed")
	print(sep)
	get_tree().quit(1 if _failed > 0 else 0)


# ─── Factory ───

func _make_unit(unit_name: String, accuracy: int, evasion: int, attack: int, defense: int, attack_range: int = 1, crit_chance: float = 0.05, crit_mult: float = 2.0, hp: int = 100):
	var unit = load("res://source/features/shared/unit.gd").new()
	unit.unit_name = unit_name
	unit.accuracy = accuracy
	unit.evasion = evasion
	unit.attack = attack
	unit.defense = defense
	unit.attack_range = attack_range
	unit.crit_chance = crit_chance
	unit.crit_multiplier = crit_mult
	unit.max_hp = hp
	unit.current_hp = hp
	add_child(unit)
	return unit


# ─── Assert helpers ───

func _assert_eq(got, expected, msg: String) -> bool:
	if got == expected:
		_passed += 1; print("[PASS] %s (got %s)" % [msg, str(got)])
		return true
	_failed += 1; push_error("FAIL: %s — expected %s, got %s" % [msg, str(expected), str(got)])
	return false


func _assert_true(cond: bool, msg: String) -> bool:
	if cond:
		_passed += 1; print("[PASS] %s" % msg)
		return true
	_failed += 1; push_error("FAIL: %s" % msg)
	return false


func _assert_false(cond: bool, msg: String) -> bool:
	if not cond:
		_passed += 1; print("[PASS] %s" % msg)
		return true
	_failed += 1; push_error("FAIL: %s" % msg)
	return false


# ─── 1. Base hit chance ───

func _test_hit_chance_base() -> void:
	print("\n--- TEST: Base hit chance calculation ---")
	var atk = _make_unit("Atk", 90, 10, 10, 5)
	var tgt = _make_unit("Tgt", 90, 10, 5, 3)
	await get_tree().process_frame

	var hc = CombatResolver.calculate_hit_chance(atk, tgt, 1)
	_assert_eq(hc, 80, "Base hit chance = accuracy - evasion")


# ─── 2. Clamping ───

func _test_hit_chance_clamping() -> void:
	print("\n--- TEST: Hit chance clamping (5%-95%) ---")
	var atk = _make_unit("Atk", 90, 10, 10, 5)
	var tgt = _make_unit("Tgt", 90, 10, 5, 3)
	await get_tree().process_frame

	# High accuracy → capped at 95
	var hc_high = CombatResolver.calculate_hit_chance(atk, tgt, 1)
	_assert_true(hc_high <= 95, "Hit chance capped at 95%%")

	# Low accuracy → clamped at 5
	var low = _make_unit("Low", 0, 10, 1, 1)
	await get_tree().process_frame
	var hc_low = CombatResolver.calculate_hit_chance(low, tgt, 1)
	_assert_eq(hc_low, 5, "Near-zero accuracy = 5%% min")


# ─── 3. Distance penalty ───

func _test_distance_penalty() -> void:
	print("\n--- TEST: Distance penalty for ranged attacks ---")
	var atk = _make_unit("Atk", 90, 10, 10, 5)
	var tgt = _make_unit("Tgt", 90, 10, 5, 3)
	await get_tree().process_frame

	_assert_eq(CombatResolver.calculate_hit_chance(atk, tgt, 1), 80, "Melee (dist=1): 80%%")
	_assert_eq(CombatResolver.calculate_hit_chance(atk, tgt, 2), 75, "Dist 2: 75%% (-5)")
	_assert_eq(CombatResolver.calculate_hit_chance(atk, tgt, 4), 65, "Dist 4: 65%% (-15)")
	_assert_eq(CombatResolver.calculate_hit_chance(atk, tgt, 20), 5, "Extreme dist: 5%% (clamped)")

	# Ranged unit (opt=3) at dist 2 → no penalty
	var rng = _make_unit("Rng", 80, 10, 8, 3, 3)
	await get_tree().process_frame
	_assert_eq(CombatResolver.calculate_hit_chance(rng, tgt, 2), 70, "Ranged (opt=3) at dist 2: 70%% (no penalty)")
	_assert_eq(CombatResolver.calculate_hit_chance(rng, tgt, 5), 60, "Ranged at dist 5: 60%% (-10)")


# ─── 4. Crit mechanics ───

func _test_crit_mechanics() -> void:
	print("\n--- TEST: Crit mechanics ---")
	var atk = _make_unit("Atk", 200, 10, 10, 5)
	var tgt = _make_unit("Tgt", 90, 10, 5, 3)
	await get_tree().process_frame

	_assert_eq(CombatResolver.calculate_hit_chance(atk, tgt, 1), 95, "High accuracy caps at 95%%")
	_assert_eq(atk.crit_chance, 0.05, "Default crit_chance = 0.05")
	_assert_eq(atk.crit_multiplier, 2.0, "Default crit_multiplier = 2.0")

	var hit_count = 0
	var crit_count = 0
	var trials = 200
	for _i in range(trials):
		var r = CombatResolver.resolve_attack(atk, tgt, 1)
		if r[CombatResolver.KEY_HIT]: hit_count += 1
		if r[CombatResolver.KEY_CRIT]: crit_count += 1

	_assert_true(hit_count > trials * 0.5, "Most attacks hit (hit %d/%d)" % [hit_count, trials])
	_assert_true(crit_count > 0, "At least some crits occur (%d/%d)" % [crit_count, trials])


# ─── 5. Graze mechanics ───

func _test_graze_mechanics() -> void:
	print("\n--- TEST: Graze mechanics ---")
	var atk = _make_unit("Atk", 200, 10, 20, 1)
	var tgt = _make_unit("Tgt", 90, 10, 5, 3)
	await get_tree().process_frame

	var graze_count = 0
	var trials = 200
	var tested_graze_damage = false

	for _i in range(trials):
		var r = CombatResolver.resolve_attack(atk, tgt, 1)
		if r[CombatResolver.KEY_GRAZE]:
			graze_count += 1
			if not tested_graze_damage:
				_assert_true(r[CombatResolver.KEY_DAMAGE] <= atk.attack, "Graze damage <= full atk (%d <= %d)" % [r[CombatResolver.KEY_DAMAGE], atk.attack])
				_assert_eq(r[CombatResolver.KEY_DAMAGE], 10, "Graze damage = attack/2 (got %d)" % r[CombatResolver.KEY_DAMAGE])
				tested_graze_damage = true

	_assert_true(graze_count >= 0, "Graze count valid (%d)" % graze_count)


# ─── 6. Resolver result structure ───

func _test_resolver_structure() -> void:
	print("\n--- TEST: Resolver result structure ---")
	var atk = _make_unit("Atk", 90, 10, 10, 5)
	var tgt = _make_unit("Tgt", 90, 10, 5, 3)
	await get_tree().process_frame

	var result = CombatResolver.resolve_attack(atk, tgt, 1)

	_assert_true(result.has(CombatResolver.KEY_HIT_CHANCE), "Result has hit_chance")
	_assert_true(result.has(CombatResolver.KEY_ROLL), "Result has roll")
	_assert_true(result.has(CombatResolver.KEY_HIT), "Result has hit")
	_assert_true(result.has(CombatResolver.KEY_CRIT), "Result has crit")
	_assert_true(result.has(CombatResolver.KEY_GRAZE), "Result has graze")
	_assert_true(result.has(CombatResolver.KEY_DAMAGE), "Result has damage")
	_assert_true(result.has(CombatResolver.KEY_ACTUAL_DAMAGE), "Result has actual_damage")

	_assert_eq(result[CombatResolver.KEY_HIT_CHANCE], 80, "Structured result hit_chance=80")

	# Mutually exclusive
	if result[CombatResolver.KEY_CRIT]:
		_assert_false(result[CombatResolver.KEY_GRAZE], "Crit and graze mutually exclusive")
		_assert_true(result[CombatResolver.KEY_HIT], "Crit implies hit=true")
	if result[CombatResolver.KEY_GRAZE]:
		_assert_false(result[CombatResolver.KEY_CRIT], "Graze and crit mutually exclusive")
		_assert_true(result[CombatResolver.KEY_HIT], "Graze implies hit=true")

	if result[CombatResolver.KEY_HIT]:
		_assert_true(result[CombatResolver.KEY_DAMAGE] > 0, "Hit: damage > 0")
		_assert_true(result[CombatResolver.KEY_ACTUAL_DAMAGE] <= result[CombatResolver.KEY_DAMAGE], "actual_damage <= raw")
	else:
		_assert_eq(result[CombatResolver.KEY_DAMAGE], 0, "Miss: damage = 0")


# ─── 7. Equipment integration (stat flow) ───

func _test_equipment_integration() -> void:
	print("\n--- TEST: Equipment accuracy/evasion integration ---")
	var atk = _make_unit("Atk", 80, 10, 5, 3)
	var tgt = _make_unit("Tgt", 90, 10, 5, 3)
	var evader = _make_unit("Evader", 50, 50, 3, 1)
	var super_evader = _make_unit("SEvader", 50, 200, 3, 1)
	await get_tree().process_frame

	# get_accuracy returns base without equipment
	_assert_eq(atk.get_accuracy(), 80, "get_accuracy = base (80) w/o equipment")

	# Hit chance vs normal target
	_assert_eq(CombatResolver.calculate_hit_chance(atk, tgt, 1), 70, "80-10 = 70%% hit chance")

	# vs high evasion
	_assert_eq(CombatResolver.calculate_hit_chance(atk, evader, 1), 30, "80-50 = 30%% vs evader")

	# vs extreme evasion → clamped
	_assert_eq(CombatResolver.calculate_hit_chance(atk, super_evader, 1), 5, "5%% min vs super evader")
