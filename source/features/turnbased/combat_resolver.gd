# combat_resolver.gd — Hit/miss/crit/graze system with distance penalty.
# 통합 전투 판정 엔진. 명중/회피/치명타/빗맞힘/거리 패널티를 처리한다.
class_name CombatResolver
extends Node

## 최소/최대 명중률 (%)
const MIN_HIT_CHANCE: int = 5
const MAX_HIT_CHANCE: int = 95

## 기본 치명타 확률 (0.05 = 5%)
const BASE_CRIT_CHANCE: float = 0.05
## 치명타 데미지 배율
const BASE_CRIT_MULTIPLIER: float = 2.0

## 빗맞힘(Graze) 임계: roll이 hit_chance의 이 비율 이상이면 빗맞힘
const GRAZE_THRESHOLD: float = 0.90

## 최적 사거리 초과 시 타일당 명중률 패널티 (%)
const DISTANCE_PENALTY_PER_TILE: int = -5

## hit_chance 결과 키
const KEY_HIT_CHANCE: String = "hit_chance"
const KEY_ROLL: String = "roll"
const KEY_HIT: String = "hit"
const KEY_CRIT: String = "crit"
const KEY_GRAZE: String = "graze"
const KEY_DAMAGE: String = "damage"        # 방어력 적용 전 raw 데미지
const KEY_ACTUAL_DAMAGE: String = "actual_damage"  # 방어력 적용 후 실제 HP 변화


## 명중률 계산 (equipment + 거리 패널티 포함).
static func calculate_hit_chance(attacker: Node, target: Node, distance: int = 1) -> int:
	var atk_acc: int = attacker.get_accuracy() if attacker.has_method("get_accuracy") else 90
	var tgt_ev: int = target.get_evasion() if target.has_method("get_evasion") else 10

	# 거리 패널티
	var optimal_range: int = attacker.get("attack_range") if "attack_range" in attacker else 1
	var distance_penalty: int = 0
	if distance > optimal_range:
		distance_penalty = (distance - optimal_range) * DISTANCE_PENALTY_PER_TILE

	return clampi(atk_acc - tgt_ev + distance_penalty, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


## 공격 판정 실행. 거리 정보 포함.
## 반환 Dictionary 키: hit, crit, graze, hit_chance, roll, damage, actual_damage
static func resolve_attack(attacker: Node, target: Node, distance: int = 1) -> Dictionary:
	var hit_chance: int = calculate_hit_chance(attacker, target, distance)
	var roll: float = randf() * 100.0

	var result: Dictionary = {
		KEY_HIT_CHANCE: hit_chance,
		KEY_ROLL: roll,
		KEY_HIT: false,
		KEY_CRIT: false,
		KEY_GRAZE: false,
		KEY_DAMAGE: 0,
		KEY_ACTUAL_DAMAGE: 0,
	}

	if roll >= hit_chance:
		# 빗나감 (Miss)
		return result

	# ── 맞음! ──
	result[KEY_HIT] = true

	var base_atk: int = attacker.get_attack() if attacker.has_method("get_attack") else (attacker.get("attack") if "attack" in attacker else 10)

	# 치명타 판정 (Crit)
	var crit_chance: float = attacker.get("crit_chance") if "crit_chance" in attacker else BASE_CRIT_CHANCE
	var crit_mult: float = attacker.get("crit_multiplier") if "crit_multiplier" in attacker else BASE_CRIT_MULTIPLIER

	# crit: hit_range 상위 crit_chance 비율
	var crit_threshold: float = hit_chance * (1.0 - crit_chance)
	if roll >= crit_threshold:
		result[KEY_CRIT] = true
		var raw_damage: int = ceili(base_atk * crit_mult)
		result[KEY_DAMAGE] = raw_damage
		_apply_damage(result, target, raw_damage, attacker)
		return result

	# 빗맞힘 판정 (Graze): hit_range 상위 10% (90%~100% 구간, crit 제외)
	var graze_threshold: float = hit_chance * GRAZE_THRESHOLD
	if roll >= graze_threshold:
		result[KEY_GRAZE] = true
		var raw_damage: int = max(1, roundi(base_atk / 2))
		result[KEY_DAMAGE] = raw_damage
		_apply_damage(result, target, raw_damage, attacker)
		return result

	# 일반 명중 (Normal Hit)
	result[KEY_DAMAGE] = base_atk
	_apply_damage(result, target, base_atk, attacker)
	return result


## 데미지 적용 (방어력 차감 후 take_damage 호출).
static func _apply_damage(result: Dictionary, target: Node, raw_damage: int, attacker: Node) -> void:
	var target_def: int = target.get_defense() if target.has_method("get_defense") else (target.get("defense") if "defense" in target else 5)
	var actual: int = max(1, raw_damage - target_def)
	result[KEY_ACTUAL_DAMAGE] = actual
	target.take_damage(raw_damage, attacker)
