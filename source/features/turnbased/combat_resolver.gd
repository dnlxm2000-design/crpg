# combat_resolver.gd — Hit/miss/crit/graze system with elevation & back attack.
# 통합 전투 판정 엔진. 고도 우세, 후방 공격, 거리 패널티를 처리한다.
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

## 고도 우세 시 명중률 보너스 (%)
const ELEVATION_ADVANTAGE_BONUS: int = 10
## 고도 열세 시 명중률 패널티 (%)
const ELEVATION_DISADVANTAGE_PENALTY: int = -10

## 후방 공격 명중률 보너스 (%)
const BACK_ATTACK_ACCURACY_BONUS: int = 15
## 후방 공격 데미지 배율
const BACK_ATTACK_DAMAGE_MULTIPLIER: float = 1.5

## 결과 키
const KEY_HIT_CHANCE: String = "hit_chance"
const KEY_ROLL: String = "roll"
const KEY_HIT: String = "hit"
const KEY_CRIT: String = "crit"
const KEY_GRAZE: String = "graze"
const KEY_DAMAGE: String = "damage"
const KEY_ACTUAL_DAMAGE: String = "actual_damage"
const KEY_BACK_ATTACK: String = "back_attack"
const KEY_ELEVATION_DIFF: String = "elevation_diff"
const KEY_BASE_ATK: String = "base_atk"  # 디버깅용 순수 공격력

## 명중률 계산 (equipment + 거리 + 고도 + 후방 포함).
static func calculate_hit_chance(
	attacker: Node, target: Node, distance: int = 1,
	elevation_diff: int = 0, back_attack: bool = false
) -> int:
	var atk_acc: int = attacker.get_accuracy() if attacker.has_method("get_accuracy") else 90
	var tgt_ev: int = target.get_evasion() if target.has_method("get_evasion") else 10

	# 거리 패널티
	var optimal_range: int = attacker.get("attack_range") if "attack_range" in attacker else 1
	var distance_penalty: int = 0
	if distance > optimal_range:
		distance_penalty = (distance - optimal_range) * DISTANCE_PENALTY_PER_TILE

	# 고도 보너스/패널티
	var elevation_bonus: int = 0
	if elevation_diff > 0:
		elevation_bonus = ELEVATION_ADVANTAGE_BONUS
	elif elevation_diff < 0:
		elevation_bonus = ELEVATION_DISADVANTAGE_PENALTY

	# 후방 공격 보너스
	var back_bonus: int = BACK_ATTACK_ACCURACY_BONUS if back_attack else 0

	return clampi(atk_acc - tgt_ev + distance_penalty + elevation_bonus + back_bonus,
		MIN_HIT_CHANCE, MAX_HIT_CHANCE)


## 공격 판정 실행.
## Parameters:
##   elevation_diff: 공격자 고도 - 방어자 고도 (양수 = 공격자가 높음)
##   back_attack: 방어자 뒷면에서 공격했는가?
static func resolve_attack(
	attacker: Node, target: Node, distance: int = 1,
	elevation_diff: int = 0, back_attack: bool = false
) -> Dictionary:
	var hit_chance: int = calculate_hit_chance(attacker, target, distance, elevation_diff, back_attack)
	var roll: float = randf() * 100.0

	var base_atk: int = attacker.get_attack() if attacker.has_method("get_attack") else \
		(attacker.get("attack") if "attack" in attacker else 10)

	var result: Dictionary = {
		KEY_HIT_CHANCE: hit_chance,
		KEY_ROLL: roll,
		KEY_HIT: false,
		KEY_CRIT: false,
		KEY_GRAZE: false,
		KEY_DAMAGE: 0,
		KEY_ACTUAL_DAMAGE: 0,
		KEY_BACK_ATTACK: back_attack,
		KEY_ELEVATION_DIFF: elevation_diff,
		KEY_BASE_ATK: base_atk,
	}

	if roll >= hit_chance:
		return result

	# ── 맞음! ──
	result[KEY_HIT] = true

	# 후방 공격 데미지 배율
	var dmg_mult: float = BACK_ATTACK_DAMAGE_MULTIPLIER if back_attack else 1.0

	# 치명타 판정
	var crit_chance: float = attacker.get("crit_chance") if "crit_chance" in attacker else BASE_CRIT_CHANCE
	var crit_mult: float = attacker.get("crit_multiplier") if "crit_multiplier" in attacker else BASE_CRIT_MULTIPLIER

	var crit_threshold: float = hit_chance * (1.0 - crit_chance)
	if roll >= crit_threshold:
		result[KEY_CRIT] = true
		var raw_damage: int = ceili(base_atk * crit_mult * dmg_mult)
		result[KEY_DAMAGE] = raw_damage
		_apply_damage(result, target, raw_damage, attacker)
		return result

	# 빗맞힘
	var graze_threshold: float = hit_chance * GRAZE_THRESHOLD
	if roll >= graze_threshold:
		result[KEY_GRAZE] = true
		var raw_damage: int = max(1, roundi(base_atk / 2 * dmg_mult))
		result[KEY_DAMAGE] = raw_damage
		_apply_damage(result, target, raw_damage, attacker)
		return result

	# 일반 명중
	var raw_damage: int = ceili(base_atk * dmg_mult)
	result[KEY_DAMAGE] = raw_damage
	_apply_damage(result, target, raw_damage, attacker)
	return result


## 후방 공격 여부 판정.
## target의 facing_direction과 attack_dir이 같은 방향이면 후방 공격.
static func is_back_attack(attacker_pos: Vector2i, target: Node) -> bool:
	var facing: Vector2 = target.get("facing_direction") if "facing_direction" in target else Vector2.DOWN
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN
	# 공격 방향 = 타겟 위치 - 공격자 위치
	var target_pos: Vector2i
	var grid_world = _find_grid_world(target)
	if grid_world:
		target_pos = grid_world.world_to_grid(target.global_position)
	else:
		return false

	var attack_dir: Vector2i = target_pos - attacker_pos
	if attack_dir == Vector2i.ZERO:
		return false

	# facing_direction은 정규화된 Vector2 (예: (0, 1) = 아래)
	# attack_dir을 정규화
	var ad_norm: Vector2 = Vector2(attack_dir).normalized()
	var dot: float = ad_norm.dot(facing.normalized())
	# dot > 0.5면 같은 방향 (후방)
	return dot > 0.5


static func _find_grid_world(from: Node) -> Node:
	return from.get_node_or_null("/root/Main/GameLoop/GridWorld")


## 데미지 적용 (방어력 차감 후 take_damage 호출).
static func _apply_damage(result: Dictionary, target: Node, raw_damage: int, attacker: Node) -> void:
	var target_def: int = target.get_defense() if target.has_method("get_defense") else (target.get("defense") if "defense" in target else 5)
	var actual: int = max(1, raw_damage - target_def)
	result[KEY_ACTUAL_DAMAGE] = actual
	target.take_damage(raw_damage, attacker)
