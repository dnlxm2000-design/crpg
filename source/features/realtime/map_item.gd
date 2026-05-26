# map_item.gd ??An item sitting on the game map, ready to be picked up. 3D version.
extends Node3D
class_name MapItem

## The item resource this map object represents.
var item = null
## Grid position of this item on the world.
var grid_position: Vector2i = Vector2i.ZERO
## Reference to the mesh for visual feedback.
var _mesh: MeshInstance3D = null


func _ready() -> void:
	add_to_group("map_items")


func setup(item_resource, grid_pos: Vector2i) -> void:
	item = item_resource
	grid_position = grid_pos

	# ?? Visual: colored box as placeholder icon ??
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _pick_color_for_item(item)
	mat.flags_unshaded = true

	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)

	_mesh = MeshInstance3D.new()
	_mesh.name = "MapItemMesh"
	_mesh.mesh = box
	_mesh.material_override = mat
	_mesh.position = Vector3(0, 0.2, 0)
	add_child(_mesh)

	# ?? Label: 3D label above item ??
	var label := Label3D.new()
	label.text = item.item_name if item else "?"
	label.font_size = 24
	label.modulate = Color(1.0, 1.0, 0.8)
	label.position = Vector3(0, 0.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


## Flash or scale animation to show it was picked up.
func animate_pickup() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.15)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.chain()
	tween.tween_callback(queue_free)


## Pick a visual color based on item type.
func _pick_color_for_item(it) -> Color:
	if not it:
		return Color(0.5, 0.5, 0.5)
	match it.item_type:
		0:  return Color(0.2, 0.8, 0.3)
		1:  return Color(0.9, 0.3, 0.3)
		2:  return Color(0.3, 0.3, 0.9)
		3:  return Color(0.9, 0.8, 0.2)
		4:  return Color(1.0, 0.8, 0.0)
		_:  return Color(0.5, 0.5, 0.5)
