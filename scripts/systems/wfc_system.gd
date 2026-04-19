class_name WFCSystem
extends Node

enum TileType {
	WALL = 0,
	FLOOR = 1,
	DOOR = 2,
	WATER = 3,
	COVER = 4,
	STAIRS_UP = 6,
	STAIRS_DOWN = 7
}

var width: int = 20
var height: int = 20
var output_grid: Array = []
var collapsed: Array = []
var entropy: Array = []

var tile_weights = {
	TileType.WALL: 0.15,
	TileType.FLOOR: 0.75,
	TileType.DOOR: 0.02,
	TileType.COVER: 0.08
}

var adjacency_rules = {
	TileType.WALL: [TileType.WALL, TileType.FLOOR, TileType.DOOR],
	TileType.FLOOR: [TileType.WALL, TileType.FLOOR, TileType.DOOR, TileType.COVER],
	TileType.DOOR: [TileType.FLOOR, TileType.WALL],
	TileType.COVER: [TileType.FLOOR, TileType.WALL, TileType.COVER]
}

func _ready():
	pass

func set_size(w: int, h: int):
	width = w
	height = h

func generate() -> Array:
	_initialize_grid()
	var attempts = 0
	var max_attempts = 10
	var success = false
	
	while attempts < max_attempts:
		attempts += 1
		_initialize_grid()
		
		success = _collapse_grid()
		if success:
			break
	
	if not success:
		_fallback_generate()
	
	return output_grid

func _initialize_grid():
	output_grid.clear()
	collapsed.clear()
	entropy.clear()
	
	for y in range(height):
		var row = []
		var collapsed_row = []
		var entropy_row = []
		for x in range(width):
			row.append(-1)
			collapsed_row.append(false)
			
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				entropy_row.append([TileType.WALL])
			else:
				entropy_row.append(tile_weights.keys().duplicate())
		output_grid.append(row)
		collapsed.append(collapsed_row)
		entropy.append(entropy_row)

func _collapse_grid() -> bool:
	var iterations = 0
	var max_iterations = width * height * 2
	
	while iterations < max_iterations:
		iterations += 1
		
		var cell = _find_lowest_entropy_cell()
		if cell == Vector2i(-1, -1):
			break
		
		var pos = cell as Vector2i
		var possible = entropy[pos.y][pos.x]
		
		if possible.is_empty():
			return false
		
		var selected = _weighted_select(possible)
		output_grid[pos.y][pos.x] = selected
		collapsed[pos.y][pos.x] = true
		
		_propagate_constraints(pos, selected)
		
		if _is_fully_collapsed():
			return _validate_output()
	
	return _validate_output()

func _find_lowest_entropy_cell() -> Vector2i:
	var min_entropy = 999
	var best_cell = Vector2i(-1, -1)
	
	for y in range(height):
		for x in range(width):
			if collapsed[y][x]:
				continue
			
			var e = entropy[y][x].size()
			if e < min_entropy:
				min_entropy = e
				best_cell = Vector2i(x, y)
	
	return best_cell

func _weighted_select(options: Array) -> int:
	var total_weight = 0.0
	var weights = []
	
	for opt in options:
		var w = tile_weights.get(opt, 0.1)
		weights.append(w)
		total_weight += w
	
	var rand = randf() * total_weight
	var cumulative = 0.0
	
	for i in range(options.size()):
		cumulative += weights[i]
		if rand <= cumulative:
			return options[i]
	
	return options[0]

func _propagate_constraints(pos: Vector2i, tile_type: int):
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	
	for dir in directions:
		var nx = pos.x + dir.x
		var ny = pos.y + dir.y
		
		if nx < 0 or nx >= width or ny < 0 or ny >= height:
			continue
		if collapsed[ny][nx]:
			continue
		
		var allowed = adjacency_rules.get(tile_type, [tile_type])
		var current = entropy[ny][nx]
		var new_allowed = []
		
		for c in current:
			if c in allowed:
				new_allowed.append(c)
		
		if new_allowed.is_empty():
			entropy[ny][nx] = current.duplicate()
		else:
			entropy[ny][nx] = new_allowed

func _is_fully_collapsed() -> bool:
	for y in range(height):
		for x in range(width):
			if not collapsed[y][x]:
				return false
	return true

func _validate_output() -> bool:
	var floor_count = 0
	var wall_count = 0
	
	for y in range(height):
		for x in range(width):
			var t = output_grid[y][x]
			if t == TileType.FLOOR or t == TileType.DOOR or t == TileType.COVER:
				floor_count += 1
			elif t == TileType.WALL:
				wall_count += 1
	
	var total = width * height
	return floor_count > total * 0.3 and wall_count > total * 0.1

func _fallback_generate():
	for y in range(height):
		for x in range(width):
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				output_grid[y][x] = TileType.WALL
			elif randf() < 0.15:
				output_grid[y][x] = TileType.WALL
			else:
				output_grid[y][x] = TileType.FLOOR

func get_walkable_map() -> Array:
	var walkable = []
	for y in range(height):
		var row = []
		for x in range(width):
			var t = output_grid[y][x]
			if t == TileType.WALL or t == TileType.WATER:
				row.append(-1)
			else:
				row.append(1)
		walkable.append(row)
	return walkable
