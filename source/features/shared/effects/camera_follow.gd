extends Camera3D

## 3인칭 오빗 카메라 — 우클릭 드래그로 회전, 휠로 줌

var _target: Node3D

# Orbit state
var _yaw: float = 0.0       # 수평 회전각 (도)
var _pitch: float = 50.0    # 수직 각도 (도, 90=정수직)
var _distance: float = 14.0

# Orbit mouse state
var _orbiting: bool = false
var _last_mouse_pos: Vector2

@export var pitch_min: float = 15.0
@export var pitch_max: float = 85.0
@export var distance_min: float = 5.0
@export var distance_max: float = 25.0
@export var zoom_speed: float = 1.0
@export var orbit_sensitivity: float = 0.5


func _ready() -> void:
	_target = get_meta("follow_target", null)


func _process(_delta: float) -> void:
	if _target and is_instance_valid(_target):
		_update_camera()


func _update_camera() -> void:
	var rad_pitch := deg_to_rad(_pitch)
	var rad_yaw := deg_to_rad(_yaw)

	var offset := Vector3(
		sin(rad_yaw) * cos(rad_pitch),
		sin(rad_pitch),
		cos(rad_yaw) * cos(rad_pitch)
	)
	position = _target.global_position + offset * _distance
	look_at(_target.global_position, Vector3.UP)
	size = _distance * 0.5  # 오소그래픽 zoom = distance 기반


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_orbiting = true
					_last_mouse_pos = event.position
					get_viewport().set_input_as_handled()
				else:
					_orbiting = false
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_distance = max(_distance - zoom_speed, distance_min)
					_update_camera()
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_distance = min(_distance + zoom_speed, distance_max)
					_update_camera()
					get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _orbiting:
		_yaw -= event.relative.x * orbit_sensitivity
		_pitch = clamp(_pitch + event.relative.y * orbit_sensitivity, pitch_min, pitch_max)
		_update_camera()
		get_viewport().set_input_as_handled()
