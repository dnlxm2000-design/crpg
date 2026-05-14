# state.gd — Base class for all states in the finite state machine.
# Each state encapsulates behavior for one mode of operation.
class_name State
extends Node

## Reference to the state machine owner — set automatically on enter.
var state_machine: StateMachine = null


## Called when this state becomes active.
func enter(_prev_state: State = null) -> void:
	pass


## Called when this state is deactivated.
func exit() -> void:
	pass


## Called every frame while this state is active (_process).
func update(_delta: float) -> void:
	pass


## Called every physics frame while this state is active (_physics_process).
func physics_update(_delta: float) -> void:
	pass


## Called when an input event occurs while this state is active (_input).
func handle_input(_event: InputEvent) -> void:
	pass


## Convenience: transition to another state.
func transition_to(state_name: String) -> void:
	if state_machine:
		state_machine.change_state(state_name)
