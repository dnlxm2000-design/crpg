extends Camera3D

var _target: Node3D
const OFFSET_Y: float = 6.0

@export var zoom_min: float = 4.0
@export var zoom_max: float = 20.0
@export var zoom_speed: float = 1.0

func _ready() -> void:
	_target = get_meta("follow_target", null)

func _process(_delta: float) -> void:
	if _target and is_instance_valid(_target):
		position = Vector3(_target.global_position.x, OFFSET_Y, _target.global_position.z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			size = max(size - zoom_speed, zoom_min)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			size = min(size + zoom_speed, zoom_max)
			get_viewport().set_input_as_handled()
