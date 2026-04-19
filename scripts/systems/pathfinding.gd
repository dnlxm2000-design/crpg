# PathfindingSystem - A* pathfinding for grid-based movement

extends Node

var grid_width: int = 20
var grid_height: int = 20

func _init():
	pass

# Set grid dimensions
func set_grid_size(width: int, height: int):
	grid_width = width
	grid_height = height

# A* pathfinding algorithm
# start: start position, end: goal, walkable_map: 2D array of move costs
# returns: array of positions, empty if not found
func find_path(start: Vector2i, end: Vector2i, walkable_map: Array) -> Array:
	if not _is_valid_position(end, walkable_map):
		return []
	
	var open_set: Array = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _heuristic(start, end)}
	
	while open_set.size() > 0:
		var current = _get_lowest_f_score(open_set, f_score)
		
		if current == end:
			return _reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		var neighbors = _get_neighbors(current)
		for neighbor in neighbors:
			if not _is_valid_position(neighbor, walkable_map):
				continue
			
			var tentative_g_score = g_score[current] + _get_move_cost(neighbor, walkable_map)
			
			if not g_score.has(neighbor) or tentative_g_score < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic(neighbor, end)
				
				if not open_set.has(neighbor):
					open_set.append(neighbor)
	
	return []

# Manhattan distance heuristic
func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# Get position with lowest f_score in open set
func _get_lowest_f_score(open_set: Array, f_score: Dictionary) -> Vector2i:
	var lowest = open_set[0]
	for pos in open_set:
		if not f_score.has(pos):
			continue
		if not f_score.has(lowest) or f_score[pos] < f_score[lowest]:
			lowest = pos
	return lowest

# Get 4-directional neighbors
func _get_neighbors(pos: Vector2i) -> Array:
	return [
		Vector2i(pos.x - 1, pos.y),
		Vector2i(pos.x + 1, pos.y),
		Vector2i(pos.x, pos.y - 1),
		Vector2i(pos.x, pos.y + 1)
	]

# Check if position is valid and walkable
func _is_valid_position(pos: Vector2i, walkable_map: Array) -> bool:
	if pos.x < 0 or pos.x >= grid_width or pos.y < 0 or pos.y >= grid_height:
		return false
	if walkable_map.size() <= pos.y or walkable_map[pos.y].size() <= pos.x:
		return false
	return walkable_map[pos.y][pos.x] >= 0

# Get move cost at position
func _get_move_cost(pos: Vector2i, walkable_map: Array) -> int:
	if walkable_map.size() > pos.y and walkable_map[pos.y].size() > pos.x:
		return walkable_map[pos.y][pos.x]
	return 1

# Reconstruct path from came_from dictionary
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path