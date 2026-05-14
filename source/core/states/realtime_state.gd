# realtime_state.gd — Active when the game is in real-time mode.
class_name RealtimeState
extends State


func enter(_prev_state: State = null) -> void:
	print("[RealtimeState] Entered")
	EventBus.realtime_mode_entered.emit()


func exit() -> void:
	print("[RealtimeState] Exited")
	EventBus.realtime_mode_exited.emit()


func update(delta: float) -> void:
	# Global real-time update logic (enemy AI, day/night cycle, etc.)
	pass


func physics_update(delta: float) -> void:
	# Physics-based real-time simulation
	pass
