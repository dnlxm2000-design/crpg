# game_loop.gd — Orchestrates real-time <-> turn-based mode switching.
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
	# Combat end -> return to realtime
	EventBus.combat_ended.connect(_on_combat_ended)


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
	
	# Spawn test enemies near the player
	var turn_manager = $TurnManager
	var enemies = _spawn_test_enemies(player, grid)
	
	turn_manager.add_combatant(player)
	for e in enemies:
		turn_manager.add_combatant(e)
	
	enter_turn_mode()
	_entering_combat = false


## Spawn enemy units near player for testing combat.
## Creates 3~5 goblins randomly, with terrain-aware spawn positions.
func _spawn_test_enemies(player: Node, grid: Node) -> Array:
	var enemies: Array = []
	var player_gp: Vector2i = grid.world_to_grid(player.global_position)

	# 3~5 random
	var count: int = randi_range(3, 5)
	print("[GameLoop] Spawning %d enemies" % count)

	# Enemy ID pool
	var enemy_pool: Array = ["goblin", "goblin_warrior", "goblin_archer", "goblin_thief"]

	# Collect valid spawn positions (4~8 tiles around player, terrain check)
	var spawn_positions: Array = _find_valid_spawn_positions(grid, player_gp, count, 4, 8)

	for i in range(count):
		var enemy_id: String = enemy_pool[randi_range(0, enemy_pool.size() - 1)]
		var e_def: Dictionary = EnemyData.enemies().get(enemy_id)
		if not e_def:
			push_error("EnemyData: unknown enemy_id '%s'" % enemy_id)
			continue

		var enemy = load("res://source/features/shared/unit.gd").new()
		enemy.unit_name = e_def.name
		enemy.is_player = false
		enemy.max_hp = e_def.hp
		enemy.current_hp = e_def.hp
		enemy.speed = e_def.speed
		enemy.accuracy = e_def.accuracy
		enemy.evasion = e_def.evasion
		enemy.attack = e_def.attack
		enemy.defense = e_def.defense
		if e_def.has("attack_range"):
			enemy.attack_range = e_def.attack_range
		else:
			enemy.attack_range = 1
		enemy.max_action_points = 3
		enemy.current_action_points = 3
		enemy.corpse_color = Color(e_def.color.r * 0.4, e_def.color.g * 0.3, e_def.color.b * 0.3)

		# Apply skills
		var skill_levels: Dictionary = {}
		if e_def.has("skill_levels"):
			skill_levels = e_def.skill_levels
		for sid in skill_levels:
			enemy.learned_skills[sid] = skill_levels[sid]

		# Convert drop table
		var drops: Array = []
		if e_def.has("drops"):
			drops = e_def.drops
		var drop_entry: Dictionary
		var item_id: String
		var item_def: Dictionary
		for d in drops:
			item_id = d.item_id
			item_def = ItemData.items().get(item_id)
			if not item_def:
				continue
			drop_entry = {}
			drop_entry["item_id"] = item_id
			drop_entry["chance"] = d.get("chance", 1.0)
			drop_entry["qty_min"] = d.get("qty_min", 1)
			drop_entry["qty_max"] = d.get("qty_max", 1)
			enemy.item_drops.append(drop_entry)

		# Terrain-based spawn position
		var spawn_gp: Vector2i
		if i < spawn_positions.size():
			spawn_gp = spawn_positions[i]
		else:
			# Fallback: random offset
			spawn_gp = _find_valid_spawn_position(grid, player_gp, 4, 8)

		# terrain height Y adjustment
		var spawn_world: Vector3 = grid.grid_to_world(spawn_gp)
		var terrain := get_node_or_null("/root/Main/Terrain")
		if terrain and terrain.has_method("get_height_at"):
			spawn_world.y = terrain.get_height_at(spawn_world)
		enemy.position = spawn_world

		# Attach movement for grid registration
		var movement = load("res://source/features/shared/unit_movement.gd").new()
		movement.name = "UnitMovement"
		enemy.add_child(movement)

		# Attach EnemyAI for patrol + turn-based combat behavior
		var ai = load("res://source/features/shared/enemy_ai.gd").new()
		ai.name = "EnemyAI"
		enemy.add_child(ai)

		# Visual: Placeholder rectangle (replace with SpriteSheet later)
		enemy.setup_placeholder_visual(e_def.color)

		# Register on grid
		if grid.has_method("set_occupied"):
			grid.set_occupied(spawn_gp, enemy)

		# Add to scene tree (GameLoop -> Main -> /root)
		get_parent().add_child(enemy)
		enemies.append(enemy)

		print("[GameLoop] Spawned %s at %s (terrain: %s)" % [
			e_def.name, spawn_gp, _get_terrain_name(grid, spawn_gp)])

	return enemies


## Find valid spawn positions around player, checking terrain walkability.
func _find_valid_spawn_positions(grid: Node, player_gp: Vector2i, count: int, min_radius: int, max_radius: int) -> Array:
	var positions: Array = []
	var attempts: int = 0
	var max_attempts: int = count * 10

	while positions.size() < count and attempts < max_attempts:
		attempts += 1
		var pos: Vector2i = _find_valid_spawn_position(grid, player_gp, min_radius, max_radius)
		if pos != Vector2i.ZERO and not _position_in_array(pos, positions):
			positions.append(pos)

	return positions


## Find a single valid spawn position.
func _find_valid_spawn_position(grid: Node, player_gp: Vector2i, min_radius: int, max_radius: int) -> Vector2i:
	for _i in range(50):
		var angle: float = randf() * PI * 2.0
		var radius: int = randi_range(min_radius, max_radius)
		var offset: Vector2i = Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius))
		var candidate: Vector2i = player_gp + offset

		if grid.has_method("is_walkable") and grid.is_walkable(candidate, true):
			var occupant = grid.get_occupant(candidate)
			if not occupant:
				return candidate

	return Vector2i.ZERO


func _position_in_array(pos: Vector2i, arr: Array) -> bool:
	for p in arr:
		if p == pos:
			return true
	return false


func _get_terrain_name(grid: Node, gp: Vector2i) -> String:
	var elv: int = grid.get_elevation(gp) if grid.has_method("get_elevation") else 1
	if grid.has_method("blocked") and grid.blocked.has("%d,%d" % [gp.x, gp.y]):
		return "BLOCKED"
	match elv:
		0: return "WATER"
		1: return "PLAINS"
		2: return "HILLS"
		_: return "MOUNTAIN"


## Pause/unpause all real-time processing (e.g. when menus open).
func set_paused(paused: bool) -> void:
	get_tree().paused = paused


func _on_combat_victory() -> void:
	print("[GameLoop] Combat victory - all enemies defeated")
	enter_realtime()


func _on_combat_defeat() -> void:
	print("[GameLoop] Combat defeat - player slain")
	# Show defeat panel with restart option
	var panel = load("res://source/ui/screens/defeat_panel.gd").new()
	panel.name = "DefeatPanel"
	panel.restart_requested.connect(_on_restart_requested)
	get_parent().add_child(panel)  # Add to /root/Main


## Restart the game scene after defeat.
func _on_restart_requested() -> void:
	print("[GameLoop] Restart requested - reloading scene")
	get_tree().reload_current_scene()


func _on_realtime_entered() -> void:
	print("[GameLoop] Entered real-time mode")
	GameState.current_mode = GameState.GameMode.REALTIME


func _on_combat_ended() -> void:
	# Safety net: return to realtime on combat end outside victory/defeat
	if is_turn_mode:
		print("[GameLoop] Combat ended - returning to real-time mode")
		enter_realtime()
	
	# Restore player AP after combat (prevent 0 state)
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		var player = rt.player_ref
		if "current_action_points" in player and "max_action_points" in player:
			player.current_action_points = player.max_action_points


func _on_turn_entered() -> void:
	print("[GameLoop] Entered turn-based mode")
	GameState.current_mode = GameState.GameMode.TURNBASED
