# terrain_manager.gd — 아이소메트릭 입체 지형 + 유적지 생성기.
# 높이 스택 TileMapLayer + 절차적 타일셋 + 유적지 Hollow Cube.
extends Node2D

## 타일셋 색상
const C_GRASS := Color("#99C27C")
const C_DIRT := Color("#6D5545")
const C_PATH := Color("#D1B48C")
const C_STONE := Color("#A0A4A6")
const C_STONE_L := Color("#707476")
const C_STONE_R := Color("#4D5153")
const C_MOSS := Color("#6B8E4D")

# 아틀라스 좌표 (8열 × 2행)
const T_GRASS := Vector2i(0, 0)
const T_DIRT := Vector2i(1, 0)
const T_PATH := Vector2i(2, 0)
const T_STONE := Vector2i(4, 0)
const T_MOSS := Vector2i(5, 0)
const T_STONE_L := Vector2i(4, 1)
const T_STONE_R := Vector2i(5, 1)
const T_GRASS_SIDE := Vector2i(0, 1)
const T_DIRT_SIDE := Vector2i(1, 1)
const T_PATH_SIDE := Vector2i(2, 1)
# col 3, 6, 7: 예비

const TILE_W: int = 64
const TILE_H: int = 32
const MAX_H: int = 5
const ATLAS_COLS: int = 8

var _layers: Array[TileMapLayer] = []
var _noise: FastNoiseLite = null
var _grid_world: Node = null
var _rng: RandomNumberGenerator = null
var _world_size := Vector2i(63, 126)
var _sid: int = 0


func _ready() -> void:
	_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")
	if _grid_world:
		_world_size = Vector2i(_grid_world.grid_width, _grid_world.grid_height)

	_noise = FastNoiseLite.new()
	_noise.seed = 42
	_noise.frequency = 0.04
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_rng = RandomNumberGenerator.new()
	_rng.seed = 123

	_build_tileset()
	_generate_and_render()


func _build_tileset() -> void:
	var img := Image.create(TILE_W * ATLAS_COLS, TILE_H * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# 1행: 윗면 (col 0~7)
	_draw_diamond(img, 0, C_GRASS)
	_draw_diamond(img, 1, C_DIRT)
	_draw_diamond(img, 2, C_PATH)
	# col 3 = 비어있음 (예비)
	_draw_diamond(img, 4, C_STONE)
	_draw_diamond_moss(img, 5, C_STONE)   # col 5 = 이끼 석재
	# col 6~7 = 비어있음 (예비)

	# 2행: 옆면 (col 0~7)
	_draw_side(img, 0, C_GRASS.darkened(0.4))
	_draw_side(img, 1, C_DIRT)
	_draw_side(img, 2, C_PATH.darkened(0.35))
	_draw_side(img, 4, C_STONE_L)
	_draw_side(img, 5, C_STONE_R)

	var tex := ImageTexture.create_from_image(img)
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE_W, TILE_H)
	for row: int in 2:
		for col: int in ATLAS_COLS:
			src.create_tile(Vector2i(col, row), Vector2i(1, 1))
	ts.add_source(src)
	_sid = ts.get_source_id(0)

	for level: int in range(MAX_H + 1):
		var layer := TileMapLayer.new()
		layer.name = "H%d" % level
		layer.tile_set = ts
		layer.position = Vector2(0, -level * TILE_H / 2)
		layer.y_sort_enabled = true
		add_child(layer)
		_layers.append(layer)


# ─── 지형 생성 ───

func _generate_and_render() -> void:
	var hm: Dictionary = {}

	# 노이즈 높이맵
	for x: int in range(_world_size.x):
		for y: int in range(_world_size.y):
			var raw: float = _noise.get_noise_2d(x, y)
			hm["%d,%d" % [x, y]] = clampi(roundi(abs(raw) * 5), 0, MAX_H)

	# 십자형 길
	var cy: int = _world_size.y / 2 - 2
	for x: int in range(10, 50):
		for yy: int in range(cy, cy + 3):
			hm["%d,%d" % [x, yy]] = 1
	var cx: int = _world_size.x / 2 - 1
	for y: int in range(20, 90):
		for xx: int in range(cx, cx + 2):
			hm["%d,%d" % [xx, y]] = 1

	# 유적지 생성
	_create_ruins(Vector2i(50, 20), 5, hm)

	# 렌더링
	for layer in _layers:
		layer.clear()

	for x: int in range(_world_size.x):
		for y: int in range(_world_size.y):
			var h: int = hm.get("%d,%d" % [x, y], 0)
			if h <= 0:
				continue
			var pos: Vector2i = Vector2i(x, y)
			_layers[h].set_cell(pos, _sid, _get_top(x, y, hm))
			for lev: int in range(1, h + 1):
				var bh: int = hm.get("%d,%d" % [x, y + 1], 0)
				if bh < lev:
					_layers[lev].set_cell(pos, _sid, _get_side(x, y, hm, lev if lev == h else 0))

	# GridWorld elevation 동기화
	if _grid_world and _grid_world.has_method("set_elevation"):
		for x: int in range(_world_size.x):
			for y: int in range(_world_size.y):
				var h: int = hm.get("%d,%d" % [x, y], 0)
				_grid_world.set_elevation(Vector2i(x, y), clampi(h, 0, 2))


# ─── 유적지 생성 (Hollow Cube) ───

## start_pos: 그리드 좌상단, size: 한 변 길이, hm: 높이맵 참조
func _create_ruins(start: Vector2i, size: int, hm: Dictionary) -> void:
	var mid: int = size / 2  # 입구 위치 (앞면 중앙)

	for x: int in range(size):
		for y: int in range(size):
			var gp: Vector2i = start + Vector2i(x, y)
			if gp.x < 0 or gp.x >= _world_size.x or gp.y < 0 or gp.y >= _world_size.y:
				continue

			var is_wall: bool = (x == 0 or x == size - 1 or y == 0 or y == size - 1)
			var is_entrance: bool = (x == mid and y == size - 1)

			if is_wall and not is_entrance:
				# 무너진 벽: 높이 1~3 랜덤
				var wall_h: int = _rng.randi_range(1, 3)
				hm["%d,%d" % [gp.x, gp.y]] = wall_h
			else:
				# 내부 바닥
				hm["%d,%d" % [gp.x, gp.y]] = 0

	# 그림자 데칼: 벽 북쪽(y-1) 타일을 어둡게 (고도 1로 표시, 아래에서 처리)
	for x: int in range(size):
		for y: int in range(size):
			var gp: Vector2i = start + Vector2i(x, y)
			if y == 0:
				var shadow_pos: Vector2i = gp + Vector2i(0, -1)
				var sk: String = "%d,%d" % [shadow_pos.x, shadow_pos.y]
				if hm.has(sk) and hm[sk] == 0:
					hm[sk] = 1  # 그림자 효과 (낮은 고도로 표시)


# ─── 타일 종류 결정 ───

func _get_top(x: int, y: int, hm: Dictionary) -> Vector2i:
	var h: int = hm.get("%d,%d" % [x, y], 0)
	var key: String = "%d,%d" % [x, y]

	# 유적지 돌 (key prefix check: start + 크기 영역)
	if h >= 2 and _is_ruins_area(x, y):
		# 이끼: 20% 확률
		hm["%s_moss" % key] = hm.get("%s_moss" % key, false)
		if hm.get("%s_moss" % key, _rng.randf() < 0.2):
			return T_MOSS
		return T_STONE

	if h >= 4:
		return T_STONE  # 산 정상 = 돌
	if _is_path(x, y):
		return T_PATH
	return T_GRASS


func _get_side(x: int, y: int, hm: Dictionary, _is_top_level: int) -> Vector2i:
	var h: int = hm.get("%d,%d" % [x, y], 0)

	# 유적지 돌 옆면
	if _is_ruins_area(x, y) and h > 0:
		# 좌측(L) vs 우측(R) 그림자: R이 더 어두움
		if _rng.randf() < 0.5:
			return T_STONE_L
		return T_STONE_R

	return T_DIRT_SIDE


func _is_ruins_area(x: int, y: int) -> bool:
	# 유적지 영역: (50,20) ~ (54,24) — size=5
	return x >= 50 and x < 55 and y >= 20 and y < 25


func _is_path(x: int, y: int) -> bool:
	var cy: int = _world_size.y / 2 - 2
	var cx: int = _world_size.x / 2 - 1
	if x >= 10 and x < 50 and y >= cy and y < cy + 3:
		return true
	if y >= 20 and y < 90 and x >= cx and x < cx + 2:
		return true
	return false


# ─── 도우미 ───

func _draw_diamond(img: Image, col: int, color: Color) -> void:
	var cx: int = col * TILE_W + TILE_W / 2
	var cy: int = TILE_H / 2
	for py: int in range(TILE_H):
		for px: int in range(TILE_W):
			var nx: float = (px - TILE_W / 2.0) / (TILE_W / 2.0)
			var ny: float = (py - TILE_H / 2.0) / (TILE_H / 2.0)
			if abs(nx) + abs(ny) <= 1.0:
				img.set_pixel(cx - TILE_W / 2 + px, cy - TILE_H / 2 + py, color)


## 석재 윗면에 녹색 이끼 점을 추가
func _draw_diamond_moss(img: Image, col: int, base_color: Color) -> void:
	var cx: int = col * TILE_W + TILE_W / 2
	var cy: int = TILE_H / 2
	var mg := RandomNumberGenerator.new()
	mg.seed = col * 777
	for py: int in range(TILE_H):
		for px: int in range(TILE_W):
			var nx: float = (px - TILE_W / 2.0) / (TILE_W / 2.0)
			var ny: float = (py - TILE_H / 2.0) / (TILE_H / 2.0)
			if abs(nx) + abs(ny) <= 1.0:
				var c: Color = base_color
				if mg.randf() < 0.08:
					c = c.lerp(C_MOSS, mg.randf() * 0.6)
				img.set_pixel(cx - TILE_W / 2 + px, cy - TILE_H / 2 + py, c)


func _draw_side(img: Image, col: int, color: Color) -> void:
	var cx: int = col * TILE_W + TILE_W / 2
	var cy: int = TILE_H + TILE_H / 2
	for py: int in range(TILE_H / 2, TILE_H):
		for px: int in range(TILE_W):
			var nx: float = (px - TILE_W / 2.0) / (TILE_W / 2.0)
			var ny: float = (py - TILE_H / 2.0) / (TILE_H / 2.0)
			if abs(nx) + abs(ny) <= 1.0:
				img.set_pixel(cx - TILE_W / 2 + px, cy - TILE_H / 2 + py, color)
