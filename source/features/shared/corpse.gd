# corpse.gd — Fallen unit corpse that can be looted. 3D version.
extends Node3D

var loot_gold: int = 0
var loot_items: Array = []
var grid_position: Vector2i = Vector2i(-1, -1)
var _grid_world = null
var is_looted: bool = false


func setup(grid_world, grid_pos: Vector2i, unit_name: String, sprite_color: Color, gold: int, items: Array) -> void:
	_grid_world = grid_world
	grid_position = grid_pos
	loot_gold = gold
	loot_items = items.duplicate()
	name = "%s_Corpse" % unit_name
	add_to_group("corpses")

	global_position = _grid_world.grid_to_world(grid_pos) if _grid_world else Vector3(grid_pos.x, 0, grid_pos.y)

	# Darkened corpse box
	var corpse_color = Color(
		sprite_color.r * 0.35,
		sprite_color.g * 0.25,
		sprite_color.b * 0.25,
		0.85
	)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = corpse_color
	mat.flags_unshaded = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.15, 0.4)

	var sprite := MeshInstance3D.new()
	sprite.name = "CorpseMesh"
	sprite.mesh = box
	sprite.material_override = mat
	sprite.position = Vector3(0, 0.08, 0)
	add_child(sprite)

	# Red X marker (two crossed bars)
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(1.0, 0.2, 0.2, 0.7)
	bar_mat.flags_unshaded = true
	bar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.5, 0.03, 0.04)

	var bar1 := MeshInstance3D.new()
	bar1.mesh = bar_mesh
	bar1.material_override = bar_mat
	bar1.position = Vector3(0, 0.2, 0)
	bar1.rotation.y = PI / 4
	add_child(bar1)

	var bar2 := MeshInstance3D.new()
	bar2.mesh = bar_mesh
	bar2.material_override = bar_mat
	bar2.position = Vector3(0, 0.2, 0)
	bar2.rotation.y = -PI / 4
	add_child(bar2)

	if _grid_world:
		_grid_world.set_occupied(grid_pos, self)

	var item_names = ""
	for it in loot_items:
		if it and "item_name" in it:
			if item_names != "":
				item_names += ", "
			item_names += it.item_name
	print("[Corpse] %s fell at %s (gold=%d, items=[%s])" % [unit_name, str(grid_pos), loot_gold, item_names])


func loot(player_unit: Node, player_inventory: Node) -> bool:
	if is_looted:
		return false
	if not is_instance_valid(player_unit) or not is_instance_valid(player_inventory):
		return false

	var any_loot: bool = false

	if loot_gold > 0 and "gold" in player_unit:
		player_unit.gold += loot_gold
		EventBus.gold_changed.emit(player_unit, loot_gold)
		var event_log = _get_event_log()
		if event_log and event_log.has_method("add_entry"):
			event_log.add_entry("Looted %d gold from %s" % [loot_gold, name], Color(1.0, 0.8, 0.0))
		print("[Corpse] Looted %d gold from %s" % [loot_gold, name])
		loot_gold = 0
		any_loot = true

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
		_dismiss()

	return any_loot


func _dismiss() -> void:
	is_looted = true
	if _grid_world and grid_position != Vector2i(-1, -1):
		_grid_world.set_occupied(grid_position, null)
	remove_from_group("corpses")
	queue_free()


func _get_event_log():
	return get_node_or_null("/root/Main/HUD/EventLog")
