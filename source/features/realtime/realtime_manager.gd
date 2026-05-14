# realtime_manager.gd — Manages real-time game mode (exploration, live AI, physics).
# Stoneshard-style: continuous click-to-move, fluid exploration.
extends Node

## Is real-time mode currently active?
var active: bool = false

## All units in the real-time world.
var units: Array = []

## Reference to spawned player unit (for test/combat access).
var player_ref: Node = null

var _grid_world: Node = null


func _ready() -> void:
	_grid_world = get_node_or_null("../GameLoop/GridWorld")
	if not _grid_world:
		_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")


func enter() -> void:
	active = true
	print("[RealTimeManager] Real-time mode activated")


func exit() -> void:
	active = false
	print("[RealTimeManager] Real-time mode deactivated")


func register_unit(unit: Node) -> void:
	if unit not in units:
		units.append(unit)

	# Register on grid
	if _grid_world and _grid_world.has_method("set_occupied"):
		var grid_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)
		_grid_world.set_occupied(grid_pos, unit)


func unregister_unit(unit: Node) -> void:
	units.erase(unit)
	if _grid_world and _grid_world.has_method("set_occupied"):
		var grid_pos: Vector2i = _grid_world.world_to_grid(unit.global_position)
		_grid_world.set_occupied(grid_pos, null)


## Spawn the player unit at a given world position.
func spawn_player(at_position: Vector2) -> Node:
	var player = load("res://source/features/shared/unit.gd").new()
	player.unit_name = "Player"
	player.is_player = true
	player.max_hp = 100
	player.current_hp = 100
	player.speed = 12
	player.max_action_points = 4
	player.current_action_points = 4
	player.corpse_color = Color(0.15, 0.4, 0.7)  # Blue-tinted corpse
	player.global_position = at_position

	# Attach movement component (name "UnitMovement" for PlayerController lookup)
	var movement = load("res://source/features/shared/unit_movement.gd").new()
	movement.name = "UnitMovement"
	movement.move_speed = 120.0
	movement.ap_cost_per_tile = 1
	player.add_child(movement)

	# Attach player controller
	var controller = load("res://source/features/shared/player_controller.gd").new()
	controller.name = "PlayerController"
	player.add_child(controller)

	# Attach inventory component
	var inventory = load("res://source/features/shared/inventory/inventory.gd").new()
	inventory.name = "Inventory"
	player.add_child(inventory)

	# Visual: 다이아몬드 Sprite + CollisionShape
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 24)  # 다이아몬드와 유사한 충돌 영역
	collision.shape = shape
	player.add_child(collision)

	var sprite := Sprite2D.new()
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# 다이아몬드 모양으로 픽셀 채우기
	var color := Color(0.2, 0.6, 1.0)
	for px in 48:
		for py in 48:
			# 다이아몬드 경계: |x-24|/24 + |y-36|/12 <= 1 (y 기준점을 아래로)
			var nx: float = (px - 24) / 24.0
			var ny: float = (py - 36) / 12.0
			if abs(nx) + abs(ny) <= 1.0:
				img.set_pixel(px, py, color)
	var tex := ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.position = Vector2(0, -2)  # 타일 중앙 기준 위치 보정
	player.add_child(sprite)

	# Camera2D (follows player)
	var camera := Camera2D.new()
	camera.enabled = true
	player.add_child(camera)

	player.name = "PlayerUnit"
	add_child(player)

	player_ref = player
	register_unit(player)

	print("[RealTimeManager] Player spawned at %s" % at_position)
	return player
