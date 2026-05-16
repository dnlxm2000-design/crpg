# minimap_panel.gd — 완전 독립형 원형 미니맵 (CanvasLayer).
# 다른 UI 파일을 전혀 건드리지 않음. _enter_tree()에서 자동으로 뷰포트에 추가됨.
# 위치는 자식 Control의 anchor로 지정 (뷰포트 크기 변화에도 안정적).
extends CanvasLayer

const PANEL_W := 136
const PANEL_H := 176
const MAP_SIZE := 128
const GRID_W := 63
const GRID_H := 126
const PLAYER_DOT_R := 3

const COLOR_WATER := Color(0.15, 0.35, 0.65)
const COLOR_GRASS := Color(0.6, 0.76, 0.49)
const COLOR_PATH  := Color(0.82, 0.71, 0.55)
const COLOR_MOUNTAIN := Color(0.4, 0.4, 0.4)

var _bg: ColorRect = null
var _tex_rect: TextureRect = null
var _coord_label: Label = null
var _img: Image = null
var _tex: ImageTexture = null
var _heights: Dictionary = {}
var _player: Node = null
var _grid_world: Node = null


func _enter_tree() -> void:
	# 부모가 없으면 뷰포트 루트에 자동 추가 (완전 독립)
	if not get_parent():
		get_tree().root.add_child(self)


func _ready() -> void:
	layer = 100  # HUD 위에 렌더링

	# ── 전체 화면 컨테이너 (anchor 기반 위치 지정) ──
	var container := Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	# ── 우상단 패널 ──
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -PANEL_W - 8
	panel.offset_top = 8
	panel.offset_right = -8
	panel.offset_bottom = PANEL_H + 8

	# 패널 배경 스타일
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", bg_style)
	container.add_child(panel)

	# ── 원형 마스크 이미지 ──
	var circle_img := Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RGBA8)
	circle_img.fill(Color.TRANSPARENT)
	var c := MAP_SIZE / 2
	var r := MAP_SIZE / 2 - 1
	for px in MAP_SIZE:
		for py in MAP_SIZE:
			var d := Vector2(px - c, py - c)
			if d.length_squared() <= r * r:
				circle_img.set_pixel(px, py, Color.WHITE)
	var circle_tex := ImageTexture.create_from_image(circle_img)

	# ── 미니맵 이미지 ──
	_img = Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0.08, 0.08, 0.08))
	_tex = ImageTexture.create_from_image(_img)

	_tex_rect = TextureRect.new()
	_tex_rect.texture = _tex
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.size = Vector2(MAP_SIZE, MAP_SIZE)
	_tex_rect.position = Vector2(4, 4)
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_tex_rect)

	# ── 좌표 레이블 ──
	_coord_label = Label.new()
	_coord_label.position = Vector2(4, MAP_SIZE + 8)
	_coord_label.size = Vector2(MAP_SIZE, 18)
	_coord_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coord_label.add_theme_font_size_override("font_size", 13)
	_coord_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_coord_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	panel.add_child(_coord_label)

	# ── 데이터 수집 ──
	_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt:
		_player = rt.get("player_ref")

	_collect_terrain()
	_render()


func _collect_terrain() -> void:
	if not _grid_world or not _grid_world.has_method("get_elevation"):
		return
	for x in range(GRID_W):
		for y in range(GRID_H):
			_heights["%d,%d" % [x, y]] = _grid_world.get_elevation(Vector2i(x, y))


func _render() -> void:
	if not _img:
		return
	_img.fill(Color(0.08, 0.08, 0.08))
	var cx := MAP_SIZE / 2
	var cy := MAP_SIZE / 2
	var radius := cx - 1
	var sx: float = float(MAP_SIZE) / float(GRID_W)
	var sy: float = float(MAP_SIZE) / float(GRID_H)

	for x in range(GRID_W):
		for y in range(GRID_H):
			var h: int = _heights.get("%d,%d" % [x, y], 0)
			var color: Color
			if h <= 0:      color = COLOR_WATER
			elif h == 1:    color = COLOR_GRASS
			else:           color = COLOR_MOUNTAIN

			var px := int(float(x) * sx)
			var py := int(float(y) * sy)
			var dx := px - cx
			var dy := py - cy
			if dx * dx + dy * dy <= radius * radius:
				_img.set_pixel(px, py, color)

	_tex.update(_img)


func _process(_delta: float) -> void:
	if not _player or not _grid_world:
		return

	var wp := _player.global_position
	var gp: Vector2i = _grid_world.world_to_grid(wp)
	_coord_label.text = "x:%d  y:%d" % [gp.x, gp.y]

	_render()
	_draw_dot(gp)


func _draw_dot(gp: Vector2i) -> void:
	var sx: float = float(MAP_SIZE) / float(GRID_W)
	var sy: float = float(MAP_SIZE) / float(GRID_H)
	var px := int(float(gp.x) * sx)
	var py := int(float(gp.y) * sy)

	var cx := MAP_SIZE / 2
	var cy := MAP_SIZE / 2
	var dx := px - cx
	var dy := py - cy
	if dx * dx + dy * dy > (cx - 1) * (cx - 1):
		return

	for ox in range(-PLAYER_DOT_R, PLAYER_DOT_R + 1):
		for oy in range(-PLAYER_DOT_R, PLAYER_DOT_R + 1):
			if ox * ox + oy * oy <= PLAYER_DOT_R * PLAYER_DOT_R:
				var nx := px + ox
				var ny := py + oy
				if nx >= 0 and nx < MAP_SIZE and ny >= 0 and ny < MAP_SIZE:
					_img.set_pixel(nx, ny, Color(1.0, 0.2, 0.2))
	_tex.update(_img)
