# terrain_manager.gd — 아이소메트릭 지형 렌더러 (TileMapLayer 기반).
# noise 고도 데이터로 3D 입체 지형 생성. TileMapLayer + 절차적 TileSet 사용.
extends TileMapLayer

## 지형 종류 (고도 기준)
enum TerrainType { WATER, LOWLAND, PLAIN, HILL }

## 지형별 색상 (윗면)
const TERRAIN_COLORS := {
	TerrainType.WATER: Color("#7fb3d5"),
	TerrainType.LOWLAND: Color("#a8d08d"),
	TerrainType.PLAIN: Color("#8dbe6d"),
	TerrainType.HILL: Color("#6b9e4a"),
}

## 타일셋 내 타일 인덱스 (atlas 좌표)
enum TileAtlas { TOP_0, TOP_1, TOP_2, TOP_3, SIDE_0, SIDE_1, SIDE_2, SIDE_3 }

const TILE_W: int = 64
const TILE_H: int = 32

var _grid_world: Node = null
var _source_id: int = 0


func _ready() -> void:
	_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")
	_build_tileset()
	generate_terrain()


## ─── TileSet 생성 ───

## 절차적 타일셋 생성. 각 지형마다 윗면/옆면 타일을 만든다.
## 2행 × 4열 아틀라스: 1행=윗면, 2행=옆면
func _build_tileset() -> void:
	var atlas_img := Image.create(TILE_W * 4, TILE_H * 2, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color.TRANSPARENT)

	# 각 타일별 텍스처를 아틀라스에 그림
	for type in range(TerrainType.size()):
		var top_color: Color = _get_color(type)
		var side_color: Color = top_color.darkened(0.4)

		# 윗면 (1행): 다이아몬드
		_draw_diamond(atlas_img, type * TILE_W + TILE_W / 2, TILE_H / 2, top_color)
		# 옆면 (2행): 절반 높이의 어두운 다이아몬드
		_draw_side(atlas_img, type * TILE_W + TILE_W / 2, TILE_H + TILE_H / 2, side_color)

	var atlas_tex := ImageTexture.create_from_image(atlas_img)

	# TileSet 구성
	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL

	var source := TileSetAtlasSource.new()
	source.texture = atlas_tex
	source.texture_region_size = Vector2i(TILE_W, TILE_H)

	# 윗면 타일 (atlas 좌표 1행)
	for type in range(TerrainType.size()):
		source.create_tile(Vector2i(type, 0), Vector2i(1, 1))

	# 옆면 타일 (atlas 좌표 2행)
	for type in range(TerrainType.size()):
		source.create_tile(Vector2i(type, 1), Vector2i(1, 1))

	tileset.add_source(source)

	# source_id 확인 (첫 번째 source = 0)
	for i in tileset.get_source_count():
		_source_id = tileset.get_source_id(i)
		break

	self.tile_set = tileset


## 타일 아틀라스에 다이아몬드 그리기
func _draw_diamond(img: Image, cx: int, cy: int, color: Color) -> void:
	for py in range(TILE_H):
		for px in range(TILE_W):
			var nx: float = (px - TILE_W / 2.0) / (TILE_W / 2.0)
			var ny: float = (py - TILE_H / 2.0) / (TILE_H / 2.0)
			if abs(nx) + abs(ny) <= 1.0:
				img.set_pixel(px, py, color)


## 타일 아틀라스에 옆면(절반 높이 아래쪽 절반) 그리기
func _draw_side(img: Image, cx: int, cy: int, color: Color) -> void:
	for py in range(TILE_H / 2, TILE_H):
		for px in range(TILE_W):
			var nx: float = (px - TILE_W / 2.0) / (TILE_W / 2.0)
			var ny: float = (py - TILE_H / 2.0) / (TILE_H / 2.0)
			if abs(nx) + abs(ny) <= 1.0:
				img.set_pixel(px, py, color)


## 지형 타입에 따른 색상 반환 (고도 기반)
func _get_color(type: int) -> Color:
	match type:
		TerrainType.WATER:   return TERRAIN_COLORS[TerrainType.WATER]
		TerrainType.LOWLAND: return TERRAIN_COLORS[TerrainType.LOWLAND]
		TerrainType.PLAIN:   return TERRAIN_COLORS[TerrainType.PLAIN]
		TerrainType.HILL:    return TERRAIN_COLORS[TerrainType.HILL]
	return Color.WHITE


## 고도값(0~2) → TerrainType 변환
func _height_to_type(h: int) -> int:
	match h:
		0: return TerrainType.WATER
		1: return TerrainType.LOWLAND
		2: return TerrainType.PLAIN
		_: return TerrainType.HILL


## 윗면 타일 ID
func _top_tile_id(type: int) -> Vector2i:
	return Vector2i(type, 0)


## 옆면 타일 ID  
func _side_tile_id(type: int) -> Vector2i:
	return Vector2i(type, 1)


## ─── 지형 생성 ───

func generate_terrain() -> void:
	if not tile_set or not _grid_world:
		return

	clear()

	var gw := _grid_world
	var w: int = gw.grid_width if "grid_width" in gw else 0
	var h: int = gw.grid_height if "grid_height" in gw else 0

	for y in range(h):
		for x in range(w):
			var pos := Vector2i(x, y)
			var elevation: int = gw.get_elevation(pos)
			var type: int = _height_to_type(elevation)

			# 윗면
			if elevation > 0:
				set_cell(pos, _source_id, _top_tile_id(type))

			# 옆면: 아래 타일(y+1)보다 높이가 높으면 절벽면
			var below_pos := Vector2i(x, y + 1)
			if gw.get_elevation(below_pos) < elevation:
				set_cell(below_pos, _source_id, _side_tile_id(type))
