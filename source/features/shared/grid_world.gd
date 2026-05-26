# grid_world.gd ??Tile-based grid with A* pathfinding (3D).
# Grid coords (x, y) map to world (x, 0, y) ??one unit per tile.
# Isometric view is handled by Camera3D rotation, NOT by grid coords.
extends Node
class_name GridWorld

## ????ш린 (1 tile = 2 units ??matches TerrainManager).
const TILE_SIZE: float = 2.0
## Grid dimensions (tiles).
@export var grid_width: int = 63
@export var grid_height: int = 126
## Enable 8-directional movement (diagonals).
@export var enable_diagonal: bool = true

## Godot's built-in A* solver (3D).
var astar: AStar3D
## Set of blocked grid positions as "x,y" strings.
var blocked: Dictionary = {}
## Set of occupied grid positions.
var occupied: Dictionary = {}
## 怨좊룄 ?곗씠??("x,y" ??0=臾? 1=?吏?, 2=怨좎??).
var elevation: Dictionary = {}

## Cardinal direction offsets (3D: Y=0, XZ plane).
const DIRS_CARDINAL: Array = [Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0)]
## Diagonal direction offsets.
const DIRS_DIAGONAL: Array = [Vector3i(1, 0, -1), Vector3i(1, 0, 1), Vector3i(-1, 0, 1), Vector3i(-1, 0, -1)]


func _ready() -> void:
	_build_grid()


## Build the A* graph and connect neighbors.
## A* ???꾩튂???⑥닚 3D 醫뚰몴 ?ъ슜 (x, 0, y).
func _build_grid() -> void:
	astar = AStar3D.new()
	for xi in grid_width:
		for yi in grid_height:
			var idi: int = _point_id(xi, yi)
			astar.add_point(idi, _grid_to_world(Vector2i(xi, yi)))

	# Connect cardinal neighbors
	for xi in grid_width:
		for yi in grid_height:
			var idi: int = _point_id(xi, yi)
			for d in DIRS_CARDINAL:
				var dir_vec: Vector3i = d
				var nxi: int = xi + dir_vec.x
				var nyi: int = yi + dir_vec.z
				if nxi >= 0 and nxi < grid_width and nyi >= 0 and nyi < grid_height:
					var nid: int = _point_id(nxi, nyi)
					if not astar.are_points_connected(idi, nid):
						astar.connect_points(idi, nid)

	# Connect diagonal neighbors
	if enable_diagonal:
		for xi in grid_width:
			for yi in grid_height:
				var idi: int = _point_id(xi, yi)
				for d in DIRS_DIAGONAL:
					var dir_vec: Vector3i = d
					var nxi: int = xi + dir_vec.x
					var nyi: int = yi + dir_vec.z
					if nxi >= 0 and nxi < grid_width and nyi >= 0 and nyi < grid_height:
						var nid: int = _point_id(nxi, nyi)
						if not astar.are_points_connected(idi, nid):
							astar.connect_points(idi, nid, 1.4)


## 洹몃━?????붾뱶 醫뚰몴 蹂??(3D: XZ ?됰㈃, ?⑥닚 留ㅽ븨).
func _grid_to_world(grid_pos: Vector2i) -> Vector3:
	return Vector3(
		grid_pos.x * TILE_SIZE,
		0.0,
		grid_pos.y * TILE_SIZE
	)


## ?붾뱶 醫뚰몴 ??洹몃━??醫뚰몴 蹂??
func _world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / TILE_SIZE),
		floori(world_pos.z / TILE_SIZE)
	)


## Convert world position to grid coordinate.
func world_to_grid(world_pos: Vector3) -> Vector2i:
	return _world_to_grid(world_pos)


## Convert grid coordinate to world position ??center of tile.
func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return _grid_to_world(grid_pos)


## ??? Elevation / Heightmap ???

## ?뱀젙 ??쇱쓽 怨좊룄 諛섑솚 (湲곕낯 1 = ?됱썝).
func get_elevation(grid_pos: Vector2i) -> int:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	return elevation.get(key, 1)


## ?????媛?怨좊룄 李⑥씠 諛섑솚 (?묒닔 = from?????믪쓬).
func get_elevation_difference(from_pos: Vector2i, to_pos: Vector2i) -> int:
	return get_elevation(from_pos) - get_elevation(to_pos)


## ?뱀젙 ??쇱쓽 怨좊룄 ?ㅼ젙.
func set_elevation(grid_pos: Vector2i, value: int) -> void:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	elevation[key] = value


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
	if unit != null:
		occupied[key] = unit
	else:
		occupied.erase(key)


## Get the unit occupying a grid position (null if empty).
func get_occupant(grid_pos: Vector2i) -> Node:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	return occupied.get(key, null)


## Get all cardinal + diagonal neighbors (filtered by walkability).
func get_neighbors(grid_pos: Vector2i, ignore_occupancy: bool = false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dirs = DIRS_CARDINAL.duplicate()
	if enable_diagonal:
		dirs.append_array(DIRS_DIAGONAL)
	for d in dirs:
		var n: Vector2i = Vector2i(grid_pos.x + d.x, grid_pos.y + d.z)
		if is_walkable(n, ignore_occupancy):
			result.append(n)
	return result


## Find path between two grid positions using A*.
## Returns array of grid positions (excluding start).
func find_path_grid(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
	# Clamp positions to grid bounds
	from_pos = Vector2i(clampi(from_pos.x, 0, grid_width - 1), clampi(from_pos.y, 0, grid_height - 1))
	to_pos = Vector2i(clampi(to_pos.x, 0, grid_width - 1), clampi(to_pos.y, 0, grid_height - 1))
	
	var from_id: int = _point_id(from_pos.x, from_pos.y)
	var to_id: int = _point_id(to_pos.x, to_pos.y)

	# Temporarily disable occupancy for pathfinding
	var from_occ = occupied.get("%d,%d" % [from_pos.x, from_pos.y], null)
	var to_occ = occupied.get("%d,%d" % [to_pos.x, to_pos.y], null)
	occupied.erase("%d,%d" % [from_pos.x, from_pos.y])
	occupied.erase("%d,%d" % [to_pos.x, to_pos.y])

	# Temporarily unblock target
	var to_blocked = blocked.has("%d,%d" % [to_pos.x, to_pos.y])
	if to_blocked:
		blocked.erase("%d,%d" % [to_pos.x, to_pos.y])

	var raw_path: PackedVector3Array = astar.get_point_path(from_id, to_id)

	# Restore occupancy and blocked
	if from_occ != null:
		occupied["%d,%d" % [from_pos.x, from_pos.y]] = from_occ
	if to_occ != null:
		occupied["%d,%d" % [to_pos.x, to_pos.y]] = to_occ
	if to_blocked:
		blocked["%d,%d" % [to_pos.x, to_pos.y]] = true

	if raw_path.size() < 2:
		return []

	# Convert world positions back to grid
	var result: Array[Vector2i] = []
	for i in range(1, raw_path.size()):
		result.append(_world_to_grid(raw_path[i]))
	return result


## Internal: unique point ID for A*.
func _point_id(xi: int, yi: int) -> int:
	return xi * grid_height + yi
