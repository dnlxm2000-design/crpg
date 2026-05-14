# unit_movement.gd — Movement component for units (Stoneshard-inspired dual-mode).
# Attach as child of any Unit.
# 
# Real-time mode: follow path toward clicked destination via move_and_slide().
# Turn-based mode: move one tile per action, costs AP, snaps to grid.
extends Node

## Reference to GridWorld (injected via parent Unit or set manually).
@export var grid_world_path: NodePath = NodePath("/root/Main/GameLoop/GridWorld")

## Movement speed in pixels/second (real-time).
@export var move_speed: float = 120.0

## Turn-based AP cost per tile.
@export var ap_cost_per_tile: int = 1

## Is this unit currently moving along a path?
var is_moving: bool = false
## Current path (grid positions) to follow.
var path: Array = []
## Current target grid position for this step.
var _target_world: Vector2 = Vector2.ZERO
## Is movement locked (stun, paralysis)?
var is_locked: bool = false

var _grid_world = null
var _unit = null
var _tween = null


func _ready() -> void:
	_unit = get_parent()
	if not _unit:
		push_error("UnitMovement must have a parent")
		return

	if grid_world_path:
		var node = get_node(grid_world_path)
		if node:
			_grid_world = node
	if not _grid_world:
		_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")


## === REAL-TIME MODE ===

func get_grid_world():
	return _grid_world


## Navigate to a world position (real-time pathfinding).
## Finds path from current position to target via A*.
func navigate_to(target_world: Vector2) -> void:
	if is_locked or not _grid_world:
		return

	var from_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
	var to_grid: Vector2i = _grid_world.world_to_grid(target_world)

	# Don't path to same tile
	if from_grid == to_grid:
		return

	path = _grid_world.find_path_grid(from_grid, to_grid)
	if path.is_empty():
		return
	_grid_world.set_occupied(from_grid, null)
	is_moving = true
	_pop_next_path_point()


## Immediate stop.
func stop_moving() -> void:
	is_moving = false
	path.clear()
	if _tween and _tween.is_valid():
		_tween.kill()
	_target_world = Vector2.ZERO


## === TURN-BASED MODE ===

## Move one tile in a direction (turn-based, costs AP).
## Returns true if movement happened.
func move_one_tile(direction: Vector2i, unit_node = null) -> bool:
	if is_locked or not _grid_world:
		return false

	var current_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
	var target_grid: Vector2i = current_grid + direction

	if not _grid_world.is_walkable(target_grid):
		return false

	# Check AP cost (if caller provides AP-managed unit)
	if unit_node:
		if not _can_spend_ap(unit_node):
			return false
		_spend_ap(unit_node)

	# Snap to grid
	var target_world: Vector2 = _grid_world.grid_to_world(target_grid)

	# Update occupancy
	_grid_world.set_occupied(current_grid, null)
	_grid_world.set_occupied(target_grid, unit_node if unit_node else _unit)

	# Instant snap for turn-based mode
	_unit.global_position = target_world

	# Notify
	EventBus.unit_moved.emit(_unit, _grid_world.grid_to_world(current_grid), target_world)
	return true


## Skip/pass the current turn (Space in combat).
## Returns false if locked.
func skip_turn() -> bool:
	if is_locked:
		return false
	EventBus.unit_skipped_turn.emit(_unit)
	return true


## === INTERNAL ===

func _process(delta: float) -> void:
	if not is_moving or is_locked:
		return

	# Real-time: move toward current target
	if _target_world == Vector2.ZERO:
		is_moving = false
		return

	var dir: Vector2 = (_target_world - _unit.global_position)
	var dist: float = dir.length()
	if dist < 2.0:
		# Arrived at target
		_unit.global_position = _target_world
		_pop_next_path_point()
		return

	var velocity: Vector2 = dir.normalized() * move_speed
	var motion: Vector2 = velocity * delta
	if motion.length() > dist:
		motion = dir

	_unit.global_position += motion


func _pop_next_path_point() -> void:
	if path.is_empty():
		is_moving = false
		# Update occupancy at final position
		if _grid_world:
			var final_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
			_grid_world.set_occupied(final_grid, _unit)
		return

	var next_grid: Vector2i = path.pop_front()
	_target_world = _grid_world.grid_to_world(next_grid)


func _can_spend_ap(unit_node: Node) -> bool:
	var ap: int = unit_node.get("current_action_points")
	return ap != null and ap >= ap_cost_per_tile


func _spend_ap(unit_node: Node) -> void:
	if "current_action_points" in unit_node:
		unit_node.current_action_points -= ap_cost_per_tile
		EventBus.ap_changed.emit(unit_node)
