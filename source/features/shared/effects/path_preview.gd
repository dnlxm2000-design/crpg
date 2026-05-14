# path_preview.gd — Shows frozen path preview on first mouse click.
# Second click confirms movement. No clicks → nothing shown.
extends Node2D

var _player: Node = null
var _grid_world: Node = null
var _path: Array[Vector2i] = []


func setup(grid_world: Node, player_node: Node) -> void:
	_grid_world = grid_world
	_player = player_node


## Compute and display path from player to target grid position.
func preview_to(target_grid: Vector2i) -> void:
	if not _grid_world or not _player or not is_instance_valid(_player):
		return
	var from_grid: Vector2i = _grid_world.world_to_grid(_player.global_position)
	if from_grid == target_grid:
		_path.clear()
		visible = false
		queue_redraw()
		return
	_path = _grid_world.find_path_grid(from_grid, target_grid)
	visible = not _path.is_empty()
	queue_redraw()


## Hide the preview path.
func clear() -> void:
	_path.clear()
	visible = false
	queue_redraw()


func _draw() -> void:
	if _path.is_empty() or not _grid_world:
		return

	var tile_size: int = _grid_world.tile_size if "tile_size" in _grid_world else 32

	# Draw semi-transparent dots at each step
	for point in _path:
		var world_pos: Vector2 = _grid_world.grid_to_world(point)
		draw_circle(world_pos, 5, Color(1.0, 1.0, 1.0, 0.5))

	# Draw connecting line from player through all path points
	var pts: PackedVector2Array = []
	pts.append(_player.global_position)
	for point in _path:
		pts.append(_grid_world.grid_to_world(point))

	if pts.size() >= 2:
		for i in range(pts.size() - 1):
			draw_line(pts[i], pts[i + 1], Color(1.0, 1.0, 1.0, 0.35), 2.0)

	# Highlight destination tile
	var dest: Vector2 = _grid_world.grid_to_world(_path[_path.size() - 1])
	var half: float = tile_size / 2.0
	var rect := Rect2(dest.x - half, dest.y - half, tile_size, tile_size)
	draw_rect(rect, Color(1.0, 1.0, 0.3, 0.25), true)
	draw_rect(rect, Color(1.0, 1.0, 0.3, 0.6), false, 1.5)
