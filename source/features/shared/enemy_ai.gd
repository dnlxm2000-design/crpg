# enemy_ai.gd ??Enemy AI with patrol (realtime) + combat (turn-based).
# Attach as child of any enemy Unit.
# States: IDLE -> PATROL -> CHASE -> COMBAT -> DEAD
extends Node

@warning_ignore("shadowed_global_identifier")
const CombatResolver = preload("res://source/features/turnbased/combat_resolver.gd")
@warning_ignore("shadowed_global_identifier")
const ZocController = preload("res://source/features/turnbased/zoc_controller.gd")

## State Machine
const STATE_IDLE: int = 0
const STATE_PATROL: int = 1
const STATE_CHASE: int = 2
const STATE_COMBAT: int = 3
const STATE_DEAD: int = 4
var state: int = STATE_IDLE

## Patrol config
@export var patrol_radius: int = 5
@export var patrol_wait_sec: float = 2.0
@export var detect_range: int = 8

## Combat config
@export var aggro_range: int = 20
@export var move_range: int = 5

var _parent: Node = null
var _movement: Node = null
var _grid_world = null
var _connected: bool = false
var _parent_range: int = 1

# Targeting
var _target: Node = null
var _moves_remaining: int = 0

# Patrol state
var _patrol_center: Vector2i = Vector2i.ZERO
var _patrol_target: Vector2i = Vector2i.ZERO
var _wait_timer: float = 0.0
var _is_waiting: bool = false

# Realtime movement
var _move_timer: float = 0.0
var _move_interval: float = 0.5


func _ready() -> void:
	_parent = get_parent()
	_movement = _parent.get_node_or_null("UnitMovement")
	if _movement:
		_grid_world = _movement.get_grid_world()
	if "attack_range" in _parent:
		_parent_range = _parent.attack_range
	else:
		_parent_range = 1

	# Patrol center = spawn position
	if _grid_world:
		_patrol_center = _grid_world.world_to_grid(_parent.global_position)
		_patrol_target = _patrol_center

	# Connect turn-based signal
	EventBus.turn_started.connect(_on_turn_started)
	_connected = true

	# Start in patrol state
	state = STATE_PATROL


func _exit_tree() -> void:
	if _connected:
		EventBus.turn_started.disconnect(_on_turn_started)
		_connected = false


## Realtime update - called from RealtimeState.update()
func update(delta: float) -> void:
	if state == STATE_DEAD or state == STATE_COMBAT:
		return
	if not _grid_world or not _movement or not _parent.is_alive:
		return

	# Check for player detection
	var player = _find_nearest_player()
	if player:
		var my_pos = _grid_world.world_to_grid(_parent.global_position)
		var pl_pos = _grid_world.world_to_grid(player.global_position)
		var dist = max(abs(pl_pos.x - my_pos.x), abs(pl_pos.y - my_pos.y))
		if dist <= detect_range:
			_target = player
			state = STATE_CHASE
			return

	# Patrol behavior
	if _is_waiting:
		_wait_timer -= delta
		if _wait_timer <= 0:
			_is_waiting = false
			_pick_new_patrol_target()
		return

	_move_timer -= delta
	if _move_timer > 0:
		return
	_move_timer = _move_interval

	_move_toward_patrol_target()


func _move_toward_patrol_target() -> void:
	if not _grid_world or not _movement:
		return

	var my_pos = _grid_world.world_to_grid(_parent.global_position)
	if my_pos == _patrol_target:
		_is_waiting = true
		_wait_timer = patrol_wait_sec
		return

	var path = _grid_world.find_path_grid(my_pos, _patrol_target)
	if path.is_empty():
		# Direct step
		var diff = _patrol_target - my_pos
		@warning_ignore("confusable_local_declaration")
		var dir = _direction_toward(diff)
		_movement.move_one_tile(dir, null)
		return

	var next_step = path[0]
	var dir = next_step - my_pos
	_movement.move_one_tile(dir, null)


func _pick_new_patrol_target() -> void:
	if not _grid_world:
		return

	# Random point within patrol_radius
	var attempts = 20
	for i in range(attempts):
		var offset = Vector2i(randi_range(-patrol_radius, patrol_radius), randi_range(-patrol_radius, patrol_radius))
		var candidate = _patrol_center + offset
		if _grid_world.is_walkable(candidate, true):
			var occupant = _grid_world.get_occupant(candidate)
			if not occupant or occupant == _parent:
				_patrol_target = candidate
				return

	# Fallback: return to center
	_patrol_target = _patrol_center


func _find_nearest_player() -> Node:
	var root = get_tree().current_scene
	if not root:
		return null
	return _find_player_recursive(root)


func _find_player_recursive(node: Node) -> Node:
	if node.get("is_player") == true and node.get("is_alive"):
		return node
	for child in node.get_children():
		var result = _find_player_recursive(child)
		if result:
			return result
	return null


## Turn-based combat entry
func _on_turn_started(unit: Node) -> void:
	if unit != _parent:
		return
	if not _parent.is_alive:
		state = STATE_DEAD
		return

	state = STATE_COMBAT
	_moves_remaining = move_range
	act()


func act() -> void:
	if not _grid_world or not _movement or not _parent.is_alive:
		_end_turn()
		return

	var target = _pick_target()
	if not target:
		_end_turn()
		return

	var my_pos: Vector2i = _grid_world.world_to_grid(_parent.global_position)
	var target_pos: Vector2i = _grid_world.world_to_grid(target.global_position)
	var dist: int = max(abs(target_pos.x - my_pos.x), abs(target_pos.y - my_pos.y))

	if dist > aggro_range:
		_end_turn()
		return

	if dist <= _parent_range and dist > 0:
		if _has_ap(1):
			if dist <= 1:
				_attack_target(target)
			else:
				_ranged_attack(target)
			_spend_ap(1)
		_end_turn()
		return

	var safety: int = move_range + 5
	while _moves_remaining > 0 and safety > 0:
		safety -= 1

		my_pos = _grid_world.world_to_grid(_parent.global_position)
		target_pos = _grid_world.world_to_grid(target.global_position)
		dist = max(abs(target_pos.x - my_pos.x), abs(target_pos.y - my_pos.y))

		if dist <= _parent_range and dist > 0:
			if _has_ap(1):
				if dist <= 1:
					_attack_target(target)
				else:
					_ranged_attack(target)
				_spend_ap(1)
			break

		var move_target: Vector2i = target_pos
		if dist <= 3:
			var flank_pos = _pick_flank_position(my_pos, target_pos)
			if flank_pos != target_pos:
				move_target = flank_pos

		if not _move_along_path(my_pos, move_target):
			break

	_end_turn()


func _move_along_path(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	var path: Array[Vector2i] = _grid_world.find_path_grid(from_pos, to_pos)
	if path.is_empty():
		var diff: Vector2i = to_pos - from_pos
		@warning_ignore("confusable_local_declaration")
		var moved: bool = _movement.move_one_tile(_direction_toward(diff), null)
		if moved:
			_moves_remaining -= 1
		return moved

	var next_step: Vector2i = path[0]
	var dir: Vector2i = next_step - from_pos
	var moved: bool = _movement.move_one_tile(dir, null)
	if moved:
		_moves_remaining -= 1
	return moved


func _has_ap(cost: int) -> bool:
	if not "current_action_points" in _parent:
		return false
	return _parent.current_action_points >= cost


func _spend_ap(amount: int) -> void:
	if "current_action_points" in _parent:
		_parent.current_action_points -= amount
		EventBus.ap_changed.emit(_parent)


func _direction_toward(diff: Vector2i) -> Vector2i:
	var dx: int = 0
	var dy: int = 0
	if diff.x > 0:
		dx = 1
	elif diff.x < 0:
		dx = -1
	if diff.y > 0:
		dy = 1
	elif diff.y < 0:
		dy = -1
	return Vector2i(dx, dy)


func _pick_target() -> Node:
	if _target and is_instance_valid(_target) and _target.get("is_alive"):
		return _target
	_target = _find_best_target()
	return _target


func _find_best_target() -> Node:
	var candidates: Array = []

	var turn_manager = _parent.get_node_or_null("/root/Main/GameLoop/TurnManager")
	var combatants: Array = []
	if turn_manager:
		combatants = turn_manager.combatants
	if combatants.is_empty():
		var root = get_tree().current_scene
		if root:
			combatants = _find_alive_players_recursive(root)

	for candidate in combatants:
		if not is_instance_valid(candidate):
			continue
		if not candidate.get("is_player") or not candidate.get("is_alive"):
			continue

		var c_pos: Vector2i = _grid_world.world_to_grid(candidate.global_position)
		var my_pos: Vector2i = _grid_world.world_to_grid(_parent.global_position)
		var dist: int = max(abs(c_pos.x - my_pos.x), abs(c_pos.y - my_pos.y))
		var hp: int = 99999
		if "current_hp" in candidate:
			hp = candidate.current_hp
		var def_val: int = 99999
		if "defense" in candidate:
			def_val = candidate.defense

		var entry: Dictionary = {}
		entry["node"] = candidate
		entry["hp"] = hp
		entry["defense"] = def_val
		entry["distance"] = dist
		candidates.append(entry)

	if candidates.is_empty():
		return null

	candidates.sort_custom(_compare_candidate)
	return candidates[0].node


func _compare_candidate(a, b) -> bool:
	if a.hp != b.hp:
		return a.hp < b.hp
	if a.defense != b.defense:
		return a.defense < b.defense
	return a.distance < b.distance


func _pick_flank_position(my_pos: Vector2i, target_pos: Vector2i) -> Vector2i:
	var neighbors: Array = [
		target_pos + Vector2i(1, 0),
		target_pos + Vector2i(-1, 0),
		target_pos + Vector2i(0, 1),
		target_pos + Vector2i(0, -1),
	]

	var combatants = _get_combatants()
	var non_zoc_best: Vector2i = target_pos
	var non_zoc_dist: int = 999999

	for n in neighbors:
		if not _grid_world.is_walkable(n, true):
			continue
		var occupant = _grid_world.get_occupant(n)
		if occupant and occupant != _parent:
			continue
		if not ZocController.is_in_enemy_zoc(n, _parent, combatants, _grid_world):
			var d: int = max(abs(n.x - my_pos.x), abs(n.y - my_pos.y))
			if d < non_zoc_dist:
				non_zoc_dist = d
				non_zoc_best = n

	if non_zoc_best != target_pos:
		return non_zoc_best

	var best: Vector2i = target_pos
	var best_dist: int = 999999
	for n in neighbors:
		if not _grid_world.is_walkable(n, true):
			continue
		var occupant = _grid_world.get_occupant(n)
		if occupant and occupant != _parent:
			continue
		var d: int = max(abs(n.x - my_pos.x), abs(n.y - my_pos.y))
		if d < best_dist:
			best_dist = d
			best = n

	return best


func _find_alive_players_recursive(node: Node) -> Array:
	var result: Array = []
	if node.get("is_player") == true and node.get("is_alive"):
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_alive_players_recursive(child))
	return result


func _attack_target(target: Node) -> void:
	var atk_pos: Vector2i = Vector2i(0, 0)
	var tgt_pos: Vector2i = Vector2i(0, 0)
	if _grid_world:
		atk_pos = _grid_world.world_to_grid(_parent.global_position)
		tgt_pos = _grid_world.world_to_grid(target.global_position)
	var elv: int = 0
	if _grid_world and _grid_world.has_method("get_elevation"):
		elv = _grid_world.get_elevation(atk_pos) - _grid_world.get_elevation(tgt_pos)
	var back: bool = CombatResolver.is_back_attack(atk_pos, target)
	var cover: int = 0
	if _grid_world and _grid_world.has_method("calculate_cover"):
		cover = _grid_world.calculate_cover(atk_pos, tgt_pos, _parent, target)

	var result = CombatResolver.resolve_attack(_parent, target, 1, elv, back, cover)
	if not result[CombatResolver.KEY_HIT]:
		EventBus.unit_evaded.emit(target, _parent)
		return
	if result[CombatResolver.KEY_CRIT]:
		var e_name = "Enemy"
		if "unit_name" in _parent:
			e_name = _parent.unit_name
		var t_name = "Target"
		if "unit_name" in target:
			t_name = target.unit_name
		print("[Combat] Enemy CRIT! %s -> %s (%d dmg)" % [e_name, t_name, result[CombatResolver.KEY_DAMAGE]])


func _ranged_attack(target: Node) -> void:
	if not is_instance_valid(target) or not target.get("is_alive"):
		return
	if not _parent or not is_instance_valid(_parent):
		return

	var my_pos: Vector2i = Vector2i(0, 0)
	var tgt_pos: Vector2i = Vector2i(0, 0)
	if _grid_world:
		my_pos = _grid_world.world_to_grid(_parent.global_position)
		tgt_pos = _grid_world.world_to_grid(target.global_position)
	var dist: int = max(abs(tgt_pos.x - my_pos.x), abs(tgt_pos.y - my_pos.y))

	var elv: int = 0
	if _grid_world and _grid_world.has_method("get_elevation"):
		elv = _grid_world.get_elevation(my_pos) - _grid_world.get_elevation(tgt_pos)
	var back: bool = CombatResolver.is_back_attack(my_pos, target)
	var cover: int = 0
	if _grid_world and _grid_world.has_method("calculate_cover"):
		cover = _grid_world.calculate_cover(my_pos, tgt_pos, _parent, target)

	var result = CombatResolver.resolve_attack(_parent, target, max(dist, 1), elv, back, cover)
	if not result[CombatResolver.KEY_HIT]:
		EventBus.unit_evaded.emit(target, _parent)
		return
	if result[CombatResolver.KEY_CRIT]:
		@warning_ignore("confusable_local_declaration")
		var e_name = "Enemy"
		if "unit_name" in _parent:
			e_name = _parent.unit_name
		@warning_ignore("confusable_local_declaration")
		var t_name = "Target"
		if "unit_name" in target:
			t_name = target.unit_name
		print("[Combat] Enemy CRIT! %s -> %s (%d dmg at range %d)" % [e_name, t_name, result[CombatResolver.KEY_DAMAGE], dist])

	var parent_pos: Vector3 = _parent.global_position
	var target_pos: Vector3 = target.global_position
	var scene = get_tree().current_scene
	if scene:
		var ProjScript = load("res://source/features/shared/effects/projectile.gd")
		if ProjScript:
			var proj = ProjScript.new()
			scene.add_child(proj)
			proj.setup(parent_pos, target_pos, _parent, target)

	var e_name = "Enemy"
	if "unit_name" in _parent:
		e_name = _parent.unit_name
	var t_name = "Target"
	if "unit_name" in target:
		t_name = target.unit_name
	print("[EnemyAI] %s ranged attacks %s for %d damage (range=%d)" % [
		e_name, t_name, result[CombatResolver.KEY_DAMAGE], _parent_range])


func _get_combatants() -> Array:
	var tm = _parent.get_node_or_null("/root/Main/GameLoop/TurnManager")
	if tm:
		return tm.combatants
	return []


func _end_turn() -> void:
	if _parent and is_instance_valid(_parent):
		EventBus.player_ended_turn.emit(_parent)
