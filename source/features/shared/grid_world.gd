# grid_world.gd — Isometric tile-based grid with A* pathfinding.
# Converts between grid coordinates and isometric world coordinates.
class_name GridWorld
extends Node

## 아이소메트릭 타일 크기 (너비 64, 높이 32 = 2:1 비율).
const TILE_WIDTH_ISO: int = 64
const TILE_HEIGHT_ISO: int = 32
## 레거시 호환용 타일 크기 (참조용).
const CELL_SIZE: int = 32
## Grid dimensions (tiles).
@export var grid_width: int = 63
@export var grid_height: int = 126
## Enable 8-directional movement (diagonals).
@export var enable_diagonal: bool = true

## Godot's built-in A* solver.
var astar: AStar2D
## Set of blocked grid positions as "x,y" strings.
var blocked: Dictionary = {}
## Set of occupied grid positions.
var occupied: Dictionary = {}
## 고도 데이터 ("x,y" → 0=물, 1=저지대, 2=고지대).
var elevation: Dictionary = {}
## 노이즈 기반 지형 생성기
var _noise: FastNoiseLite = null

## Cardinal direction offsets (pre-typed to avoid inference issues).
const DIRS_CARDINAL: Array = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
## Diagonal direction offsets.
const DIRS_DIAGONAL: Array = [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]


func _ready() -> void:
	_build_grid()
	# _generate_elevation() 제거: TerrainManager가 지형 생성 + 차단 설정
	# GridWorld가 다른 noise로 elevation을 덮어쓰면 blocked와 불일치 발생


## Build the A* graph and connect neighbors.
## A* 점 위치는 아이소메트릭 월드 좌표 사용.
func _build_grid() -> void:
	astar = AStar2D.new()
	for xi in grid_width:
		for yi in grid_height:
			var idi: int = _point_id(xi, yi)
			astar.add_point(idi, _grid_to_world_iso(Vector2i(xi, yi)))

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

	# Connect diagonal neighbors
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


## 아이소메트릭 그리드 → 월드 좌표 변환 (타일 중앙).
func _grid_to_world_iso(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * TILE_WIDTH_ISO / 2.0,
		(grid_pos.x + grid_pos.y) * TILE_HEIGHT_ISO / 2.0
	)


## 월드 좌표 → 아이소메트릭 그리드 좌표 변환.
func _world_to_grid_iso(world_pos: Vector2) -> Vector2i:
	var px: float = world_pos.x / (TILE_WIDTH_ISO / 2.0)
	var py: float = world_pos.y / (TILE_HEIGHT_ISO / 2.0)
	return Vector2i(
		floori((px + py) / 2.0),
		floori((py - px) / 2.0)
	)


## Convert world position to grid coordinate (isometric).
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return _world_to_grid_iso(world_pos)


## Convert grid coordinate to world position — center of isometric diamond.
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return _grid_to_world_iso(grid_pos)


## ─── Elevation / Heightmap ───

## 노이즈 기반 고도 생성. _ready()에서 자동 호출.
func _generate_elevation() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 0.05
	for x in grid_width:
		for y in grid_height:
			var v: float = _noise.get_noise_2d(x, y)
			var h: int = 0
			if v < -0.2:
				h = 0  # 물/낮은 지대
			elif v < 0.3:
				h = 1  # 평원
			else:
				h = 2  # 언덕
			var key: String = "%d,%d" % [x, y]
			elevation[key] = h


## 특정 타일의 고도 반환 (기본 1 = 평원).
func get_elevation(grid_pos: Vector2i) -> int:
	var key: String = "%d,%d" % [grid_pos.x, grid_pos.y]
	return elevation.get(key, 1)


## 두 타일 간 고도 차이 반환 (양수 = from이 더 높음).
func get_elevation_difference(from_pos: Vector2i, to_pos: Vector2i) -> int:
	return get_elevation(from_pos) - get_elevation(to_pos)


## 특정 타일의 고도 설정.
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

	# Skip the first point (current position), convert A* world position → grid coordinates
	var result: Array[Vector2i] = []
	for idx in range(1, point_ids.size()):
		var p: Vector2 = astar.get_point_position(point_ids[idx])
		var grid_pos: Vector2i = _world_to_grid_iso(p)
		var gk: String = "%d,%d" % [grid_pos.x, grid_pos.y]
		if gk in blocked:
			return []  # 경로 중간에 blocked된 점이 있으면 경로 무효
		result.append(grid_pos)

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


## Bresenham line between two grid positions. Returns all cells the line passes through.
func _bresenham_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dx: int = abs(to.x - from.x)
	var dy: int = abs(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx - dy
	var cx: int = from.x
	var cy: int = from.y

	while cx != to.x or cy != to.y:
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			cx += sx
		if e2 < dx:
			err += dx
			cy += sy
		result.append(Vector2i(cx, cy))

	return result


## 엄폐 레벨 계산: attacker → target 사이 blocked 타일 수로 판정.
## 인접 유닛(생명체)도 절반 엄폐로 간주.
func calculate_cover(attacker_pos: Vector2i, target_pos: Vector2i, attacker: Node = null, target: Node = null) -> int:
	# 인접 체크 (체스 거리 1)
	var chess_dist: int = max(abs(attacker_pos.x - target_pos.x), abs(attacker_pos.y - target_pos.y))
	if chess_dist <= 1:
		return 0  # 인접 시 엄폐 없음

	var line: Array[Vector2i] = _bresenham_line(attacker_pos, target_pos)
	var cover_count: int = 0
	var total_steps: int = line.size()

	for cell in line:
		var key: String = "%d,%d" % [cell.x, cell.y]
		if key in blocked:
			cover_count += 1
		# 경로상 다른 유닛도 절반 엄폐 제공
		elif key in occupied:
			var occupant = occupied[key]
			# 공격자나 대상자 자신은 제외
			if occupant != attacker and occupant != target:
				cover_count += 1

	if total_steps == 0:
		return 0

	var cover_ratio: float = float(cover_count) / float(total_steps)

	# 완전 엄폐: 경로상 60% 이상이 blocked
	if cover_ratio >= 0.6:
		return 3  # TOTAL
	# 3/4 엄폐: 30%~60%
	elif cover_ratio >= 0.3:
		return 2  # THREE_QUARTER
	# 절반 엄폐: 1개 이상의 엄폐물 존재
	elif cover_count >= 1:
		return 1  # HALF

	return 0  # NONE


## Unique point ID for AStar2D.
static func _point_id(x: int, y: int) -> int:
	return y * 100000 + x
