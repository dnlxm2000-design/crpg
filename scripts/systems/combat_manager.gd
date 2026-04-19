extends Node

signal turn_started(character: Node)
signal turn_ended(character: Node)
signal combat_ended(victory: bool)
signal initiative_resolved(participants: Array)

enum CombatPhase { INIT, SURPRISE_CHECK, INITIATIVE, PLAYER_TURN, ENEMY_TURN, RESOLUTION }

var current_phase: CombatPhase = CombatPhase.INIT
var participants: Array = []
var current_turn: int = 0
var is_surprise_round: bool = false
var combat_log: Array = []

func _ready():
	add_to_group("combat_systems")

func start_combat(party: Array, enemies: Array, _surprise_info: Dictionary = {}):
	participants.clear()
	participants.append_array(party)
	participants.append_array(enemies)
	is_surprise_round = true
	print("Combat started")
	_initiative_order()

func _initiative_order():
	for p in participants:
		if p.has_method("roll_initiative"):
			p.roll_initiative()
	participants.sort_custom(func(a, b): return a.initiative > b.initiative)
	initiative_resolved.emit(participants)
	print("Initiative resolved")

func next_turn():
	current_turn += 1
	if current_turn >= participants.size():
		current_turn = 0
		_cycle_round()
	var current_char = participants[current_turn]
	if current_char.is_in_group("players"):
		current_phase = CombatPhase.PLAYER_TURN
		turn_started.emit(current_char)
	else:
		current_phase = CombatPhase.ENEMY_TURN
		_process_enemy_turn(current_char)

func _cycle_round():
	for p in participants:
		if p.has_method("on_round_start"):
			p.on_round_start()

func _process_enemy_turn(enemy: Node):
	if enemy.has_method("take_ai_turn"):
		enemy.take_ai_turn()
	turn_ended.emit(enemy)
	next_turn()

func check_combat_end() -> bool:
	var players_alive = false
	var enemies_alive = false
	for p in participants:
		if p.is_in_group("players") and p.current_hp > 0:
			players_alive = true
		elif p.is_in_group("enemies") and p.current_hp > 0:
			enemies_alive = true
	if not players_alive:
		combat_ended.emit(false)
		return true
	if not enemies_alive:
		combat_ended.emit(true)
		return true
	return false

func add_log(message: String):
	combat_log.append(message)
	print(message)
