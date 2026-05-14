# turnbased_state.gd — Active when the game is in turn-based mode (combat, etc.).
class_name TurnbasedState
extends State

@onready var turn_manager: Node = $"../../TurnManager"


func enter(_prev_state: State = null) -> void:
	print("[TurnbasedState] Entered")
	EventBus.turn_mode_entered.emit()
	if turn_manager:
		turn_manager.start_combat()


func exit() -> void:
	print("[TurnbasedState] Exited")
	EventBus.turn_mode_exited.emit()
	if turn_manager:
		turn_manager.end_combat()


func update(_delta: float) -> void:
	pass
