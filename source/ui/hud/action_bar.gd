# action_bar.gd — 전투 액션 바 (공격/아이템/대기).
# 전투 모드에서 하단 중앙에 표시된다.
extends Panel

signal attack_pressed()
signal item_pressed()
signal wait_pressed()
signal end_turn_pressed()

const BAR_W: int = 480
const BAR_H: int = 60
const BTN_W: int = 140
const BTN_H: int = 44

var _attack_btn: Button = null
var _item_btn: Button = null
var _wait_btn: Button = null
var _container: HBoxContainer = null


func _ready() -> void:
	size = Vector2(BAR_W, BAR_H)
	position = Vector2(400, 690)  # Bottom center (1280/2 - 480/2 = 400)

	# Background style
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", bg)

	# Container
	_container = HBoxContainer.new()
	_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_container.anchors_preset = Control.PRESET_FULL_RECT
	_container.add_theme_constant_override("separation", 12)
	add_child(_container)

	# Attack button
	_attack_btn = _make_button("⚔ Attack", Color(1.0, 0.4, 0.3))
	_attack_btn.pressed.connect(_on_attack_pressed)

	# Item button
	_item_btn = _make_button("🎒 Item", Color(0.4, 0.6, 1.0))
	_item_btn.pressed.connect(_on_item_pressed)

	# Wait button
	_wait_btn = _make_button("⏳ Wait", Color(0.8, 0.8, 0.3))
	_wait_btn.pressed.connect(_on_wait_pressed)

	# Initially hidden
	visible = false

	# Connect combat signals
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.ap_changed.connect(_on_ap_changed)


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(BTN_W, BTN_H)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Normal style
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_color = color
	normal.border_blend = true
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal)

	# Hover style
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.25, 0.25, 0.4, 0.95)
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_color = color
	hover.border_blend = true
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover)

	# Disabled style
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.08, 0.08, 0.12, 0.6)
	disabled.border_width_top = 1
	disabled.border_width_bottom = 1
	disabled.border_width_left = 1
	disabled.border_width_right = 1
	disabled.border_color = Color(0.3, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))

	_container.add_child(btn)
	return btn


func _on_combat_started(_participants: Array) -> void:
	visible = true
	_update_button_states()


func _on_combat_ended() -> void:
	visible = false


func _on_turn_started(unit: Node) -> void:
	# Enable buttons when it's the player's turn
	if unit.get("is_player") == true:
		_update_button_states()
	else:
		_set_buttons_enabled(false)


func _on_ap_changed(unit: Node) -> void:
	if unit.get("is_player") == true:
		_update_button_states()


func _update_button_states() -> void:
	if not _attack_btn or not _item_btn or not _wait_btn:
		return

	var player = _find_player()
	if not player:
		return

	var ap = player.get("current_action_points") if "current_action_points" in player else 0
	var has_ap = ap > 0

	_attack_btn.disabled = not has_ap
	_item_btn.disabled = not has_ap
	# Wait is always available (even with 0 AP, ends turn)
	_wait_btn.disabled = false


func _set_buttons_enabled(enabled: bool) -> void:
	if _attack_btn:
		_attack_btn.disabled = not enabled
	if _item_btn:
		_item_btn.disabled = not enabled
	if _wait_btn:
		_wait_btn.disabled = not enabled


func _find_player() -> Node:
	var hud = get_parent()
	if hud and "get_player" in hud:
		return hud.get_player()
	# Fallback
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		return rt.player_ref
	return null


func _on_attack_pressed() -> void:
	attack_pressed.emit()


func _on_item_pressed() -> void:
	item_pressed.emit()


func _on_wait_pressed() -> void:
	# Wait: if AP > 0, skip remaining AP; if AP == 0, end turn
	var player = _find_player()
	if player and "current_action_points" in player:
		if player.current_action_points > 0:
			player.current_action_points = 0
			EventBus.ap_changed.emit(player)
	wait_pressed.emit()
