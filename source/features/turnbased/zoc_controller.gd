# zoc_controller.gd ??Zone of Control system for turn-based tactical combat.
# 媛??좊떅? ?몄젒 8??쇱쓣 ZOC濡??듭젣?쒕떎.
# ZOC ?덉쑝濡?吏꾩엯: AP 異붽? ?뚮え. ZOC 諛뽰쑝濡??댄깉: Attack of Opportunity ?좊컻.
extends Node
class_name ZocController

const CombatResolver = preload("res://source/features/turnbased/combat_resolver.gd")

## ZOC 諛섍꼍 (Chebyshev 嫄곕━). 1 = ?몄젒 8???
const DEFAULT_ZOC_RANGE: int = 1

## ?대떦 ?좊떅???듭젣?섎뒗 ZOC ???紐⑸줉 諛섑솚.
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


## ?곴뎔 ?좊떅?ㅼ쓽 ZOC 留?諛섑솚 ("x,y" ??Array of enemy Nodes).
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


## ?뱀젙 ??쇱씠 ?곸쓽 ZOC ?덉씤吏 ?뺤씤.
static func is_in_enemy_zoc(tile: Vector2i, unit: Node, all_combatants: Array, grid_world: Node) -> bool:
	var zoc_map = get_enemy_zoc_map(unit, all_combatants, grid_world)
	return zoc_map.has(str(tile.x) + "," + str(tile.y))


## to_tile 吏꾩엯 ??異붽? AP 鍮꾩슜 諛섑솚. ??ZOC = +1 AP (以묒꺽 ????.
static func get_extra_ap_cost(unit: Node, to_tile: Vector2i, all_combatants: Array, grid_world: Node) -> int:
	if is_in_enemy_zoc(to_tile, unit, all_combatants, grid_world):
		return 1
	return 0


## Attack of Opportunity 諛쒕룞???곷뱾 諛섑솚.
## from_tile????ZOC?怨?to_tile??ZOC媛 ?꾨땺 ?뚮쭔 諛쒕룞.
## from_tile???듭젣?덈뜕 ???꾪닾??紐⑸줉 諛섑솚.
static func get_attack_of_opportunity_attackers(
	moving_unit: Node, from_tile: Vector2i, to_tile: Vector2i,
	all_combatants: Array, grid_world: Node
) -> Array:
	var to_key = str(to_tile.x) + "," + str(to_tile.y)

	# to_tile????ZOC硫?AoO ?놁쓬 (媛숈? ZOC ???대룞)
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


## Attack of Opportunity ?ㅽ뻾: attacker媛 target?먭쾶 洹쇱젒 怨듦꺽 1??
## take_damage() ?대??먯꽌 諛⑹뼱?μ쓣 ?곸슜?섎?濡?raw attack 媛믪쓣 ?섍릿??
static func execute_attack_of_opportunity(attacker: Node, target: Node) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var a_alive: bool = attacker.get("is_alive") if "is_alive" in attacker else true
	var t_alive: bool = target.get("is_alive") if "is_alive" in target else true
	if not a_alive or not t_alive:
		return

	# CombatResolver ?듯빀 ?먯젙 (AoO = 洹쇱젒, elevation + back attack ?ы븿)
	var gw = attacker.get_node_or_null("/root/Main/GameLoop/GridWorld")
	var elv: int = 0
	var back: bool = false
	if gw and gw.has_method("get_elevation"):
		var atk_pos: Vector2i = gw.world_to_grid(attacker.global_position) if is_instance_valid(attacker) else Vector2i(0, 0)
		var tgt_pos: Vector2i = gw.world_to_grid(target.global_position) if is_instance_valid(target) else Vector2i(0, 0)
		elv = gw.get_elevation(atk_pos) - gw.get_elevation(tgt_pos)
		back = CombatResolver.is_back_attack(atk_pos, target)

	var result = CombatResolver.resolve_attack(attacker, target, 1, elv, back)
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
