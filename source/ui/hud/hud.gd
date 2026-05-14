# hud.gd — Primary in-game HUD.
# Shows health bars, action points, turn indicator, damage numbers, etc.
extends CanvasLayer


@onready var health_bar: ProgressBar = %HealthBar
@onready var ap_label: Label = %ActionPointsLabel
@onready var mode_label: Label = %ModeLabel
@onready var turn_indicator: Label = %TurnIndicator

var _player: Node = null
var _enemy_hp_containers: Dictionary = {}  # Node -> Panel for enemy HP bars
var _combat_announce: Label = null
var _announce_tween: Tween = null
var _gold_label: Label = null  # Gold display in top-left
var _center_prompt: Label = null  # Center-screen prompt (AP 0, etc.)


func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.game_mode_changed.connect(_on_mode_changed)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_ended.connect(_on_round_ended)
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.ap_changed.connect(_on_ap_changed)
	EventBus.player_ended_turn.connect(_on_player_ended_turn)
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.unit_destroyed.connect(_on_unit_destroyed)
	EventBus.unit_evaded.connect(_on_unit_evaded)
	EventBus.combat_victory.connect(_on_combat_victory)
	EventBus.combat_defeat.connect(_on_combat_defeat)
	EventBus.gold_changed.connect(_on_gold_changed)

	# Create combat announcement label (centered, large text)
	_combat_announce = Label.new()
	_combat_announce.name = "CombatAnnounce"
	_combat_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combat_announce.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combat_announce.add_theme_font_size_override("font_size", 48)
	_combat_announce.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_combat_announce.position = Vector2(400, 300)
	_combat_announce.size = Vector2(600, 120)
	_combat_announce.z_index = 100
	_combat_announce.visible = false
	add_child(_combat_announce)

	# ── Center-screen prompt (AP 0 message, dims background) ──
	_center_prompt = Label.new()
	_center_prompt.name = "CenterPrompt"
	_center_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_prompt.add_theme_font_size_override("font_size", 28)
	_center_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_center_prompt.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_center_prompt.add_theme_constant_override("shadow_outline_size", 4)
	_center_prompt.position = Vector2(340, 300)
	_center_prompt.size = Vector2(600, 80)
	_center_prompt.z_index = 200
	_center_prompt.visible = false
	add_child(_center_prompt)

	# Create event log panel
	var event_log = load("res://source/ui/hud/event_log.gd").new()
	event_log.name = "EventLog"
	add_child(event_log)

	# Create inventory panel (hidden by default)
	var inv_panel = load("res://source/ui/hud/inventory_panel.gd").new()
	inv_panel.name = "InventoryPanel"
	add_child(inv_panel)

	# Create equipment panel (hidden by default)
	var eq_panel = load("res://source/ui/hud/equipment_panel.gd").new()
	eq_panel.name = "EquipmentPanel"
	add_child(eq_panel)

	# ── Turn order panel (top center, shown during combat) ──
	var turn_order = load("res://source/ui/hud/turn_order_panel.gd").new()
	turn_order.name = "TurnOrderPanel"
	add_child(turn_order)

	# ── Gold display (top-left, below HP bar) ──
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	_gold_label.position = Vector2(16, 100)
	_gold_label.size = Vector2(150, 20)
	add_child(_gold_label)

	# Find player after scene tree is ready
	await get_tree().process_frame
	_find_player()


## Locate the player unit via RealTimeManager.
func _find_player() -> void:
	var rt = get_node("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		_player = rt.player_ref
		print("[HUD] Found player: ", _player.unit_name)
		_update_hp_bar()
		_update_ap_label()
		_update_gold_label()
	else:
		# Fallback: search scene tree
		_player = get_tree().get_first_node_in_group("player_unit")
		if not _player:
			for node in get_tree().root.get_children():
				_player = _find_player_recursive(node)
				if _player:
					break
		if _player:
			print("[HUD] Found player via fallback: ", _player.unit_name)
			_update_hp_bar()
			_update_ap_label()


func _find_player_recursive(node: Node) -> Node:
	if node.get("is_player") == true and node.get("is_alive") != null:
		return node
	for child in node.get_children():
		var found = _find_player_recursive(child)
		if found:
			return found
	return null


## --- Turn/Combat signals ---

func _on_turn_started(unit: Node) -> void:
	hide_center_prompt()
	var unit_name = unit.get("unit_name") if "unit_name" in unit else "Unknown"
	# Show turn order position
	var tm = get_node_or_null("/root/Main/GameLoop/TurnManager")
	if tm and tm.get("turn_order") and tm.get("current_turn_index") != null:
		var order: Array = tm.turn_order
		var idx: int = tm.current_turn_index
		var total: int = order.size()
		turn_indicator.text = "%s (%d/%d)의 턴" % [unit_name, idx + 1, total]
	else:
		turn_indicator.text = "%s's Turn" % unit_name
	# Update AP if it's the player's turn
	if unit == _player:
		_update_ap_label()


func _on_turn_ended(_unit: Node) -> void:
	turn_indicator.text = ""


## Public method: set turn indicator text (used by player_controller for warnings).
func set_turn_indicator(text: String) -> void:
	if turn_indicator:
		turn_indicator.text = text


## Show a centered prompt (e.g. "AP 0 — Press Space to end turn").
## Used by player_controller when player runs out of AP.
func show_center_prompt(text: String) -> void:
	if _center_prompt:
		_center_prompt.text = text
		_center_prompt.visible = true


## Hide the centered prompt.
func hide_center_prompt() -> void:
	if _center_prompt:
		_center_prompt.visible = false
		_center_prompt.text = ""


func _on_mode_changed(mode: String) -> void:
	mode_label.text = mode.to_upper()


func _on_round_started(round: int) -> void:
	mode_label.text = "ROUND %d" % round


func _on_round_ended(round: int) -> void:
	print("[HUD] Round %d ended" % round)


func _on_combat_started(participants: Array) -> void:
	hide_center_prompt()
	_clear_enemy_bars()
	_find_player()
	_update_hp_bar()
	_update_ap_label()

	# Show combat announcement
	_show_combat_announce("⚔ COMBAT ⚔", Color(1.0, 0.9, 0.3))

	# Create HP bars for non-player participants
	for unit in participants:
		if unit != _player and unit.get("is_player") != true:
			_add_enemy_hp_bar(unit)


func _on_combat_victory() -> void:
	_show_combat_announce("VICTORY", Color(0.3, 1.0, 0.3))


func _on_combat_defeat() -> void:
	_show_combat_announce("DEFEAT", Color(1.0, 0.3, 0.3))


func _on_combat_ended() -> void:
	hide_center_prompt()
	turn_indicator.text = ""
	ap_label.text = ""
	_clear_enemy_bars()
	# After combat, player may have been replaced — find again
	_find_player()


## Show a large centered announcement with a scale-up + fade-out animation.
func _show_combat_announce(text: String, color: Color) -> void:
	if not _combat_announce:
		return

	# Kill any running announce tween to avoid conflicts
	if _announce_tween and _announce_tween.is_valid():
		_announce_tween.kill()

	_combat_announce.text = text
	_combat_announce.add_theme_color_override("font_color", color)
	_combat_announce.modulate = Color.WHITE
	_combat_announce.scale = Vector2(0.5, 0.5)
	_combat_announce.visible = true

	_announce_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE)
	_announce_tween.tween_property(_combat_announce, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT)
	_announce_tween.tween_property(_combat_announce, "modulate:a", 0.0, 0.8).set_delay(0.8)
	_announce_tween.tween_callback(func(): _combat_announce.visible = false).set_delay(1.6)


func _on_ap_changed(unit: Node) -> void:
	if unit == _player:
		_update_ap_label()


func _on_player_ended_turn(_unit: Node) -> void:
	if _player:
		_update_ap_label()


## --- Damage numbers ---

func _on_unit_evaded(target: Node, _source: Node) -> void:
	if is_instance_valid(target):
		_show_miss_text(target)


func _on_unit_damaged(unit: Node, amount: int, _source: Node) -> void:
	# Update HP bar if it's the player
	if unit == _player:
		_update_hp_bar()

	# Update enemy HP bar if tracked
	if unit in _enemy_hp_containers:
		_update_enemy_hp_bar(unit)

	# Show floating damage number
	if is_instance_valid(unit):
		_show_damage_number(unit, amount)


func _show_damage_number(unit: Node, amount: int) -> void:
	var label = Label.new()
	label.text = "-%d" % amount
	label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	label.add_theme_font_size_override("font_size", 18)
	label.position = Vector2(16, -40)  # Offset above unit center

	unit.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", -72, 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


## Show "MISS" floating text above a unit that evaded an attack.
func _show_miss_text(unit: Node) -> void:
	if not is_instance_valid(unit):
		return
	var label = Label.new()
	label.text = "MISS"
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(16, -60)

	unit.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", -100, 0.6).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


## --- HP / AP display ---

func _update_hp_bar() -> void:
	if not _player or not health_bar:
		return
	var max_hp = _player.get("max_hp") if "max_hp" in _player else 100
	var cur_hp = _player.get("current_hp") if "current_hp" in _player else 0
	health_bar.max_value = max_hp
	health_bar.value = cur_hp

	# Color: green → yellow → red
	var pct: float = float(cur_hp) / max_hp if max_hp > 0 else 0.0
	if pct > 0.6:
		health_bar.modulate = Color(0.2, 1.0, 0.2)
	elif pct > 0.3:
		health_bar.modulate = Color(1.0, 1.0, 0.2)
	else:
		health_bar.modulate = Color(1.0, 0.2, 0.2)

	var label_node = health_bar.get_node_or_null("HPLabel")
	if not label_node:
		label_node = Label.new()
		label_node.name = "HPLabel"
		health_bar.add_child(label_node)
		label_node.position = Vector2(4, 2)
	label_node.text = "%d / %d" % [cur_hp, max_hp]


func _update_ap_label() -> void:
	if not _player or not ap_label:
		return
	var ap = _player.get("current_action_points") if "current_action_points" in _player else 0
	var max_ap = _player.get("max_action_points") if "max_action_points" in _player else 4
	ap_label.text = "AP: %d / %d" % [ap, max_ap]


## === Enemy HP Bars ===

## Remove an enemy HP bar when its unit is destroyed.
func _on_unit_destroyed(unit: Node) -> void:
	if unit in _enemy_hp_containers:
		var panel = _enemy_hp_containers[unit]
		_enemy_hp_containers.erase(unit)
		if is_instance_valid(panel):
			panel.queue_free()


func _on_gold_changed(_unit: Node, _amount: int) -> void:
	_update_gold_label()


func _update_gold_label() -> void:
	if not _gold_label or not _player:
		return
	var gold = _player.get("gold") if "gold" in _player else 0
	_gold_label.text = "Gold: %d" % gold


## Create a small HP bar panel for an enemy unit.
func _add_enemy_hp_bar(unit: Node) -> void:
	var panel = Panel.new()
	var bar_index = _enemy_hp_containers.size()
	panel.size = Vector2(200, 44)
	panel.position = Vector2(10, 200 + bar_index * 50)

	# Enemy name
	var name_label = Label.new()
	name_label.text = unit.get("unit_name") if "unit_name" in unit else "Enemy"
	name_label.position = Vector2(4, 2)
	panel.add_child(name_label)

	# HP bar
	var hp_bar = ProgressBar.new()
	hp_bar.size = Vector2(180, 20)
	hp_bar.position = Vector2(4, 20)
	var max_hp = unit.get("max_hp") if "max_hp" in unit else 100
	var cur_hp = unit.get("current_hp") if "current_hp" in unit else 0
	hp_bar.max_value = max_hp
	hp_bar.value = cur_hp
	hp_bar.modulate = Color(1.0, 0.3, 0.3)

	# HP text
	var hp_label = Label.new()
	hp_label.name = "HPValue"
	hp_label.text = "%d / %d" % [cur_hp, max_hp]
	hp_label.position = Vector2(4, 2)
	hp_bar.add_child(hp_label)

	panel.add_child(hp_bar)
	add_child(panel)

	_enemy_hp_containers[unit] = panel


## Refresh a tracked enemy's HP bar.
func _update_enemy_hp_bar(unit: Node) -> void:
	var panel = _enemy_hp_containers.get(unit)
	if not panel or not is_instance_valid(panel):
		return

	# Panel structure: children[0] = name label, children[1] = progress bar
	var hp_bar = panel.get_child(1) if panel.get_child_count() > 1 else null
	if not hp_bar:
		return

	var max_hp = unit.get("max_hp") if "max_hp" in unit else 100
	var cur_hp = unit.get("current_hp") if "current_hp" in unit else 0
	hp_bar.max_value = max_hp
	hp_bar.value = cur_hp

	var hp_label = hp_bar.get_node_or_null("HPValue")
	if hp_label:
		hp_label.text = "%d / %d" % [cur_hp, max_hp]


## Remove all enemy HP bar panels.
func _clear_enemy_bars() -> void:
	for panel in _enemy_hp_containers.values():
		if is_instance_valid(panel):
			panel.queue_free()
	_enemy_hp_containers.clear()
