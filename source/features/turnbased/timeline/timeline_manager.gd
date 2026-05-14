# timeline_manager.gd — ATB (Active Time Battle) timeline manager.
# Units accumulate speed toward a threshold. When they reach it, they get a turn.
# Supports haste/slow modifiers and turn interrupts.
class_name TimelineManager
extends Node

## Signal when a unit's turn is ready.
signal unit_ready(unit: Node)

## Threshold for taking a turn (e.g. 1000).
@export var turn_threshold: float = 1000.0

## All tracked units with their current timeline progress.
var _progress: Dictionary = {}  # Node → float
## Queue of units ready to act.
var _ready_queue: Array[Node] = []


## Register a unit on the timeline.
func register_unit(unit: Node, initial_progress: float = 0.0) -> void:
	_progress[unit] = initial_progress


## Remove a unit from the timeline.
func unregister_unit(unit: Node) -> void:
	_progress.erase(unit)
	_ready_queue.erase(unit)


## Called each tick (use _process or a custom timer).
func tick(delta: float) -> void:
	for unit in _progress.keys():
		if unit in _ready_queue:
			continue  # Already waiting for their turn.

		var speed = unit.get("speed", 100.0)
		var haste = unit.get("haste_multiplier", 1.0)
		_progress[unit] += speed * haste * delta

		if _progress[unit] >= turn_threshold:
			_progress[unit] -= turn_threshold
			_ready_queue.append(unit)
			unit_ready.emit(unit)


## Get the next unit waiting to act.
func pop_next_ready() -> Node:
	if _ready_queue.is_empty():
		return null
	return _ready_queue.pop_front()


func reset() -> void:
	_progress.clear()
	_ready_queue.clear()
