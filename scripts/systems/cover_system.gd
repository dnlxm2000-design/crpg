# CoverSystem - Cover and flanking mechanics

extends Node

enum CoverType { NONE, LOW, HIGH, FULL }

var cover_map: Dictionary = {}

func _ready():
	add_to_group("combat_systems")

func calculate_cover(attacker_pos: Vector2i, defender_pos: Vector2i, obstacles: Array) -> CoverType:
	var dx = defender_pos.x - attacker_pos.x
	var dy = defender_pos.y - attacker_pos.y
	
	if abs(dx) <= 1 and abs(dy) <= 1:
		return CoverType.NONE
	
	var dir_x = sign(dx)
	var dir_y = sign(dy)
	var check_positions: Array = []
	
	if dir_x != 0 and dir_y != 0:
		check_positions.append(defender_pos + Vector2i(dir_x, 0))
		check_positions.append(defender_pos + Vector2i(0, dir_y))
	elif dir_x != 0:
		check_positions.append(defender_pos + Vector2i(dir_x, 0))
	elif dir_y != 0:
		check_positions.append(defender_pos + Vector2i(0, dir_y))
	
	var low_cover_count = 0
	var high_cover_count = 0
	
	for pos in check_positions:
		if obstacles.has(pos):
			var tile_type = obstacles[pos]
			if tile_type == 4:
				low_cover_count += 1
			elif tile_type == 0:
				high_cover_count += 1
	
	if high_cover_count >= 2:
		return CoverType.FULL
	elif high_cover_count >= 1 or low_cover_count >= 2:
		return CoverType.HIGH
	elif low_cover_count >= 1:
		return CoverType.LOW
	
	return CoverType.NONE

func get_cover_bonus(cover_type: CoverType) -> Dictionary:
	match cover_type:
		CoverType.NONE:
			return {"ac": 0, "saving_throw": 0}
		CoverType.LOW:
			return {"ac": 2, "saving_throw": 0}
		CoverType.HIGH:
			return {"ac": 5, "saving_throw": 2}
		CoverType.FULL:
			return {"ac": 8, "saving_throw": 5}
	return {"ac": 0, "saving_throw": 0}

func is_flanking(attacker: Node, defender: Node) -> bool:
	var dx = abs(attacker.grid_position.x - defender.grid_position.x)
	var dy = abs(attacker.grid_position.y - defender.grid_position.y)
	
	if dx <= 1 and dy <= 1:
		return false
	
	var adjacent_allies = 0
	var all_nodes = get_tree().get_nodes_in_group("characters")
	
	for node in all_nodes:
		if node.has_method("get_ability_modifier"):
			if node != attacker and node != defender:
				if node.is_in_group("enemies") == attacker.is_in_group("enemies"):
					var dist_x = abs(node.grid_position.x - defender.grid_position.x)
					var dist_y = abs(node.grid_position.y - defender.grid_position.y)
					if dist_x <= 1 and dist_y <= 1:
						adjacent_allies += 1
	
	return adjacent_allies >= 1

func get_flanking_bonus() -> int:
	return 2

func apply_cover_defense(defender: Node, attacker: Node) -> Dictionary:
	var cover = calculate_cover(attacker.grid_position, defender.grid_position, cover_map)
	var cover_bonus = get_cover_bonus(cover)
	
	var is_flanking_attack = is_flanking(attacker, defender)
	var flanking_bonus = get_flanking_bonus() if is_flanking_attack else 0
	
	return {
		"cover_type": cover,
		"ac_bonus": cover_bonus.ac + flanking_bonus,
		"saving_bonus": cover_bonus.saving_throw,
		"is_flanking": is_flanking_attack
	}