# zoc_controller.gd — Zone of Control system for turn-based tactical combat.
# 각 유닛은 인접 8타일을 ZOC로 통제한다.
# ZOC 안으로 진입: AP 추가 소모. ZOC 밖으로 이탈: Attack of Opportunity 유발.
class_name ZocController
extends Node

const CombatResolver = preload("res://source/features/turnbased/combat_resolver.gd")

## ZOC 반경 (Chebyshev 거리). 1 = 인접 8타일.
const DEFAULT_ZOC_RANGE: int = 1

## 해당 유닛이 통제하는 ZOC 타일 목록 반환.
static func get_zoc_tiles(unit: Node, grid_world: Node) -> Array[Vector2i]:
	var zoc_range: int = unit.get("zoc_range") if "zoc_range" in unit else DEFAULT_ZOC_RANGE
	if zoc_range <= 0:
		return []

	var unit_pos: Vector2i = grid_world.world_to_grid(unit.global_position)
	var tiles: Array[Vector2i] = []

	for dx in range(-zoc_range, zoc_range + 1):
		for dy in range(-zoc_range, zoc_range + 1):
			if dx == 0 and dy == 0:
				continue
			var tile := Vector2i(unit_pos.x + dx, unit_pos.y + dy)
			if grid_world.is_walkable(tile):
				tiles.append(tile)

	return tiles


## 적군 유닛들의 ZOC 맵 반환 ("x,y" → Array of enemy Nodes).
static func get_enemy_zoc_map(unit: Node, all_combatants: Array, grid_world: Node) -> Dictionary:
	var is_player: bool = unit.get("is_player") if "is_player" in unit else false
	var zoc_map: Dictionary = {}

	for c in all_combatants:
		if c == unit:
			continue
		var c_alive: bool = c.get("is_alive") if "is_alive" in c else true
		if not c_alive:
			continue
		var c_is_player: bool = c.get("is_player") if "is_player" in c else false
		if c_is_player == is_player:
			continue

		var tiles = get_zoc_tiles(c, grid_world)
		for tile in tiles:
			var key = str(tile.x) + "," + str(tile.y)
			if not zoc_map.has(key):
				zoc_map[key] = []
			zoc_map[key].append(c)

	return zoc_map


## 특정 타일이 적의 ZOC 안인지 확인.
static func is_in_enemy_zoc(tile: Vector2i, unit: Node, all_combatants: Array, grid_world: Node) -> bool:
	var zoc_map = get_enemy_zoc_map(unit, all_combatants, grid_world)
	return zoc_map.has(str(tile.x) + "," + str(tile.y))


## to_tile 진입 시 추가 AP 비용 반환. 적 ZOC = +1 AP (중첩 안 함).
static func get_extra_ap_cost(unit: Node, to_tile: Vector2i, all_combatants: Array, grid_world: Node) -> int:
	if is_in_enemy_zoc(to_tile, unit, all_combatants, grid_world):
		return 1
	return 0


## Attack of Opportunity 발동할 적들 반환.
## from_tile이 적 ZOC였고 to_tile이 ZOC가 아닐 때만 발동.
## from_tile을 통제했던 적 전투원 목록 반환.
static func get_attack_of_opportunity_attackers(
	moving_unit: Node, from_tile: Vector2i, to_tile: Vector2i,
	all_combatants: Array, grid_world: Node
) -> Array:
	var to_key = str(to_tile.x) + "," + str(to_tile.y)

	# to_tile이 적 ZOC면 AoO 없음 (같은 ZOC 내 이동)
	var zoc_map = get_enemy_zoc_map(moving_unit, all_combatants, grid_world)
	if zoc_map.has(to_key):
		return []

	var from_key = str(from_tile.x) + "," + str(from_tile.y)
	var attackers: Array = []
	if zoc_map.has(from_key):
		for enemy in zoc_map[from_key]:
			var e_alive: bool = enemy.get("is_alive") if "is_alive" in enemy else true
			if is_instance_valid(enemy) and e_alive:
				attackers.append(enemy)
	return attackers


## Attack of Opportunity 실행: attacker가 target에게 근접 공격 1회.
## take_damage() 내부에서 방어력을 적용하므로 raw attack 값을 넘긴다.
static func execute_attack_of_opportunity(attacker: Node, target: Node) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var a_alive: bool = attacker.get("is_alive") if "is_alive" in attacker else true
	var t_alive: bool = target.get("is_alive") if "is_alive" in target else true
	if not a_alive or not t_alive:
		return

	# CombatResolver로 통합 판정 (AoO는 항상 근접 = distance 1)
	var result = CombatResolver.resolve_attack(attacker, target, 1)
	var hit: bool = result[CombatResolver.KEY_HIT]
	var damage: int = result[CombatResolver.KEY_ACTUAL_DAMAGE]

	if hit:
		if result[CombatResolver.KEY_CRIT]:
			var atk_name: String = attacker.get("unit_name") if "unit_name" in attacker else "?"
			var tgt_name: String = target.get("unit_name") if "unit_name" in target else "?"
			print("[AoO] CRIT! %s -> %s (%d dmg)" % [atk_name, tgt_name, result[CombatResolver.KEY_DAMAGE]])
		EventBus.attack_of_opportunity.emit(attacker, target, damage, true)
	else:
		EventBus.attack_of_opportunity.emit(attacker, target, 0, false)
