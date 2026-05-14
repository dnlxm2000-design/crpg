# state_machine.gd — Generic finite state machine that manages named state nodes.
# States are child nodes of this node. Each state must extend State.
class_name StateMachine
extends Node

## Emitted when the state changes.
signal state_changed(current_state: State, previous_state: State)

## Name of the initial state to enter on _ready.
@export var initial_state: String = ""

## The currently active state.
var current_state: State = null
var _states: Dictionary = {}  # name → State


func _ready() -> void:
	# Collect all child states.
	for child in get_children():
		if child is State:
			var name_lower = child.name.to_lower()
			_states[name_lower] = child
			child.state_machine = self

	# Enter initial state.
	if initial_state.is_empty() and _states.size() > 0:
		var first_key = _states.keys()[0]
		change_state(first_key)
	elif initial_state in _states:
		change_state(initial_state)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


## Transition to a named state.
func change_state(state_name: String) -> void:
	var new_state_name = state_name.to_lower()
	if new_state_name not in _states:
		push_warning("StateMachine: state '%s' not found." % state_name)
		return

	var new_state = _states[new_state_name]
	if new_state == current_state:
		return

	var prev_state = current_state
	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter(prev_state)
	state_changed.emit(current_state, prev_state)


## Return a state node by name.
func get_state(state_name: String) -> State:
	return _states.get(state_name.to_lower())
