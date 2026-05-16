# turn_manager.gd — Speed-based turn queue with action points and phases.
class_name TurnManager
extends Node

## Emitted when any combatant's turn begins.
signal turn_started(combatant: Node)
## Emitted when a combatant's turn ends.
signal turn_ended(combatant: Node)
## Emitted when a full round completes.
signal round_ended(round_number: int)

## All combatants in the battle.
var combatants: Array[Node] = []
## Turn order for the current round (sorted by speed).
var turn_order: Array[Node] = []
## Index into turn_order for the current actor.
var current_turn_index: int = 0
## Current round number.
var current_round: int = 0
## Is combat active?
var is_combat_active: bool = false


func _ready() -> void:
	# Connect to player turn end (Stoneshard: player acts → enemies react)
	EventBus.player_ended_turn.connect(_on_player_ended_turn)
	# Track unit deaths for combat end detection
	EventBus.unit_destroyed.connect(_on_unit_destroyed)


func start_combat(participants: Array[Node] = []) -> void:
	if participants.size() > 0:
		combatants = participants
	elif combatants.size() == 0:
		push_warning("TurnManager: no combatants to start combat.")
		return

	# Snap all combatants to grid on combat start
	var grid = get_node_or_null("/root/Main/GameLoop/GridWorld")
	if grid and grid.has_method("set_occupied"):
		for c in combatants:
			var gp: Vector2i = grid.world_to_grid(c.global_position)
			grid.set_occupied(gp, c)

	is_combat_active = true
	current_round = 0
	current_turn_index = 0
	EventBus.combat_started.emit(combatants)
	_start_new_round()


func end_combat() -> void:
	if not is_combat_active:
		return  # 이미 종료됨 (중복 호출 방지)
	is_combat_active = false
	EventBus.combat_ended.emit()


func add_combatant(unit: Node) -> void:
	if unit not in combatants:
		combatants.append(unit)


func remove_combatant(unit: Node) -> void:
	combatants.erase(unit)


func _start_new_round() -> void:
	if not is_combat_active:
		return
	current_round += 1
	_calculate_turn_order()
	current_turn_index = 0
	EventBus.round_started.emit(current_round)
	_start_current_turn()


func _calculate_turn_order() -> void:
	# Agility-based initiative로 정렬.
	turn_order = combatants.duplicate()
	turn_order.sort_custom(
		func(a: Node, b: Node) -> bool:
			var init_a: int = a.get_initiative() if a.has_method("get_initiative") else (a.get("speed") if "speed" in a else 0)
			var init_b: int = b.get_initiative() if b.has_method("get_initiative") else (b.get("speed") if "speed" in b else 0)
			if init_a == init_b:
				var agi_a: int = a.get("agility") if "agility" in a else 0
				var agi_b: int = b.get("agility") if "agility" in b else 0
				return agi_a > agi_b
			return init_a > init_b
	)
	EventBus.turn_order_changed.emit(turn_order)


func _start_current_turn() -> void:
	if turn_order.size() == 0:
		return

	if current_turn_index >= turn_order.size():
		EventBus.round_ended.emit(current_round)
		_start_new_round()
		return

	var current = turn_order[current_turn_index]
	if not is_instance_valid(current) or not current.get("is_alive"):
		turn_order.remove_at(current_turn_index)
		_start_current_turn()
		return

	# Reset action points at turn start
	if "current_action_points" in current:
		var max_ap = 3 if not "max_action_points" in current else current.max_action_points
		current.current_action_points = max_ap

	EventBus.turn_started.emit(current)


## Call this when the current actor finishes their turn.
func end_current_turn() -> void:
	if not is_combat_active or turn_order.size() == 0:
		return

	var current = turn_order[current_turn_index]
	EventBus.turn_ended.emit(current)
	current_turn_index += 1
	_start_current_turn()


## Call this when an actor performs an action to deduct AP.
func perform_action(actor: Node, cost: int) -> bool:
	if "current_action_points" not in actor:
		return false
	if actor.current_action_points < cost:
		return false
	actor.current_action_points -= cost
	return true


## Listen for a unit dying during combat.
func _on_unit_destroyed(unit: Node) -> void:
	if not is_combat_active:
		return

	remove_combatant(unit)

	# Check remaining combatants for victory/defeat
	var has_players := false
	var has_enemies := false
	for c in combatants:
		if not is_instance_valid(c):
			continue
		if c.get("is_player"):
			has_players = true
		else:
			has_enemies = true

	if not has_enemies:
		EventBus.combat_victory.emit()
		end_combat()
		return

	if not has_players:
		EventBus.combat_defeat.emit()
		end_combat()


## Listen for player ending their turn (Stoneshard: player moves/skips → next).
func _on_player_ended_turn(unit: Node) -> void:
	# Only process if this unit is the current combatant
	if turn_order.size() > 0 and turn_order[current_turn_index] == unit:
		end_current_turn()
