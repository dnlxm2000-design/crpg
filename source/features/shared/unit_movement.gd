# unit_movement.gd — Movement component for units (Stoneshard-inspired dual-mode).
# Attach as child of any Unit. 3D version.
#
# Real-time mode: follow path toward clicked destination via move_and_slide().
# Turn-based mode: move one tile per action, costs AP, snaps to grid.
extends Node

const ZocController = preload("res://source/features/turnbased/zoc_controller.gd")

## Reference to GridWorld
@export var grid_world_path: NodePath = NodePath("/root/Main/GameLoop/GridWorld")

## Movement speed in units/second (real-time).
@export var move_speed: float = 4.0

## Turn-based AP cost per tile.
@export var ap_cost_per_tile: int = 1

## Is this unit currently moving along a path?
var is_moving: bool = false
## 키보드 트윈 이동 중인가?
var is_tween_moving: bool = false
## Current path (grid positions) to follow.
var path: Array = []
## Current target world position for this step.
var _target_world: Vector3 = Vector3.ZERO
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
func navigate_to(target_world: Vector3) -> void:
	if is_locked or not _grid_world:
		return

	# 키보드 트윈이 진행 중이면 취소
	if _tween and _tween.is_valid():
		_tween.kill()

	var from_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
	var to_grid: Vector2i = _grid_world.world_to_grid(target_world)

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
	is_tween_moving = false
	path.clear()
	if _tween and _tween.is_valid():
		_tween.kill()
	_target_world = Vector3.ZERO


## === TURN-BASED MODE ===

## Move one tile in a direction (turn-based, costs AP).
## Returns true if movement happened.
func move_one_tile(direction: Vector2i, unit_node = null) -> bool:
	if is_locked or not _grid_world:
		return false

	# 진행 중인 경로 이동 취소
	if is_moving:
		stop_moving()

	var current_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
	var target_grid: Vector2i = current_grid + direction
	var target_ok: bool = _grid_world.is_walkable(target_grid)
	# 3D: XZ 평면 방향 벡터
	var dir_vec: Vector3 = Vector3(direction.x, 0, direction.y).normalized()

	# 항상 방향 전환
	if "update_facing_direction" in _unit:
		_unit.update_facing_direction(dir_vec)

	if not target_ok:
		return false

	# AP 확인 (turn-based)
	if unit_node:
		if not _can_spend_ap(unit_node):
			return false
		
		var combatants = _get_combatants()
		var zoc_extra: int = ZocController.get_extra_ap_cost(unit_node, target_grid, combatants, _grid_world)
		var ap_available: int = unit_node.get("current_action_points") if "current_action_points" in unit_node else 0
		if ap_available < ap_cost_per_tile + zoc_extra:
			return false
		
		_spend_ap(unit_node)
		_zoc_spend_extra_ap(unit_node, zoc_extra)

	# 이동 실행
	var target_world: Vector3 = _grid_world.grid_to_world(target_grid)
	target_world.y = _get_terrain_height_at(target_world)
	var from_grid: Vector2i = current_grid

	# 그리드 점유는 즉시 업데이트
	_grid_world.set_occupied(current_grid, null)
	_grid_world.set_occupied(target_grid, unit_node if unit_node else _unit)

	# 시각적 이동은 트윈 애니메이션 (0.08s)
	if _tween and _tween.is_valid():
		_tween.kill()
	is_tween_moving = true
	_tween = create_tween()
	_tween.tween_property(_unit, "global_position", target_world, 0.08).set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(_on_move_tween_finished)

	EventBus.unit_moved.emit(_unit, _grid_world.grid_to_world(current_grid), target_world)

	if unit_node:
		_trigger_attack_of_opportunity(unit_node, from_grid, target_grid)

	return true


## 바라보는 방향으로 밀치기 시도
func try_push_facing(unit_node: Node) -> bool:
	if is_locked or not _grid_world or not unit_node:
		return false

	var facing_dir: Vector3 = unit_node.get("facing_direction") if "facing_direction" in unit_node else Vector3(0, 0, 1)
	var dir_vec: Vector3 = facing_dir.normalized()
	var direction: Vector2i = Vector2i(roundi(dir_vec.x), roundi(dir_vec.z))
	if direction == Vector2i.ZERO:
		return false

	var from_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
	var target_grid: Vector2i = from_grid + direction

	var occupant = _grid_world.get_occupant(target_grid)
	if not occupant or occupant == _unit or not (occupant.get("is_alive") if "is_alive" in occupant else false):
		return false

	return _execute_push(unit_node, occupant, from_grid, direction, dir_vec)


## 밀치기 실행 (내부).
func _execute_push(pusher: Node, pushed: Node, from_grid: Vector2i, direction: Vector2i, dir_vec: Vector3) -> bool:
	var push_target: Vector2i = from_grid + direction + direction

	if not _grid_world.is_walkable(push_target):
		return false
	var push_occupant = _grid_world.get_occupant(push_target)
	if push_occupant and push_occupant != _unit and push_occupant != pushed:
		return false

	var ap_cost: int = ap_cost_per_tile + 1
	var ap = pusher.get("current_action_points") if "current_action_points" in pusher else 0
	if ap < ap_cost:
		return false
	pusher.current_action_points -= ap_cost
	EventBus.ap_changed.emit(pusher)

	if "update_facing_direction" in pushed:
		pushed.update_facing_direction(-dir_vec)
	var push_world = _grid_world.grid_to_world(push_target)
	push_world.y = _get_terrain_height_at(push_world)
	pushed.global_position = push_world

	_grid_world.set_occupied(from_grid, null)
	var enemy_old_grid: Vector2i = from_grid + direction
	_grid_world.set_occupied(enemy_old_grid, null)
	_grid_world.set_occupied(push_target, pushed)
	_grid_world.set_occupied(enemy_old_grid, pusher)

	var swap_world = _grid_world.grid_to_world(enemy_old_grid)
	swap_world.y = _get_terrain_height_at(swap_world)
	_unit.global_position = swap_world

	EventBus.unit_moved.emit(pusher, _grid_world.grid_to_world(from_grid), _grid_world.grid_to_world(enemy_old_grid))
	EventBus.unit_moved.emit(pushed, _grid_world.grid_to_world(enemy_old_grid), _grid_world.grid_to_world(push_target))

	print("[Push] %s pushes %s from %s to %s" % [
		pusher.get("unit_name") if "unit_name" in pusher else "?",
		pushed.get("unit_name") if "unit_name" in pushed else "?",
		str(enemy_old_grid), str(push_target)])

	return true


## Skip/pass the current turn (Space in combat).
func skip_turn() -> bool:
	if is_locked:
		return false
	EventBus.unit_skipped_turn.emit(_unit)
	return true


## === INTERNAL ===

func _process(delta: float) -> void:
	if not is_moving or is_locked:
		return

	if _target_world == Vector3.ZERO:
		is_moving = false
		return

	var dir: Vector3 = (_target_world - _unit.global_position)
	var dist: float = dir.length()
	if dist < 0.1:
		_unit.global_position = _target_world
		_pop_next_path_point()
		return

	if "update_facing_direction" in _unit and dir.length() > 0.1:
		_unit.update_facing_direction(dir.normalized())

	var velocity: Vector3 = dir.normalized() * move_speed
	var motion: Vector3 = velocity * delta
	if motion.length() > dist:
		motion = dir

	_unit.global_position += motion

	# 경로 이동 중 통과 불가 타일에 진입했는지 체크
	if _grid_world and _grid_world.has_method("is_walkable"):
		var current_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
		if not _grid_world.is_walkable(current_grid):
			_unit.global_position -= motion
			stop_moving()


## 현재 모드가 턴제인지 확인.
func _is_turn_mode() -> bool:
	return GameState.current_mode == GameState.GameMode.TURNBASED


func _pop_next_path_point() -> void:
	if path.is_empty():
		is_moving = false
		if _grid_world:
			var final_grid: Vector2i = _grid_world.world_to_grid(_unit.global_position)
			_grid_world.set_occupied(final_grid, _unit)
		return

	var next_grid: Vector2i = path.pop_front()
	_target_world = _grid_world.grid_to_world(next_grid)
	_target_world.y = _get_terrain_height_at(_target_world)


func _on_move_tween_finished() -> void:
	is_tween_moving = false


func _can_spend_ap(unit_node: Node) -> bool:
	var ap: int = unit_node.get("current_action_points")
	return ap != null and ap >= ap_cost_per_tile


func _spend_ap(unit_node: Node) -> void:
	if "current_action_points" in unit_node:
		unit_node.current_action_points -= ap_cost_per_tile
		EventBus.ap_changed.emit(unit_node)


## Terrain 높이 조회.
func _get_terrain_height_at(world_pos: Vector3) -> float:
	var terrain := get_node_or_null("/root/Main/Terrain")
	if terrain and terrain.has_method("get_height_at"):
		return terrain.get_height_at(world_pos)
	return world_pos.y


## TurnManager에서 현재 전투원 목록을 가져온다.
func _get_combatants() -> Array:
	var tm = get_node_or_null("/root/Main/GameLoop/TurnManager")
	if not tm:
		var scene_root = get_tree().current_scene
		if scene_root:
			tm = scene_root.find_child("TurnManager", true, false)
	return tm.combatants if tm else []


## ZOC 추가 AP 소모 처리.
func _zoc_spend_extra_ap(unit_node: Node, amount: int) -> void:
	if amount <= 0:
		return
	if "current_action_points" in unit_node:
		unit_node.current_action_points -= amount
		EventBus.ap_changed.emit(unit_node)


## ZOC Attack of Opportunity 확인 및 실행.
func _trigger_attack_of_opportunity(unit_node: Node, from_tile: Vector2i, to_tile: Vector2i) -> void:
	var combatants = _get_combatants()
	if combatants.is_empty():
		return

	var attackers = ZocController.get_attack_of_opportunity_attackers(
		unit_node, from_tile, to_tile, combatants, _grid_world
	)
	for attacker in attackers:
		var a_alive: bool = attacker.get("is_alive") if "is_alive" in attacker else true
		if is_instance_valid(attacker) and a_alive:
			ZocController.execute_attack_of_opportunity(attacker, unit_node)
