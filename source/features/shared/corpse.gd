# corpse.gd — Fallen unit corpse that can be looted.
# Spawned by unit.die(). Blocks grid tile until looted.
extends Node2D

## Gold carried by this corpse.
var loot_gold: int = 0
## Array of Item resources carried by this corpse.
var loot_items: Array = []
## Grid position of this corpse.
var grid_position: Vector2i = Vector2i(-1, -1)
## Reference to GridWorld for occupancy management.
var _grid_world = null
## Has this corpse been fully looted?
var is_looted: bool = false


## Initialize the corpse with unit data.
func setup(grid_world, grid_pos: Vector2i, unit_name: String, sprite_color: Color, gold: int, items: Array) -> void:
	_grid_world = grid_world
	grid_position = grid_pos
	loot_gold = gold
	loot_items = items.duplicate()
	name = "%s_Corpse" % unit_name
	add_to_group("corpses")

	# Position
	global_position = _grid_world.grid_to_world(grid_pos) if _grid_world else Vector2(grid_pos.x * 64 + 32, grid_pos.y * 64 + 32)

	# Darkened corpse sprite (same unit color but desaturated + dark)
	var sprite := Sprite2D.new()
	sprite.name = "CorpseSprite"
	sprite.z_index = -1
	sprite.z_as_relative = false
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var corpse_color = Color(
		sprite_color.r * 0.35,
		sprite_color.g * 0.25,
		sprite_color.b * 0.25,
		0.85
	)
	img.fill(corpse_color)
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

	# "X" marker made of two thin rects — a simple fallback without font rendering
	var cross := Node2D.new()
	var bar1 := ColorRect.new()
	bar1.color = Color(1.0, 0.2, 0.2, 0.6)
	bar1.size = Vector2(18, 3)
	bar1.position = Vector2(-9, -1.5)
	bar1.rotation = 0.785  # 45 degrees
	cross.add_child(bar1)
	var bar2 := ColorRect.new()
	bar2.color = Color(1.0, 0.2, 0.2, 0.6)
	bar2.size = Vector2(18, 3)
	bar2.position = Vector2(-9, -1.5)
	bar2.rotation = -0.785  # -45 degrees
	cross.add_child(bar2)
	cross.z_index = 1
	cross.z_as_relative = false
	add_child(cross)

	# Set grid occupancy so this tile blocks movement
	if _grid_world:
		_grid_world.set_occupied(grid_pos, self)

	# Print summary
	var item_names = ""
	for it in loot_items:
		if it and "item_name" in it:
			if item_names != "":
				item_names += ", "
			item_names += it.item_name
	print("[Corpse] %s fell at %s (gold=%d, items=[%s])" % [unit_name, str(grid_pos), loot_gold, item_names])


## Player presses E near this corpse: transfer all loot to player.
## Returns true if anything was looted.
func loot(player_unit: Node, player_inventory: Node) -> bool:
	if is_looted:
		return false
	if not is_instance_valid(player_unit) or not is_instance_valid(player_inventory):
		return false

	var any_loot: bool = false

	# Gold
	if loot_gold > 0 and "gold" in player_unit:
		player_unit.gold += loot_gold
		EventBus.gold_changed.emit(player_unit, loot_gold)
		var event_log = _get_event_log()
		if event_log and event_log.has_method("add_entry"):
			event_log.add_entry("Looted %d gold from %s" % [loot_gold, name], Color(1.0, 0.8, 0.0))
		print("[Corpse] Looted %d gold from %s" % [loot_gold, name])
		loot_gold = 0
		any_loot = true

	# Items
	for it in loot_items:
		if it and player_inventory.has_method("add_item") and player_inventory.add_item(it):
			var item_name = it.get("item_name", "Unknown")
			var event_log = _get_event_log()
			if event_log and event_log.has_method("add_entry"):
				event_log.add_entry("Looted %s from %s" % [item_name, name], Color(0.4, 1.0, 0.4))
			print("[Corpse] Looted %s from %s" % [item_name, name])
			any_loot = true

	loot_items.clear()

	if any_loot:
		_dismiss()
	else:
		# Nothing to loot — still dismiss
		_dismiss()

	return any_loot


## Corpse has been looted: clear grid occupancy and remove.
func _dismiss() -> void:
	is_looted = true
	# Clear grid occupancy
	if _grid_world and grid_position != Vector2i(-1, -1):
		_grid_world.set_occupied(grid_position, null)
	remove_from_group("corpses")
	queue_free()


func _get_event_log():
	return get_node_or_null("/root/Main/HUD/EventLog")
