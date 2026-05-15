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
## 물 레이어 인덱스 (H0보다 아래)
var _layers: Array[TileMapLayer] = []
var _water_layer: TileMapLayer = null
var _noise: FastNoiseLite = null
var _grid_world: Node = null
var _rng: RandomNumberGenerator = null
var _world_size := Vector2i(63, 126)
var _sid: int = 0


func _ready() -> void:
	# Editor에서는 _generate_and_render 생략 (씬 저장 방지)
	if Engine.is_editor_hint():
		_build_tileset()
		return

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


## 강제 재생성 (수동 호출용)
func regenerate() -> void:
	_build_tileset()
	if not Engine.is_editor_hint():
		_generate_and_render()


func _build_tileset() -> void:
	var img := Image.create(TILE_W * ATLAS_COLS, TILE_H * 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# 1행: 윗면 (col 0~7)
	_draw_diamond(img, 0, C_GRASS)                       # GRASS (h≤1)
	_draw_diamond(img, 1, C_DIRT)                        # DIRT
	_draw_diamond(img, 2, C_PATH)                        # PATH
	_draw_diamond_water(img, 3)                          # WATER
	_draw_diamond(img, 4, C_STONE)                       # STONE (h≥4)
	_draw_diamond_moss(img, 5, C_STONE)                  # MOSS
	_draw_diamond(img, 6, C_GRASS.darkened(0.25))        # DARK_GRASS (h=2)
	_draw_diamond(img, 7, C_DIRT.darkened(0.3))          # ROCKY (h=3)

	# 2행: 옆면 (col 0~7)
	_draw_side(img, 0, C_GRASS.darkened(0.4))            # GRASS_SIDE
	_draw_side(img, 1, C_DIRT)                           # DIRT_SIDE
	_draw_side(img, 2, C_PATH.darkened(0.35))            # PATH_SIDE
	_draw_side(img, 4, C_STONE_L)                        # STONE_L
	_draw_side(img, 5, C_STONE_R)                        # STONE_R
	_draw_side(img, 6, C_GRASS.darkened(0.55))           # DARK_GRASS_SIDE
	_draw_side(img, 7, C_DIRT.darkened(0.5))             # ROCKY_SIDE

	# 3행: 물 애니메이션 프레임 (col 0~1)
	_draw_diamond_water(img, 0, 2, Color(0.15, 0.35, 0.65, 0.85))
	_draw_diamond_water(img, 1, 2, Color(0.2, 0.4, 0.7, 0.8))

	var tex := ImageTexture.create_from_image(img)
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = Vector2i(TILE_W, TILE_H)

	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE_W, TILE_H)
	for row in range(3):
		for col in range(ATLAS_COLS):
			src.create_tile(Vector2i(col, row), Vector2i(1, 1))

	ts.add_source(src)
	_sid = ts.get_source_id(0)

	# ── 레이어 생성 (TileSet 할당까지 여기서 한 번에) ──
	# 기존 레이어 정리
	for child in get_children():
		if child is TileMapLayer:
			remove_child(child)
			child.queue_free()
	_water_layer = null
	_layers.clear()

	# 워터 레이어
	_water_layer = TileMapLayer.new()
	_water_layer.name = "H_WATER"
	_water_layer.tile_set = ts
	_water_layer.z_index = 0
	_water_layer.position = Vector2(0, 0)
	_water_layer.y_sort_enabled = true
	add_child(_water_layer)
	if Engine.is_editor_hint():
		_water_layer.owner = get_tree().edited_scene_root

	# 높이 레이어 H0~H5
	for i in range(MAX_H + 1):
		var layer := TileMapLayer.new()
		layer.name = "H%d" % i
		layer.tile_set = ts
		layer.z_index = i + 1
		layer.position = Vector2(0, -i * 16)
		layer.y_sort_enabled = true
		add_child(layer)
		if Engine.is_editor_hint():
			layer.owner = get_tree().edited_scene_root
		_layers.append(layer)


# ─── 지형 생성 ───

func _generate_and_render() -> void:
	print("[Terrain] Generating terrain...")
	for layer in _layers:
		layer.clear()
	if _water_layer:
		_water_layer.clear()

	var hm: Dictionary = {}

	# 노이즈 높이맵
	for x in range(_world_size.x):
		for y in range(_world_size.y):
			var raw: float = _noise.get_noise_2d(x, y)
			hm["%d,%d" % [x, y]] = clampi(roundi(abs(raw) * 5), 0, MAX_H)

	# 십자형 길
	var cy: int = _world_size.y / 2 - 2
	for x in range(10, 50):
		for yy in range(cy, cy + 3):
			hm["%d,%d" % [x, yy]] = 1
	var cx: int = _world_size.x / 2 - 1
	for y in range(20, 90):
		for xx in range(cx, cx + 2):
			hm["%d,%d" % [xx, y]] = 1

	# 유적지
	_create_ruins(Vector2i(50, 20), 5, hm)

	# 렌더링 (4방향 벽면 = 정육면체 효과)
	var dirs := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	for x in range(_world_size.x):
		for y in range(_world_size.y):
			var h: int = hm.get("%d,%d" % [x, y], 0)
			if h <= 0:
				if _water_layer:
					var anim_frame: int = (x + y) % 2
					_water_layer.set_cell(Vector2i(x, y), _sid, Vector2i(anim_frame, 2))
				continue
			var pos := Vector2i(x, y)
			_layers[h].set_cell(pos, _sid, _get_top(x, y, hm))
			# 4방향 벽면 (이웃 높이가 낮으면 측면 표시)
			for d in dirs:
				var nh: int = hm.get("%d,%d" % [x + d.x, y + d.y], 0)
				for lev in range(1, h + 1):
					if nh < lev:
						_layers[lev].set_cell(pos, _sid, _get_side(x, y, hm, lev if lev == h else 0))

	# GridWorld elevation 동기화 + 물 블록 처리
	if _grid_world and _grid_world.has_method("set_elevation"):
		for key in hm:
			# _get_top()이 추가한 "x,y_moss" 키는 건너뜀
			if "_moss" in key:
				continue
			var parts = key.split(",")
			if parts.size() == 2:
				var gx := int(parts[0])
				var gy := int(parts[1])
				var h_val = hm[key]
				if typeof(h_val) != TYPE_INT:
					continue
				_grid_world.set_elevation(Vector2i(gx, gy), clampi(h_val, 0, 2))
				# 고도 0 = 물 = 통과 불가
				if h_val <= 0 and _grid_world.has_method("set_blocked"):
					_grid_world.set_blocked(Vector2i(gx, gy), true)

	# ── Polygon2D 정육면체 생성 (산, 고도 ≥2) ──
	_build_cubes(hm)

	print("[Terrain] done, total cells=", _layers[0].get_used_cells().size())


# ─── Polygon2D 정육면체 ───

var _cube_container: Node2D = null

## 높이 ≥2 타일을 Polygon2D 큐브로 렌더링 (플레이어와 동일한 방식).
func _build_cubes(hm: Dictionary) -> void:
	# 기존 큐브 정리
	if _cube_container:
		_cube_container.queue_free()
	_cube_container = Node2D.new()
	_cube_container.name = "CubeContainer"
	add_child(_cube_container)
	if Engine.is_editor_hint():
		_cube_container.owner = get_tree().edited_scene_root

	for x in range(_world_size.x):
		for y in range(_world_size.y):
			var h: int = hm.get("%d,%d" % [x, y], 0)
			if h < 2:
				continue
			_create_cube_at(Vector2i(x, y), h)


func _create_cube_at(grid: Vector2i, h: int) -> void:
	var world := _grid_to_world(grid)
	var wall_h := (h - 1) * 16  # 벽면 높이 (px)
	var top_y := -wall_h - 16   # 윗면 Y (최상단)

	# 높이별 색상
	var top_color: Color
	var side_l_color: Color
	var side_r_color: Color
	match h:
		2:
			top_color = Color(0.55, 0.65, 0.45)       # DARK_GRASS
			side_l_color = Color(0.35, 0.45, 0.30)
			side_r_color = Color(0.25, 0.35, 0.22)
		3:
			top_color = Color(0.6, 0.48, 0.38)        # ROCKY
			side_l_color = Color(0.45, 0.35, 0.28)
			side_r_color = Color(0.35, 0.28, 0.22)
		_:  # h >= 4
			top_color = Color(0.63, 0.64, 0.65)       # STONE
			side_l_color = Color(0.44, 0.45, 0.46)
			side_r_color = Color(0.30, 0.32, 0.33)

	var cube := Node2D.new()
	cube.name = "Cube_%d_%d" % [grid.x, grid.y]
	cube.position = world
	cube.z_index = 50
	cube.z_as_relative = false
	_cube_container.add_child(cube)

	# 윗면 (Top)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(0, top_y), Vector2(28, top_y + 16),
		Vector2(0, top_y + 32), Vector2(-28, top_y + 16),
	])
	top.color = top_color
	top.z_index = 3
	cube.add_child(top)

	# 왼쪽 옆면
	if wall_h > 0:
		var side_l := Polygon2D.new()
		side_l.polygon = PackedVector2Array([
			Vector2(-28, top_y + 16), Vector2(0, top_y + 32),
			Vector2(0, 16), Vector2(-28, 0),
		])
		side_l.color = side_l_color
		side_l.z_index = 2
		cube.add_child(side_l)

	# 오른쪽 옆면
	if wall_h > 0:
		var side_r := Polygon2D.new()
		side_r.polygon = PackedVector2Array([
			Vector2(28, top_y + 16), Vector2(0, top_y + 32),
			Vector2(0, 16), Vector2(28, 0),
		])
		side_r.color = side_r_color
		side_r.z_index = 1
		cube.add_child(side_r)


func _grid_to_world(grid: Vector2i) -> Vector2:
	# 아이소메트릭: 타일 64×32 기준 (TILE_W/2=32, TILE_H/2=16)
	return Vector2(
		(grid.x - grid.y) * 32,
		(grid.x + grid.y) * 16
	)


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

# ─── 공개 API ───

## 지형 타입 → 아틀라스 윗면 좌표
const TYPE_TOP: Dictionary = {
	0: Vector2i(0, 0),  # GRASS
	1: Vector2i(1, 0),  # DIRT
	2: Vector2i(2, 0),  # PATH
	4: Vector2i(4, 0),  # STONE
	5: Vector2i(5, 0),  # MOSS
}
## 지형 타입 → 아틀라스 옆면 좌표
const TYPE_SIDE: Dictionary = {
	0: Vector2i(0, 1),  # GRASS_SIDE
	1: Vector2i(1, 1),  # DIRT_SIDE
	2: Vector2i(2, 1),  # PATH_SIDE
	4: Vector2i(4, 1),  # STONE_L
	5: Vector2i(5, 1),  # STONE_R
}

## 키 "x,y" → 높이 추출 헬퍼
## tiles는 {"h": int, "t": int} Dict 또는 int (호환용) 를 값으로 가짐.
static func _hm_h(key: String, tiles: Dictionary, default: int = 0) -> int:
	var entry = tiles.get(key)
	if entry is Dictionary:
		return entry.get("h", default)
	if typeof(entry) == TYPE_INT:
		return entry
	return default

## (x, y) 위치에 고도 h, 지형 type의 타일 배치.
## tiles: 전체 맵 딕셔너리 (이웃 높이 참조용, "x,y" → {h, t}).
## 자동으로 4방향(남/동/북/서) 측면 벽면 + 고도 차이 필러 처리.
## h=0 이면 물 레이어에 타일 배치.
func set_tile(x: int, y: int, h: int, type: int, tiles: Dictionary) -> void:
	var pos := Vector2i(x, y)

	# 고도 0 = 물
	if h <= 0:
		if _water_layer:
			var anim_frame: int = (x + y) % 2
			_water_layer.set_cell(pos, _sid, Vector2i(anim_frame, 2))
		return

	if h > MAX_H:
		return

	# 윗면
	_layers[h].set_cell(pos, _sid, TYPE_TOP.get(type, T_GRASS))

	# 4방향 측면 체크
	var dirs := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	for d in dirs:
		var nk: String = "%d,%d" % [x + d.x, y + d.y]
		var nh: int = _hm_h(nk, tiles)
		for lev in range(1, h + 1):
			if nh < lev:
				_layers[lev].set_cell(pos, _sid, TYPE_SIDE.get(type, T_DIRT_SIDE))


## 맵 데이터로 일괄 지형 생성. 기존 타일을 모두 지우고 새로 그림.
## map_data 구조:
##   {
##     "width": 63, "height": 126,
##     "tiles": {
##       "x,y": { "h": 1..5, "t": 0..5 }, ...
##     }
##   }
func generate_from_map(map_data: Dictionary) -> void:
	var w: int = map_data.get("width", _world_size.x)
	var h: int = map_data.get("height", _world_size.y)
	var tiles: Dictionary = map_data.get("tiles", {})

	if w <= 0 or h <= 0 or tiles.is_empty():
		push_warning("TerrainManager: generate_from_map got empty map_data")
		return

	# 모든 레이어 클리어
	for layer in _layers:
		layer.clear()

	# 타일 배치 (키 순서 중요: 위→아래 방향으로 그리기 위해)
	var sorted_keys := tiles.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		var parts = key.split(",")
		if parts.size() != 2:
			continue
		var tx = int(parts[0])
		var ty = int(parts[1])
		if tx < 0 or tx >= w or ty < 0 or ty >= h:
			continue
		var info = tiles[key]
		var tile_h = info.get("h", 0) if info is Dictionary else info
		var tile_t = info.get("t", 0) if info is Dictionary else 0
		if tile_h < 0:
			continue
		# h=0 → 물 (set_tile에서 water_layer 처리)
		set_tile(tx, ty, tile_h, tile_t, tiles)

	# GridWorld elevation 동기화
	if _grid_world and _grid_world.has_method("set_elevation"):
		for key in tiles:
			var parts = key.split(",")
			if parts.size() != 2:
				continue
			var tx = int(parts[0])
			var ty = int(parts[1])
			var entry = tiles[key]
			var eh = entry.get("h", 0) if entry is Dictionary else entry
			_grid_world.set_elevation(Vector2i(tx, ty), clampi(eh, 0, 2))


## 예시 맵 데이터 반환 — 산, 평지, 강이 포함된 63×126 맵.
static func example_map_data() -> Dictionary:
	var tiles: Dictionary = {}
	var w := 63
	var hh := 126

	# 1. 노이즈 기반 높이맵
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.04
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 123

	for x in w:
		for y in hh:
			var raw: float = noise.get_noise_2d(x, y)
			var height := clampi(roundi(abs(raw) * 5), 0, 5)
			if height <= 0:
				continue
			var terrain := 0  # GRASS
			if height >= 4:
				terrain = 4    # STONE (산 정상)
			elif height >= 3:
				terrain = 0 if rng.randi() % 3 != 0 else 4  # 섞음
			tiles["%d,%d" % [x, y]] = {"h": height, "t": terrain}

	# 2. 십자형 길 (PATH)
	var cy: int = hh / 2 - 2  # 61
	for x in range(10, 50):
		for yy in range(cy, cy + 3):
			tiles["%d,%d" % [x, yy]] = {"h": 1, "t": 2}
	var cx: int = w / 2 - 1  # 30
	for y in range(20, 90):
		for xx in range(cx, cx + 2):
			tiles["%d,%d" % [xx, y]] = {"h": 1, "t": 2}

	# 3. 강 (고도 0 = 물 레이어, 굴곡 있게)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 456
	for y in range(30, 80):
		var river_width: int = 2 + (abs(y - 55) % 3)  # 2~4 타일 폭
		var offset: int = rng2.randi() % 3 - 1  # -1~1 굴곡
		var cx2: int = 16 + offset
		for x in range(cx2, cx2 + river_width):
			tiles["%d,%d" % [x, y]] = {"h": 0, "t": 3}  # t=3 = WATER

	# 4. 유적지 영역 표시 (STONE)
	for x in range(50, 55):
		for y in range(20, 25):
			var is_wall := (x == 50 or x == 54 or y == 20 or y == 24)
			var is_entrance := (x == 52 and y == 24)
			if is_wall and not is_entrance:
				tiles["%d,%d" % [x, y]] = {"h": 2 + (x + y) % 2, "t": 4}

	return {
		"width": w,
		"height": hh,
		"tiles": tiles,
	}


func _get_top(x: int, y: int, hm: Dictionary) -> Vector2i:
	var h: int = hm.get("%d,%d" % [x, y], 0)
	var key: String = "%d,%d" % [x, y]

	# 유적지 돌
	if h >= 2 and _is_ruins_area(x, y):
		hm["%s_moss" % key] = hm.get("%s_moss" % key, false)
		if hm.get("%s_moss" % key, _rng.randf() < 0.2):
			return T_MOSS
		return T_STONE

	if h >= 4:
		return T_STONE  # 산 정상 = 돌

	# 높이에 따라 윗면 색상 변화 (col 6=DARK_GRASS, col 7=ROCKY)
	if h >= 3:
		return Vector2i(7, 0)  # rocky top (col 7, 예비 슬롯 → DIRT 계열)
	if h == 2:
		return Vector2i(6, 0)  # darker grass (col 6, 예비 슬롯 → 어두운 녹색)

	if _is_path(x, y):
		return T_PATH
	return T_GRASS


func _get_side(x: int, y: int, hm: Dictionary, _is_top_level: int) -> Vector2i:
	var h: int = hm.get("%d,%d" % [x, y], 0)

	# 유적지 돌 옆면
	if _is_ruins_area(x, y) and h > 0:
		if _rng.randf() < 0.5:
			return T_STONE_L
		return T_STONE_R

	# 높이별 옆면 색상
	if h >= 4:
		return Vector2i(4, 1)  # STONE_L
	if h == 3:
		return Vector2i(7, 1)  # ROCKY_SIDE
	if h == 2:
		return Vector2i(6, 1)  # DARK_GRASS_SIDE
	return Vector2i(0, 1)  # GRASS_SIDE


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


## 물 타일 (col 3 = 1행, col 0~1 = 3행)
func _draw_diamond_water(img: Image, col: int, row: int = 0, base_color := Color(0.2, 0.4, 0.7, 0.8)) -> void:
	var cx: int = col * TILE_W + TILE_W / 2
	var cy: int = row * TILE_H + TILE_H / 2
	var rng := RandomNumberGenerator.new()
	rng.seed = col * 999 + row
	for py: int in range(TILE_H):
		for px: int in range(TILE_W):
			var nx: float = (px - TILE_W / 2.0) / (TILE_W / 2.0)
			var ny: float = (py - TILE_H / 2.0) / (TILE_H / 2.0)
			if abs(nx) + abs(ny) <= 1.0:
				var c: Color = base_color
				if rng.randf() < 0.15:
					c = c.lerp(Color(0.4, 0.6, 0.9, 0.9), 0.3)
				img.set_pixel(cx - TILE_W / 2 + px, cy - TILE_H / 2 + py, c)
