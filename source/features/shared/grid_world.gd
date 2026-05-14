# grid_world.gd — Tile-based grid with A* pathfinding (Stoneshard-inspired).
# Converts between world coordinates and grid coordinates.
class_name GridWorld
extends Node

## 한 타일의 픽셀 크기 (32×32).
const CELL_SIZE: int = 32
## Size of each tile in pixels (see CELL_SIZE for the constant).
@export var tile_size: int = CELL_SIZE
## Grid dimensions (tiles).
@export var grid_width: int = 64
@export var grid_height: int = 64
## Enable 8-directional movement (diagonals).
@export var enable_diagonal: bool = true

## Godot's built-in A* solver.
var astar: AStar2D
## Set of blocked grid positions as "x,y" strings.
var blocked: Dictionary = {}
## Set of occupied grid positions.
var occupied: Dictionary = {}

## Cardinal direction offsets (pre-typed to avoid inference issues).
const DIRS_CARDINAL: Array = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
## Diagonal direction offsets.
const DIRS_DIAGONAL: Array = [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]


func _ready() -> void:
	_build_grid()


## Build the A* graph and connect neighbors.
func _build_grid() -> void:
	astar = AStar2D.new()
	for xi in grid_width:
		for yi in grid_height:
			var idi: int = _point_id(xi, yi)
			astar.add_point(idi, Vector2(xi * tile_size + tile_size / 2.0, yi * tile_size + tile_size / 2.0))

	# Connect cardinal neighbors
	for xi in grid_width:
		for yi in grid_height:
			var idi: int = _point_id(xi, yi)
			for d in DIRS_CARDINAL:
				var dir_vec: Vector2i = d
				var nxi: int = xi + dir_vec.x
				var nyi: int = yi + dir_vec.y
				if nxi >= 0 and nxi < grid_width and nyi >= 0 and nyi < grid_height:
					var nid: int = _point_id(nxi, nyi)
					if not astar.are_points_connected(idi, nid):
						astar.connect_points(idi, nid)

	# Connect diagonal neighbors (Stoneshard-style numpad movement)
	if enable_diagonal:
		for xi in grid_width:
			for yi in grid_height:
				var idi: int = _point_id(xi, yi)
				for d in DIRS_DIAGONAL:
					var dir_vec: Vector2i = d
					var nxi: int = xi + dir_vec.x
					var nyi: int = yi + dir_vec.y
					if nxi >= 0 and nxi < grid_width and nyi >= 0 and nyi < grid_height:
						var nid: int = _point_id(nxi, nyi)
						if not astar.are_points_connected(idi, nid):
							astar.connect_points(idi, nid, 1.4)


## Convert world position to grid coordinate.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / tile_size), floori(world_pos.y / tile_size))


## Convert grid coordinate to world position (center of tile).
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size + tile_size / 2.0, grid_pos.y * tile_size + tile_size / 2.0)


## Check if a grid position is within bounds and walkable.
func is_walkable(grid_pos: Vector2i, ignore_occupancy: bool = false) -> bool:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	if grid_pos.x < 0 or grid_pos.x >= grid_width or grid_pos.y < 0 or grid_pos.y >= grid_height:
		return false
	if key in blocked:
		return false
	if not ignore_occupancy and key in occupied:
		return false
	return true


## Mark a grid position as blocked (wall, obstacle).
func set_blocked(grid_pos: Vector2i, blocked_state: bool = true) -> void:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	if blocked_state:
		blocked[key] = true
	else:
		blocked.erase(key)


## Mark a grid position as occupied by a unit.
func set_occupied(grid_pos: Vector2i, unit: Node) -> void:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	if unit:
		occupied[key] = unit
	else:
		occupied.erase(key)


## Get the unit occupying a grid position (or null).
func get_occupant(grid_pos: Vector2i) -> Node:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	if key in occupied:
		return occupied[key]
	return null


## Compute A* path from world position to world position.
## Returns array of Vector2i grid positions (excluding start, including destination).
func find_path_world(from_world: Vector2, to_world: Vector2) -> Array[Vector2i]:
	var from_grid: Vector2i = world_to_grid(from_world)
	var to_grid: Vector2i = world_to_grid(to_world)
	return find_path_grid(from_grid, to_grid)


## Compute A* path from grid position to grid position.
func find_path_grid(from_grid: Vector2i, to_grid: Vector2i) -> Array[Vector2i]:
	var from_id: int = _point_id(from_grid.x, from_grid.y)
	var to_id: int = _point_id(to_grid.x, to_grid.y)

	if not astar.has_point(from_id) or not astar.has_point(to_id):
		return []

	# Check destination isn't blocked
	var to_key: String = "%d,%d" % [to_grid.x, to_grid.y]
	if to_key in blocked:
		return []

	# Temporarily un-occupy the starting position so unit can path away
	var from_key: String = "%d,%d" % [from_grid.x, from_grid.y]
	var was_occupied: bool = from_key in occupied
	if was_occupied:
		occupied.erase(from_key)

	var point_ids: PackedInt64Array = astar.get_id_path(from_id, to_id)

	# Restore
	if was_occupied:
		occupied[from_key] = true

	if point_ids.is_empty():
		return []

	# Skip the first point (current position), convert rest to Vector2i
	var result: Array[Vector2i] = []
	for idx in range(1, point_ids.size()):
		var p: Vector2 = astar.get_point_position(point_ids[idx])
		result.append(Vector2i(roundi(p.x / tile_size - 0.5), roundi(p.y / tile_size - 0.5)))

	return result


## Get the 4 or 8 neighboring grid positions.
func get_neighbors(grid_pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in DIRS_CARDINAL:
		var dir_vec: Vector2i = d
		var n: Vector2i = grid_pos + dir_vec
		if is_walkable(n):
			result.append(n)
	if enable_diagonal:
		for d in DIRS_DIAGONAL:
			var dir_vec: Vector2i = d
			var n: Vector2i = grid_pos + dir_vec
			if is_walkable(n):
				result.append(n)
	return result


## Unique point ID for AStar2D.
static func _point_id(x: int, y: int) -> int:
	return y * 100000 + x
