# map_item.gd — An item sitting on the game map, ready to be picked up.
# Place as child of GameLoop or GridWorld. Visually shows a colored square + label.
class_name MapItem
extends Node2D

## The item resource this map object represents.
var item = null
## Grid position of this item on the world.
var grid_position: Vector2i = Vector2i.ZERO
## Reference to the sprite for visual feedback.
var _sprite: Sprite2D = null


func _ready() -> void:
	add_to_group("map_items")


## Initialize with an item resource and grid position.
func setup(item_resource, grid_pos: Vector2i) -> void:
	item = item_resource
	grid_position = grid_pos

	# ── Visual: colored square as placeholder icon ──
	_sprite = Sprite2D.new()
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(_pick_color_for_item(item))
	var tex := ImageTexture.create_from_image(img)
	_sprite.texture = tex
	_sprite.z_index = 0
	add_child(_sprite)

	# ── Label: item name above ──
	var label := Label.new()
	label.text = item.item_name if item else "?"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	label.position = Vector2(-40, -20)
	label.size = Vector2(100, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)


## Flash or scale animation to show it was picked up.
func animate_pickup() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.chain()
	tween.tween_callback(queue_free)


func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	# Try to find GridWorld for coordinate conversion
	var grid = get_node_or_null("/root/Main/GameLoop/GridWorld")
	if grid and grid.has_method("grid_to_world"):
		return grid.grid_to_world(grid_pos)
	return Vector2(grid_pos.x * 32 + 16, grid_pos.y * 32 + 16)


## Pick a visual color based on item type.
func _pick_color_for_item(it) -> Color:
	if not it:
		return Color(0.5, 0.5, 0.5)
	match it.item_type:
		0:  return Color(0.2, 0.8, 0.3)  # CONSUMABLE → green
		1:  return Color(0.9, 0.3, 0.3)  # WEAPON → red
		2:  return Color(0.3, 0.3, 0.9)  # ARMOR → blue
		3:  return Color(0.9, 0.8, 0.2)  # KEY_ITEM → gold
		4:  return Color(1.0, 0.8, 0.0)  # GOLD → bright yellow
		_:  return Color(0.5, 0.5, 0.5)
