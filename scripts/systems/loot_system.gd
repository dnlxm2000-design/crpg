# LootSystem - Item drop and loot distribution system

extends Node

var base_items_data: Dictionary = {}
var world_sim: Node = null

const GOLD_MULTIPLIER = 1.0
const ITEM_DROP_CHANCE = 0.5

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var rarity_multipliers = {
	ItemRarity.COMMON: 1.0,
	ItemRarity.UNCOMMON: 0.5,
	ItemRarity.RARE: 0.25,
	ItemRarity.EPIC: 0.1,
	ItemRarity.LEGENDARY: 0.05
}

func _ready():
	_load_data()

func _load_data():
	var file = FileAccess.open("res://data/items.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and json is Dictionary:
			base_items_data = json
		file.close()

func set_world_simulation(ref: Node):
	world_sim = ref

func calculate_drop(monster_id: String, cr: String) -> Dictionary:
	var drop_result = {
		"gold": 0,
		"items": [],
		"xp": _calculate_xp(cr)
	}
	
	var gold_amount = _calculate_gold(cr)
	drop_result.gold = gold_amount
	
	if randf() < ITEM_DROP_CHANCE:
		drop_result.items = _calculate_item_drops(cr)
	
	return drop_result

func _calculate_gold(cr: String) -> int:
	var cr_rangemap = {
		"0": "1d4",
		"1/8": "1d6",
		"1/4": "1d10",
		"1/2": "2d10",
		"1": "3d10",
		"2": "4d10",
		"3": "5d10",
		"4": "6d10",
		"5": "7d10",
		"6": "8d10",
		"7": "9d10",
		"8": "10d10",
		"9": "11d10",
		"10": "12d10"
	}
	
	var dice_str = cr_rangemap.get(cr, "1d10")
	return _roll_dice(dice_str)

func _calculate_xp(cr: String) -> int:
	var xp_table = {
		"0": 10,
		"1/8": 25,
		"1/4": 50,
		"1/2": 100,
		"1": 200,
		"2": 450,
		"3": 700,
		"4": 1100,
		"5": 1800,
		"6": 2300,
		"7": 2900,
		"8": 3900,
		"9": 5000,
		"10": 6200
	}
	
	return xp_table.get(cr, 50)

func _calculate_item_drops(cr: String) -> Array:
	var item_pool: Array = []
	
	var rarity = _determine_rarity(cr)
	
	var fog_bonus = 1.0
	var grid_bonus = 1.0
	
	if world_sim:
		fog_bonus = 1.0 + (world_sim.fog_density * 0.3)
		grid_bonus = 1.0 + (world_sim.grid_resonance * 0.3)
	
	if randf() < (rarity_multipliers[rarity] * fog_bonus):
		item_pool.append(_create_item_by_rarity(rarity))
	
	return item_pool

func _determine_rarity(cr: String) -> int:
	var cr_num = _cr_to_number(cr)
	
	if cr_num >= 7:
		return ItemRarity.LEGENDARY
	elif cr_num >= 5:
		return ItemRarity.EPIC
	elif cr_num >= 3:
		return ItemRarity.RARE
	elif cr_num >= 1:
		return ItemRarity.UNCOMMON
	else:
		return ItemRarity.COMMON

func _cr_to_number(cr: String) -> float:
	var parts = cr.split("/")
	if parts.size() == 2:
		return float(parts[0]) / float(parts[1])
	else:
		return float(cr)

func _create_item_by_rarity(rarity: int) -> Dictionary:
	var item_templates = {
		ItemRarity.COMMON: [
			{"id": "potion_healing", "name": "치유 물약", "rarity": "common"},
			{"id": "torch", "name": "횃불", "rarity": "common"},
			{"id": "rope", "name": "로프", "rarity": "common"}
		],
		ItemRarity.UNCOMMON: [
			{"id": "potion_greater_healing", "name": "강력 치유 물약", "rarity": "uncommon"},
			{"id": "antidote", "name": "해독제", "rarity": "uncommon"},
			{"id": "holy_water", "name": "성수", "rarity": "uncommon"}
		],
		ItemRarity.RARE: [
			{"id": "scroll_fireball", "name": "화염구 마법_scroll", "rarity": "rare"},
			{"id": "cloak_protection", "name": "보호 망토", "rarity": "rare"},
			{"id": "ring_mail", "name": "반지 갑옷", "rarity": "rare"}
		],
		ItemRarity.EPIC: [
			{"id": "staff_power", "name": "힘의 지杖", "rarity": "epic"},
			{"id": "plate_armor", "name": "판금 갑옷", "rarity": "epic"}
		],
		ItemRarity.LEGENDARY: [
			{"id": "artifact", "name": "유물", "rarity": "legendary"}
		]
	}
	
	var template_list = item_templates.get(rarity, [])
	if template_list.is_empty():
		return {}
	
	return template_list[randi() % template_list.size()]

func _roll_dice(dice_str: String) -> int:
	var parts = dice_str.split("d")
	if parts.size() != 2:
		return 0
	
	var dice_count = parts[0].to_int()
	var dice_sides = parts[1].to_int()
	
	var total = 0
	for i in range(dice_count):
		total += randi_range(1, dice_sides)
	
	return total

func get_item_from_id(item_id: String) -> Dictionary:
	var categories = base_items_data.get("categories", {})
	
	for category in categories.keys():
		var items_list = categories[category]
		for item in items_list:
			if item.get("id") == item_id:
				return item
	
	return {}
