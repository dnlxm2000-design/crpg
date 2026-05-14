# enemy_ai.gd — Simple Stoneshard-style enemy combat AI.
# Attach as child of any enemy Unit. Auto-acts when turn_started fires for its parent.
extends Node

## Maximum tiles the enemy will pathfind to reach target.
@export var aggro_range: int = 20
## Tiles the enemy can move per turn (separate from AP).
@export var move_range: int = 5

var _parent: Node = null
var _movement: Node = null
var _grid_world = null
var _connected: bool = false
var _parent_range: int = 1

# Fixed targeting — stick to same target until death.
var _target: Node = null
# Movement resource (separate resource from AP).
var _moves_remaining: int = 0


func _ready() -> void:
	_parent = get_parent()
	_movement = _parent.get_node_or_null("UnitMovement")
	if _movement:
		_grid_world = _movement.get_grid_world()
	_parent_range = _parent.get("attack_range") if "attack_range" in _parent else 1

	EventBus.turn_started.connect(_on_turn_started)
	_connected = true


func _exit_tree() -> void:
	if _connected:
		EventBus.turn_started.disconnect(_on_turn_started)
		_connected = false


func _on_turn_started(unit: Node) -> void:
	if unit != _parent:
		return
	if not _parent.is_alive:
		return
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
	var combatants: Array = turn_manager.combatants if turn_manager else []
	if combatants.is_empty():
		var root = get_tree().current_scene if get_tree() else null
		if root:
			combatants = _find_alive_players_recursive(root)

	for c in combatants:
		if not is_instance_valid(c):
			continue
		if not c.get("is_player") or not c.get("is_alive"):
			continue

		var c_pos: Vector2i = _grid_world.world_to_grid(c.global_position)
		var my_pos: Vector2i = _grid_world.world_to_grid(_parent.global_position)
		var dist: int = max(abs(c_pos.x - my_pos.x), abs(c_pos.y - my_pos.y))
		var hp: int = c.current_hp if "current_hp" in c else 99999
		var def_val: int = c.defense if "defense" in c else 99999

		candidates.append({
			node = c,
			hp = hp,
			defense = def_val,
			distance = dist,
		})

	if candidates.is_empty():
		return null

	candidates.sort_custom(_compare_candidate)

	return candidates[0].node


## Sort comparator: HP asc → defense asc → distance asc.
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
	var atk: int = _parent.get_attack()
	target.take_damage(atk, _parent)


func _ranged_attack(target: Node) -> void:
	if not is_instance_valid(target) or not target.get("is_alive"):
		return
	if not _parent or not is_instance_valid(_parent):
		return

	var atk: int = _parent.get_attack()
	target.take_damage(atk, _parent)

	var parent_pos: Vector2 = _parent.global_position
	var target_pos: Vector2 = target.global_position
	var scene = get_tree().current_scene if get_tree() else null
	if scene:
		var ProjScript = load("res://source/features/shared/effects/projectile.gd")
		if ProjScript:
			var proj = ProjScript.new()
			proj.setup(parent_pos, target_pos, _parent, target)
			scene.add_child(proj)

	print("[EnemyAI] %s ranged attacks %s for %d damage (range=%d)" % [
		_parent.get("unit_name") if "unit_name" in _parent else "Enemy",
		target.get("unit_name") if "unit_name" in target else "Target",
		atk, _parent_range])


func _end_turn() -> void:
	if _parent and is_instance_valid(_parent):
		EventBus.player_ended_turn.emit(_parent)
