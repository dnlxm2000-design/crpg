# terrain_manager.gd — 아이소메트릭 입체 지형 (TileMapLayer 스택).
# 높이 레벨별로 TileMapLayer를 쌓아 3D-like 지형 + 절벽 표현.
extends Node2D

## 타일셋 색상
const COLOR_GRASS_TOP := Color("#99C27C")
const COLOR_DIRT_SIDE := Color("#6D5545")
const COLOR_PATH_TOP := Color("#D1B48C")
const COLOR_MOUNTAIN := Color("#A0A0A0")
const COLOR_MOUNTAIN_SIDE := Color("#6B6B6B")

# 아틀라스 좌표 (4열 × 2행)
const T_GRASS := Vector2i(0, 0)
const T_DIRT := Vector2i(1, 0)
const T_PATH := Vector2i(2, 0)
const T_MOUNTAIN := Vector2i(3, 0)
const T_GRASS_SIDE := Vector2i(0, 1)
const T_DIRT_SIDE := Vector2i(1, 1)
const T_PATH_SIDE := Vector2i(2, 1)
const T_MOUNTAIN_SIDE := Vector2i(3, 1)

const TILE_W: int = 64
const TILE_H: int = 32
const MAX_H: int = 5

var _layers: Array[TileMapLayer] = []
var _noise: FastNoiseLite = null
var _grid_world: Node = null
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

	_build_tileset()
	_generate_and_render()


func _build_tileset() -> void:
	var img := Image.create(TILE_W * 4, TILE_H * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# 1행: 윗면
	_draw_diamond(img, 0, COLOR_GRASS_TOP)
	_draw_diamond(img, 1, COLOR_DIRT_SIDE)
	_draw_diamond(img, 2, COLOR_PATH_TOP)
	_draw_diamond(img, 3, COLOR_MOUNTAIN)
	# 2행: 옆면
	_draw_side(img, 0, COLOR_GRASS_TOP.darkened(0.4))
	_draw_side(img, 1, COLOR_DIRT_SIDE)
	_draw_side(img, 2, COLOR_PATH_TOP.darkened(0.35))
	_draw_side(img, 3, COLOR_MOUNTAIN_SIDE)

	var tex := ImageTexture.create_from_image(img)
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE_W, TILE_H)
	for row in 2:
		for col in 4:
			src.create_tile(Vector2i(col, row), Vector2i(1, 1))
	ts.add_source(src)
	_sid = ts.get_source_id(0)

	# 높이 레이어 생성 (0=물, 1~5=지형)
	for level in range(MAX_H + 1):
		var layer := TileMapLayer.new()
		layer.name = "H%d" % level
		layer.tile_set = ts
		layer.position = Vector2(0, -level * TILE_H / 2)
		layer.y_sort_enabled = true
		add_child(layer)
		_layers.append(layer)


func _generate_and_render() -> void:
	var hmap: Dictionary = {}

	# 노이즈 높이맵
	for x: int in range(_world_size.x):
		for y: int in range(_world_size.y):
			var raw: float = _noise.get_noise_2d(x, y)
			hmap["%d,%d" % [x, y]] = clampi(roundi(abs(raw) * 5), 0, MAX_H)

	# 십자형 길 (고도 1로 고정)
	var cy: int = _world_size.y / 2 - 2
	for x: int in range(10, 50):
		for yy: int in range(cy, cy + 3):
			hmap["%d,%d" % [x, yy]] = 1
	var cx: int = _world_size.x / 2 - 1
	for y: int in range(20, 90):
		for xx: int in range(cx, cx + 2):
			hmap["%d,%d" % [xx, y]] = 1

	# 렌더링
	for layer in _layers:
		layer.clear()

	for x: int in range(_world_size.x):
		for y: int in range(_world_size.y):
			var h: int = hmap.get("%d,%d" % [x, y], 0)
			if h <= 0:
				continue
			var pos: Vector2i = Vector2i(x, y)

			# 윗면 (h 레이어에)
			_layers[h].set_cell(pos, _sid, _get_top(x, y, hmap))

			# 옆면: 아래(y+1)의 높이가 더 낮으면 절벽 표시
			for lev: int in range(1, h + 1):
				var bh: int = hmap.get("%d,%d" % [x, y + 1], 0)
				if bh < lev:
					_layers[lev].set_cell(pos, _sid, T_DIRT_SIDE)

	# GridWorld elevation 동기화
	if _grid_world and _grid_world.has_method("set_elevation"):
		for x: int in range(_world_size.x):
			for y: int in range(_world_size.y):
				var h: int = hmap.get("%d,%d" % [x, y], 0)
				_grid_world.set_elevation(Vector2i(x, y), clampi(h, 0, 2))


func _get_top(x: int, y: int, hm: Dictionary) -> Vector2i:
	var h: int = hm.get("%d,%d" % [x, y], 0)
	if h >= 4:
		return T_MOUNTAIN
	if _is_path(x, y):
		return T_PATH
	return T_GRASS


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


func _draw_side(img: Image, col: int, color: Color) -> void:
	var cx: int = col * TILE_W + TILE_W / 2
	var cy: int = TILE_H + TILE_H / 2
	for py: int in range(TILE_H / 2, TILE_H):
		for px: int in range(TILE_W):
			var nx: float = (px - TILE_W / 2.0) / (TILE_W / 2.0)
			var ny: float = (py - TILE_H / 2.0) / (TILE_H / 2.0)
			if abs(nx) + abs(ny) <= 1.0:
				img.set_pixel(cx - TILE_W / 2 + px, cy - TILE_H / 2 + py, color)
