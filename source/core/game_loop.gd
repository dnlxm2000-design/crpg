# game_loop.gd — Orchestrates real-time ↔ turn-based mode switching.
# This is the top-level controller. Attach as Autoload "GameLoop" or
# as the main scene's root script.
extends Node

## Emitted when the game mode changes.
signal mode_changed(mode: String)

## Current mode state machine
var mode_state_machine: StateMachine = null

## Are we currently in turn-based mode?
var is_turn_mode: bool = false

## Guard against rapid C-key double-trigger
var _entering_combat: bool = false


func _ready() -> void:
	mode_state_machine = $ModeStateMachine
	if not mode_state_machine:
		push_error("GameLoop requires a ModeStateMachine child node.")
		return

	# Connect to mode-specific signals via EventBus
	EventBus.realtime_mode_entered.connect(_on_realtime_entered)
	EventBus.turn_mode_entered.connect(_on_turn_entered)
	# Combat outcome handlers
	EventBus.combat_victory.connect(_on_combat_victory)
	EventBus.combat_defeat.connect(_on_combat_defeat)


## Switch to real-time mode.
func enter_realtime() -> void:
	if mode_state_machine:
		mode_state_machine.change_state("realtime")
		is_turn_mode = false
		GameState.current_mode = GameState.GameMode.REALTIME
		mode_changed.emit("realtime")
		EventBus.game_mode_changed.emit("realtime")


## Switch to turn-based mode (for combat, etc.).
func enter_turn_mode() -> void:
	if mode_state_machine:
		mode_state_machine.change_state("turnbased")
		is_turn_mode = true
		GameState.current_mode = GameState.GameMode.TURNBASED
		mode_changed.emit("turnbased")
		EventBus.game_mode_changed.emit("turnbased")


## Request combat entry from player input (C key).
## Spawns test enemies, registers combatants, enters turn-based mode.
func request_combat_entry(player: Node) -> void:
	if is_turn_mode or _entering_combat:
		return  # Already in combat or transitioning
	if not player or not is_instance_valid(player):
		return
	
	_entering_combat = true
	
	var grid = $GridWorld
	if not grid:
		push_error("GameLoop: GridWorld not found for combat entry")
		_entering_combat = false
		return
	
	# Spawn 2 test enemies near the player
	var turn_manager = $TurnManager
	var enemies = _spawn_test_enemies(player, grid)
	
	turn_manager.add_combatant(player)
	for e in enemies:
		turn_manager.add_combatant(e)
	
	enter_turn_mode()
	_entering_combat = false


## Spawn enemy units near player for testing combat.
## Creates 2 melee enemies (closer) + 1 ranged enemy (further).
func _spawn_test_enemies(player: Node, grid: Node) -> Array:
	var enemies: Array = []
	var player_gp: Vector2i = grid.world_to_grid(player.global_position)
	
	# ── Melee goblins (index 0, 1) ──
	var melee_data = [
		{offset = Vector2i(3, 0),  name = "Goblin", speed = 8,  color = Color(0.3, 0.7, 0.2)},
		{offset = Vector2i(0, 3),  name = "Warrior", speed = 6,  color = Color(0.25, 0.6, 0.15)},
	]
	# Load potion for enemy drops
	var health_potion_res = load("res://source/data/items/resources/health_potion.tres")
	# ── Goblin Archer (index 2) ──
	var ranged_data = [
		{offset = Vector2i(-4, -2), name = "Goblin Archer", speed = 10, color = Color(0.35, 0.55, 0.15)},
	]
	
	# Combine: melee first, then ranged
	var spawn_data = melee_data + ranged_data
	
	for i in range(spawn_data.size()):
		var data = spawn_data[i]
		var enemy = load("res://source/features/shared/unit.gd").new()
		enemy.unit_name = data.name
		enemy.is_player = false
		enemy.max_hp = 30
		enemy.current_hp = 30
		enemy.speed = data.speed
		enemy.max_action_points = 3
		enemy.current_action_points = 3
		enemy.attack = 5
		enemy.defense = 2
		enemy.corpse_color = Color(data.color.r * 0.4, data.color.g * 0.3, data.color.b * 0.3)

		# Melee_2 drops a health potion
		if i == 1 and health_potion_res:
			enemy.item_drops = [{item = health_potion_res, chance = 1.0}]

		# Ranged enemy: higher attack, longer range, drops gold
		if i >= melee_data.size():
			enemy.attack_range = 3
			enemy.attack = 8
			enemy.gold_drop = 15  # Ranged enemy drops gold on death
		
		var spawn_gp = player_gp + data.offset
		enemy.global_position = grid.grid_to_world(spawn_gp)
		
		# Attach movement for grid registration
		var movement = load("res://source/features/shared/unit_movement.gd").new()
		movement.name = "UnitMovement"
		enemy.add_child(movement)

		# Attach EnemyAI for turn-based combat behavior
		var ai = load("res://source/features/shared/enemy_ai.gd").new()
		ai.name = "EnemyAI"
		enemy.add_child(ai)
		
		# Visual: Placeholder 사각형 (나중에 SpriteSheet로 교체)
		enemy.setup_placeholder_visual(data.color)

		# Register on grid
		if grid.has_method("set_occupied"):
			grid.set_occupied(spawn_gp, enemy)
		
		# Add to scene tree (GameLoop -> Main -> /root)
		get_parent().add_child(enemy)
		enemies.append(enemy)
	
	return enemies


## Pause/unpause all real-time processing (e.g. when menus open).
func set_paused(paused: bool) -> void:
	get_tree().paused = paused


func _on_combat_victory() -> void:
	print("[GameLoop] Combat victory — all enemies defeated")
	enter_realtime()


func _on_combat_defeat() -> void:
	print("[GameLoop] Combat defeat — player slain")
	# Show defeat panel with restart option
	var panel = load("res://source/ui/screens/defeat_panel.gd").new()
	panel.name = "DefeatPanel"
	panel.restart_requested.connect(_on_restart_requested)
	get_parent().add_child(panel)  # Add to /root/Main


## Restart the game scene after defeat.
func _on_restart_requested() -> void:
	print("[GameLoop] Restart requested — reloading scene")
	get_tree().reload_current_scene()


func _on_realtime_entered() -> void:
	print("[GameLoop] Entered real-time mode")
	GameState.current_mode = GameState.GameMode.REALTIME


func _on_turn_entered() -> void:
	print("[GameLoop] Entered turn-based mode")
	GameState.current_mode = GameState.GameMode.TURNBASED
