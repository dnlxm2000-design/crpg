# grid_background.gd — Color-only checkerboard floor grid (no art assets).
extends Node2D

const TILE_SIZE := 32
const GRID_W := 64
const GRID_H := 64


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	for x in GRID_W:
		for y in GRID_H:
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var is_dark: bool = ((x + y) % 2 == 0)
			var color := Color(0.18, 0.18, 0.2) if is_dark else Color(0.22, 0.22, 0.24)
			draw_rect(rect, color)
