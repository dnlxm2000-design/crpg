# grid_background.gd — 아이소메트릭 체커보드 타일 배경 (드로잉 전용, 아트 에셋 불필요).
# 다이아몬드 형태의 타일을 2:1 비율로 그린다.
extends Node2D

const TILE_W := 64  # grid_world.gd TILE_WIDTH_ISO와 일치
const TILE_H := 32  # grid_world.gd TILE_HEIGHT_ISO와 일치
const GRID_W := 64
const GRID_H := 64


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	for y in GRID_H:
		for x in GRID_W:
			# 다이아몬드 중앙 위치 (아이소메트릭)
			var cx: float = (x - y) * TILE_W / 2.0
			var cy: float = (x + y) * TILE_H / 2.0

			var top    := Vector2(cx,         cy - TILE_H / 2.0)
			var right  := Vector2(cx + TILE_W / 2.0, cy)
			var bottom := Vector2(cx,         cy + TILE_H / 2.0)
			var left   := Vector2(cx - TILE_W / 2.0, cy)

			var is_dark: bool = ((x + y) % 2 == 0)
			var color := Color(0.18, 0.18, 0.2) if is_dark else Color(0.22, 0.22, 0.24)

			draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), color)
