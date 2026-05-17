# inventory.gd — Inventory component for units (player, shops, etc.).
# Attach as child of any Unit that needs item storage.
extends Node

## Emitted when one or more items are added.
signal item_added(item, quantity: int)
## Emitted when items are removed.
signal item_removed(item_id: String, quantity: int)
## Emitted when an item is used on a target.
signal item_used(item, user: Node)

## Maximum distinct item slots.
@export var max_slots: int = 20

var _items: Array = []        # Distinct item type resources held.
var _quantities: Dictionary = {}    # item_id -> int (count)


## Add an item (or stack). Returns true if successful.
func add_item(item, quantity: int = 1) -> bool:
	if not item or quantity <= 0:
		return false

	var existing_idx: int = _find_item_index(item.id)

	if existing_idx >= 0 and item.stackable:
		# Stack onto existing
		_quantities[item.id] = _quantities.get(item.id, 0) + quantity
		item_added.emit(_items[existing_idx], quantity)
		return true

	if _items.size() >= max_slots:
		push_warning("[Inventory] Max slots reached (%d)" % max_slots)
		return false

	# New slot
	_items.append(item)
	_quantities[item.id] = quantity
	item_added.emit(item, quantity)
	return true


## Remove a quantity of an item. Returns true if enough existed.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false

	var current: int = _quantities.get(item_id, 0)
	if current < quantity:
		return false

	if current == quantity:
		# Remove slot entirely
		_quantities.erase(item_id)
		for i in range(_items.size()):
			if _items[i].id == item_id:
				_items.remove_at(i)
				break
	else:
		_quantities[item_id] = current - quantity

	item_removed.emit(item_id, quantity)
	return true


## Use an item from inventory. Returns true if successful.
## In combat: costs `item.ap_cost` AP. Outside combat: free.
func use_item(item_id: String, user: Node) -> bool:
	if not _quantities.has(item_id) or _quantities[item_id] <= 0:
		return false

	# Find the item resource
	var item = null
	for it in _items:
		if it.id == item_id:
			item = it
			break

	if not item:
		return false

	# Check AP if in combat
	if GameState.current_mode == GameState.GameMode.TURNBASED:
		var ap = user.get("current_action_points") if "current_action_points" in user else 0
		if ap < item.ap_cost:
			push_warning("[Inventory] Not enough AP to use %s (need %d)" % [item.item_name, item.ap_cost])
			return false

	# Apply effects
	_apply_effects(item, user)

	# Deduct AP
	if GameState.current_mode == GameState.GameMode.TURNBASED:
		if "current_action_points" in user:
			user.current_action_points -= item.ap_cost
			EventBus.ap_changed.emit(user)

	# Consume the item
	remove_item(item_id, 1)
	item_used.emit(item, user)
	return true


## Check if an item is held and how many.
func has_item(item_id: String) -> bool:
	return _quantities.get(item_id, 0) > 0


func get_item_count(item_id: String) -> int:
	return _quantities.get(item_id, 0)


## Return all distinct item resources held.
func get_all_items() -> Array:
	return _items.duplicate()


## Get quantity for a specific item.
func get_quantity(item_id: String) -> int:
	return _quantities.get(item_id, 0)


## Return a formatted list: [{item, quantity}, ...]
func get_item_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for it in _items:
		result.append({
			item = it,
			quantity = _quantities.get(it.id, 0),
		})
	return result


## Remove everything.
func clear() -> void:
	_items.clear()
	_quantities.clear()


## ─── Equipment ───

## item_type → slot variable name (mirrors unit.gd _slot_map).
func _slot_name(item_type: int) -> String:
	match item_type:
		1:  return "equipped_weapon"
		2:  return "equipped_armor"
		4:  return "equipped_helmet"
		5:  return "equipped_necklace"
		6:  return "equipped_cloak"
		7:  return "equipped_belt"
		8:  return "equipped_ring1"
		9:  return "equipped_boots"
		10: return "equipped_off_hand"
		11: return "equipped_gloves"
		_:  return ""


## 인벤토리에서 아이템을 꺼내 유닛에 장비한다.
## 이전 장비가 있으면 인벤토리로 되돌린다.
## 반환값: {success: bool, message: String}
func equip_item(item_id: String, user: Node) -> Dictionary:
	if not _quantities.has(item_id) or _quantities[item_id] <= 0:
		return {success = false, message = "Item not in inventory"}

	var item = null
	for it in _items:
		if it.id == item_id:
			item = it
			break
	if not item:
		return {success = false, message = "Item resource not found"}

	# Check if equippable (any type with a slot)
	var slot_name = _slot_name(item.item_type)
	if slot_name == "":
		return {success = false, message = "Not equippable"}

	# Ranged weapon: check ammo availability
	if item.get("weapon_class") == "ranged" and item.get("ammo_type") != "":
		var needed: String = item.ammo_type
		if not _has_ammo(needed):
			return {success = false, message = "No %s in inventory" % needed}

	# Remove from inventory first
	if not remove_item(item_id, 1):
		return {success = false, message = "Failed to remove from inventory"}

	# Equip on unit
	var result = user.equip_item(item) if "equip_item" in user else {success = false}
	if result and result.get("success", false):
		# Return previous item to inventory
		var prev = result.get("previous")
		if prev:
			add_item(prev, 1)
		return {success = true, message = "Equipped %s" % item.item_name}
	else:
		# Equip failed — put item back
		add_item(item, 1)
		return {success = false, message = "Unit cannot equip"}


## 유닛에서 장비를 해제하고 인벤토리로 되돌린다.
## slot_var: "equipped_weapon", "equipped_armor", "equipped_ring1" 등
func unequip_item(slot_var: String, user: Node) -> bool:
	if not ("unequip_item" in user):
		return false
	var item = user.unequip_item(slot_var)
	if item:
		add_item(item, 1)
		return true
	return false


## ─── Internal ───

## Check if inventory has any ammo of the given type.
func _has_ammo(ammo_type: String) -> bool:
	for it in _items:
		if it.get("item_type") == 12 and it.get("ammo_type") == ammo_type:
			var qty = _quantities.get(it.id, 0)
			if qty > 0:
				return true
	return false

func _find_item_index(item_id: String) -> int:
	for i in range(_items.size()):
		if _items[i].id == item_id:
			return i
	return -1


## Apply item effects. Override in subclasses for custom behavior.
func _apply_effects(item, user: Node) -> void:
	if item.heal_amount > 0 and "take_damage" in user:
		# Heal: negative damage
		var heal: int = item.heal_amount
		var max_hp = user.get("max_hp") if "max_hp" in user else 999
		user.current_hp = min(user.current_hp + heal, max_hp)
		print("[Inventory] %s healed %d HP using %s" % [user.name, heal, item.item_name])
		# Log the heal via damage event (negative amount signals healing)
		EventBus.unit_damaged.emit(user, -heal, user)
