# unit.gd — Base class for all game entities (player, enemies, NPCs).
# Shared between real-time and turn-based modes.
class_name Unit
extends CharacterBody2D

## Core stats
@export var unit_name: String = "Unit"
@export var max_hp: int = 100
@export var speed: int = 10       # Initiative for turn-based, movement for real-time
@export var attack: int = 10
@export var defense: int = 5
@export var is_player: bool = false  # Stoneshard: player vs NPC distinction
@export var attack_range: int = 1    # 1=melee, 2+=ranged

## Runtime state
var current_hp: int = 100
var current_action_points: int = 3
var max_action_points: int = 3
var is_alive: bool = true
var status_effects: Array = []

## Equipment slots (references to Item resources, null = empty)
var equipped_weapon = null   # WEAPON → right_hand
var equipped_armor = null    # ARMOR → body
var equipped_helmet = null   # HELMET → head
var equipped_necklace = null # NECKLACE → necklace
var equipped_cloak = null    # CLOAK → cloak
var equipped_belt = null     # BELT → belt
var equipped_ring1 = null    # RING → ring slot 1
var equipped_ring2 = null    # RING → ring slot 2
var equipped_boots = null    # BOOTS → boots
var equipped_gloves = null   # GLOVE → gloves
var equipped_off_hand = null # OFF_HAND → left_hand

## Movement component (optional)
var movement = null

## Gold (player wallet)
var gold: int = 0

## Drops (enemies)
@export var gold_drop: int = 0    # Gold dropped on death
@export var item_drops: Array = []  # [{item=Resource, chance=0.0-1.0}, ...]

## Corpse visual tint (set by spawner). Gray default.
@export var corpse_color: Color = Color(0.4, 0.35, 0.35)


func _ready() -> void:
	current_hp = max_hp
	movement = get_node_or_null("UnitMovement")


func reset_actions() -> void:
	current_action_points = max_action_points


## 장비를 포함한 최종 공격력 반환 (weapon + off_hand).
func get_attack() -> int:
	var bonus: int = 0
	if equipped_weapon and "damage_bonus" in equipped_weapon:
		bonus += equipped_weapon.damage_bonus
	if equipped_off_hand and "damage_bonus" in equipped_off_hand:
		bonus += equipped_off_hand.damage_bonus
	return attack + bonus


## 장비를 포함한 최종 방어력 반환 (모든 방어구 합산).
func get_defense() -> int:
	var bonus: int = 0
	for slot_item in [equipped_armor, equipped_helmet, equipped_necklace, equipped_cloak, equipped_belt, equipped_boots, equipped_gloves, equipped_off_hand, equipped_ring1, equipped_ring2]:
		if slot_item and "defense_bonus" in slot_item:
			bonus += slot_item.defense_bonus
	return defense + bonus


## item_type → slot variable name mapping.
var _slot_map: Dictionary = {
	1: "equipped_weapon",      # WEAPON
	2: "equipped_armor",       # ARMOR
	4: "equipped_helmet",      # HELMET
	5: "equipped_necklace",    # NECKLACE
	6: "equipped_cloak",       # CLOAK
	7: "equipped_belt",        # BELT
	9: "equipped_boots",       # BOOTS
	10: "equipped_off_hand",   # OFF_HAND
	11: "equipped_gloves",     # GLOVE
}


## 아이템을 장비한다. item_type에 따라 적절한 슬롯에 설정.
## ring(8)은 ring1 → ring2 순서로 채운다.
## 이전에 장비한 아이템이 있으면 반환하고 새 아이템으로 교체.
## 반환값: {previous: 이전 아이템(or null), success: true, slot: 사용된 슬롯명}
func equip_item(item) -> Dictionary:
	if not item or not ("item_type" in item):
		return {previous = null, success = false, slot = ""}

	var slot_var: String = ""
	var item_type: int = item.item_type

	if item_type == 8:  # RING: try ring1 first, then ring2
		if equipped_ring1 == null:
			slot_var = "equipped_ring1"
		elif equipped_ring2 == null:
			slot_var = "equipped_ring2"
		else:
			slot_var = "equipped_ring1"  # both full, overwrite ring1
	else:
		slot_var = _slot_map.get(item_type, "")

	if slot_var == "":
		return {previous = null, success = false, slot = ""}

	var prev = get(slot_var)
	set(slot_var, item)

	print("[Unit] Equipped %s -> %s (atk=%d, def=%d)" % [item.item_name, slot_var, get_attack(), get_defense()])
	return {previous = prev, success = true, slot = slot_var}


## 장비를 해제한다. slot_var: "equipped_weapon", "equipped_armor", "equipped_ring1" 등.
## 반환값: 해제된 아이템 (없으면 null).
func unequip_item(slot_var: String):
	var item = get(slot_var) if slot_var in self else null
	if item != null:
		set(slot_var, null)
		print("[Unit] Unequipped %s from %s" % [item.item_name, slot_var])
	return item


## 장비된 모든 아이템을 {slot_var: item} Dictionary로 반환 (UI용).
func get_all_equipped() -> Dictionary:
	var result: Dictionary = {}
	for s in ["equipped_weapon", "equipped_armor", "equipped_helmet", "equipped_necklace", "equipped_cloak", "equipped_belt", "equipped_ring1", "equipped_ring2", "equipped_boots", "equipped_gloves", "equipped_off_hand"]:
		var it = get(s)
		if it != null:
			result[s] = it
	return result


func take_damage(amount: int, source: Node = null) -> void:
	var actual = max(1, amount - get_defense())
	current_hp = max(0, current_hp - actual)
	EventBus.unit_damaged.emit(self, actual, source)

	if current_hp <= 0:
		die()


func die() -> void:
	is_alive = false
	if not movement:
		EventBus.unit_destroyed.emit(self)
		queue_free()
		return

	movement.stop_moving()
	var gw = movement.get_grid_world()

	# Collect drops that would have spawned
	var drop_items: Array = []
	for entry in item_drops:
		var drop_item = entry.get("item")
		var chance = entry.get("chance", 1.0)
		if drop_item and randf() <= chance:
			drop_items.append(drop_item)

	# Clear grid occupancy (corpse will re-set it)
	if gw:
		var gp: Vector2i = gw.world_to_grid(global_position)
		gw.set_occupied(gp, null)

	# Spawn lootable corpse
	_spawn_corpse(gw, gold_drop, drop_items)

	# Legacy: spawn MapItem drops for backward compatibility (empty since we pass to corpse)
	gold_drop = 0
	item_drops = []

	EventBus.unit_destroyed.emit(self)
	queue_free()


## Create a lootable corpse at this unit's position.
func _spawn_corpse(grid_world, gold: int, items: Array) -> void:
	if not grid_world:
		return
	var gp: Vector2i = grid_world.world_to_grid(global_position)
	var corpse = load("res://source/features/shared/corpse.gd").new()
	corpse.setup(grid_world, gp, unit_name, corpse_color, gold, items)
	get_tree().current_scene.add_child(corpse)


## 사망 시 금화와 아이템을 MapItem으로 드랍한다.
func _drop_loot() -> void:
	if gold_drop <= 0 and item_drops.is_empty():
		return

	var grid_world = movement.get_grid_world() if movement else null
	if not grid_world:
		return
	var gp: Vector2i = grid_world.world_to_grid(global_position)

	# Gold drop
	if gold_drop > 0:
		var gold_item = load("res://source/data/items/resources/gold_coin.tres")
		if gold_item:
			_spawn_drop(gold_item, gp)

	# Item drops (roll chance)
	for entry in item_drops:
		var drop_item = entry.get("item")
		var chance = entry.get("chance", 1.0)
		if drop_item and randf() <= chance:
			# Offset each drop slightly so they don't stack visually
			var offset_gp = gp + Vector2i(
				item_drops.find(entry) % 3 - 1,
				(item_drops.find(entry) / 3) % 3 - 1
			)
			_spawn_drop(drop_item, offset_gp)


func _spawn_drop(item_res, grid_pos: Vector2i) -> void:
	var map_item = load("res://source/features/realtime/map_item.gd").new()
	map_item.setup(item_res, grid_pos)
	map_item.global_position = Vector2(grid_pos.x * 64 + 32, grid_pos.y * 64 + 32)
	get_tree().current_scene.add_child(map_item)
