# main.gd — Entry point for the game.
# Attach this script to the root node of main.tscn.
# Expected scene tree:
#   Main (main.gd)
#   ├── GameLoop (game_loop.gd)
#   │   ├── realtime (realtime_state.gd)
#   │   ├── turnbased (turnbased_state.gd)
#   │   ├── TurnManager (turn_manager.gd)
#   │   ├── ActionPoints (action_points.gd)
#   │   └── Timeline (timeline_manager.gd)
#   ├── RealTimeManager (realtime_manager.gd)
#   ├── HUD (hud.gd)
#   ├── MovementRangeOverlay (movement_range_overlay.gd)  [turn-based reachable tiles]
#   └── PathPreview (path_preview.gd)                     [real-time mouse path line]
extends Node2D

@onready var _game_loop: Node = $GameLoop
@onready var _grid_world: Node = $GameLoop/GridWorld


func _ready() -> void:
	print("[Main] CRPG_PROJECT initializing...")

	# Ensure core autoloads are available
	assert(EventBus != null, "EventBus autoload is required")
	assert(GameState != null, "GameState autoload is required")

	# ── Movement Range Overlay (turn-based reachable tiles) ──
	var range_overlay = load("res://source/features/shared/effects/movement_range_overlay.gd").new()
	range_overlay.name = "MovementRangeOverlay"
	add_child(range_overlay)
	if _grid_world and range_overlay.has_method("setup"):
		range_overlay.setup(_grid_world)
		# Draw below units but above the grid background
		range_overlay.z_index = -1
		range_overlay.z_as_relative = false

	# ── Path Preview (real-time mouse path line) ──
	var path_preview = load("res://source/features/shared/effects/path_preview.gd").new()
	path_preview.name = "PathPreview"
	add_child(path_preview)
	path_preview.z_index = 1
	path_preview.z_as_relative = false
	# Wire references after player is spawned
	path_preview.visible = false

	# Spawn player and start in real-time mode (Stoneshard-style)
	if _game_loop:
		var rt_manager: Node = $RealTimeManager
		if rt_manager and rt_manager.has_method("spawn_player"):
			var spawn_grid := Vector2i(30, 61)
			var spawn_pos: Vector2 = _grid_world.grid_to_world(spawn_grid) if _grid_world else Vector2(0, 320)
			var player = rt_manager.spawn_player(spawn_pos)
			print("[Main] Player spawned at iso grid %s → world %s" % [str(spawn_grid), str(spawn_pos)])
			# Wire path preview to player + grid
			if _grid_world and path_preview.has_method("setup"):
				path_preview.setup(_grid_world, player)
				path_preview.visible = true

		# Spawn a test health potion near the player
		_spawn_test_items()

		_game_loop.enter_realtime()


## Place test items on the map for debugging.
func _spawn_test_items() -> void:
	if not _grid_world:
		return

	var health_potion = load("res://source/data/items/resources/health_potion.tres")
	if not health_potion:
		push_error("[Main] Failed to load health_potion.tres")
		return

	# Place a health potion 2 tiles to the right of spawn (grid 6, 5)
	var potion_pos: Vector2i = Vector2i(6, 5)
	var potion_item = load("res://source/features/realtime/map_item.gd").new()
	potion_item.setup(health_potion, potion_pos)
	# Set world position directly (avoid get_node during _ready)
	if _grid_world and _grid_world.has_method("grid_to_world"):
		potion_item.position = _grid_world.grid_to_world(potion_pos)
	add_child(potion_item)
	print("[Main] Spawned test Health Potion at grid (6,5)")
	# Verify group registration
	call_deferred("_verify_map_item_group")


## Debug: verify MapItem is in the map_items group.
func _verify_map_item_group() -> void:
	var items = get_tree().get_nodes_in_group("map_items")
	print("[Main] map_items group has %d node(s)" % items.size())
	for it in items:
		var gp = it.get("grid_position") if "grid_position" in it else "?"
		var nm = ""
		var item_data = it.get("item")
		if item_data and typeof(item_data) == TYPE_OBJECT and "item_name" in item_data:
			nm = item_data.item_name
		print("  -> %s at %s (%s)" % [it.name, str(gp), nm])

	# Place another one 2 tiles below
	# var potion_pos2 := Vector2i(5, 7)
	# var potion_item2 = load("res://source/features/realtime/map_item.gd").new()
	# potion_item2.setup(health_potion, potion_pos2)
	# add_child(potion_item2)
