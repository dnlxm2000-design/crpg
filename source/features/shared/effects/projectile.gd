# projectile.gd — Visual projectile that flies from attacker to target.
# Used by EnemyAI for ranged attacks. Self-destructs after animation.
extends Node2D

## How long the projectile takes to reach target (seconds).
@export var flight_time: float = 0.3

## Travel speed (pixels/sec). Overrides flight_time if > 0.
@export var speed: float = 0.0

## Color of the projectile sprite.
@export var projectile_color: Color = Color(1.0, 0.6, 0.1)

var _target: Node = null
var _hit: bool = false


func setup(from_pos: Vector2, to_pos: Vector2, _attacker: Node, target: Node) -> void:
	global_position = from_pos
	_target = target

	# Create a small colored arrow/bullet sprite
	var sprite := Sprite2D.new()
	sprite.name = "ProjectileSprite"
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(projectile_color)
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = true
	add_child(sprite)

	# Determine target world position
	var target_world: Vector2 = to_pos

	# Animate toward target
	var tween := create_tween()
	tween.set_parallel(false)

	var dist: float = global_position.distance_to(target_world)
	var duration: float = flight_time
	if speed > 0:
		duration = dist / speed

	tween.tween_property(self, "global_position", target_world, duration)
	tween.tween_callback(_on_arrived)


func _on_arrived() -> void:
	if _hit:
		return
	_hit = true

	# Small impact flash
	var flash := Sprite2D.new()
	var flash_img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	flash_img.fill(Color(1.0, 0.8, 0.2, 0.6))
	flash.texture = ImageTexture.create_from_image(flash_img)
	flash.centered = true
	flash.modulate = Color(1.0, 1.0, 1.0, 0.8)
	add_child(flash)

	var fade_tween := create_tween()
	fade_tween.tween_property(flash, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
	fade_tween.tween_callback(queue_free)
