# cube_draw.gd — 큐브 면을 _draw()로 직접 그림 (Polygon2D 대체)
extends Node2D

var top_y: float = 0.0
var wall_h: float = 0.0
var top_color: Color = Color.WHITE
var side_l_color: Color = Color.GRAY
var side_r_color: Color = Color.DIM_GRAY
var south_lower: bool = false
var east_lower: bool = false


func _draw() -> void:
	# 그림자
	var shadow_col := Color(0.0, 0.0, 0.0, 0.3)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30, 14), Vector2(0, 30),
		Vector2(30, 14), Vector2(0, -2),
	]), shadow_col)

	# 윗면
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, top_y), Vector2(28, top_y + 16),
		Vector2(0, top_y + 32), Vector2(-28, top_y + 16),
	]), top_color)

	# 왼쪽 벽면
	if wall_h > 0:
		if south_lower:
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, 16), Vector2(0, top_y + 32), Vector2(-28, 0),
			]), side_l_color)
		else:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-28, top_y + 16), Vector2(0, top_y + 32),
				Vector2(0, 16), Vector2(-28, 0),
			]), side_l_color)

	# 오른쪽 벽면
	if wall_h > 0:
		if east_lower:
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, 16), Vector2(0, top_y + 32), Vector2(28, 0),
			]), side_r_color)
		else:
			draw_colored_polygon(PackedVector2Array([
				Vector2(28, top_y + 16), Vector2(0, top_y + 32),
				Vector2(0, 16), Vector2(28, 0),
			]), side_r_color)
