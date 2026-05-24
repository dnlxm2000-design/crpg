# projectile.gd — Visual projectile that flies from attacker to target. 3D version.
extends Node3D

@export var flight_time: float = 0.3
@export var speed: float = 0.0
@export var projectile_color: Color = Color(1.0, 0.6, 0.1)

var _target: Node = null
var _hit: bool = false


func setup(from_pos: Vector3, to_pos: Vector3, _attacker: Node, target: Node) -> void:
	global_position = from_pos
	_target = target

	# Create a small colored sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = projectile_color
	mat.flags_unshaded = true
	mat.emission_enabled = true
	mat.emission = projectile_color
	mat.emission_energy_multiplier = 0.5

	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.1

	var sprite := MeshInstance3D.new()
	sprite.name = "ProjectileMesh"
	sprite.mesh = sphere
	sprite.material_override = mat
	add_child(sprite)

	var target_world: Vector3 = to_pos

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

	# Impact flash
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.8, 0.2, 0.6)
	flash_mat.flags_unshaded = true
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.8, 0.2)

	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.2
	flash_mesh.height = 0.05

	var flash := MeshInstance3D.new()
	flash.mesh = flash_mesh
	flash.material_override = flash_mat
	flash.position = Vector3(0, 0.05, 0)
	add_child(flash)

	var fade_tween := create_tween()
	fade_tween.tween_property(flash, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
	fade_tween.tween_callback(queue_free)
