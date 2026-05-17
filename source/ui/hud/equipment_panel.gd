# equipment_panel.gd — 장비 패널 UI (9종 슬롯 표시).
# 우클릭으로 장비 해제, ESC/X 버튼으로 닫기.
extends Panel

## 열거 순서대로 표시할 장비 슬롯.
const SLOTS: Array[Dictionary] = [
	{var_name = "equipped_helmet",    label = "Head"},
	{var_name = "equipped_necklace",  label = "Necklace"},
	{var_name = "equipped_weapon",    label = "Right Hand"},
	{var_name = "equipped_off_hand",  label = "Left Hand"},
	{var_name = "equipped_armor",     label = "Body"},
	{var_name = "equipped_belt",      label = "Belt"},
	{var_name = "equipped_cloak",     label = "Cloak"},
	{var_name = "equipped_ring1",     label = "Ring 1"},
	{var_name = "equipped_ring2",     label = "Ring 2"},
	{var_name = "equipped_gloves",    label = "Gloves"},
	{var_name = "equipped_boots",     label = "Boots"},
]

var _player: Node = null
var _container: VBoxContainer = null
var _stat_label: Label = null
var _derived_label: Label = null
var is_open: bool = false
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Panel style
	size = Vector2(420, 560)
	position = Vector2(60, 120)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	add_theme_stylebox_override("panel", bg)
	visible = false

	# Title bar
	var title := Label.new()
	title.text = "EQUIPMENT"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	title.position = Vector2(12, 10)
	title.size = Vector2(320, 28)
	add_child(title)

	# Close button (X)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(size.x - 36, 6)
	close_btn.size = Vector2(28, 24)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	# Scrollable slot list
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(8, 42)
	scroll.size = Vector2(size.x - 16, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_container = VBoxContainer.new()
	_container.size = Vector2(size.x - 24, 0)
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_container.add_theme_constant_override("separation", 2)
	scroll.add_child(_container)

	# Stats section (6 attributes + derived stats)
	var stats_panel := VBoxContainer.new()
	stats_panel.position = Vector2(8, size.y - 140)
	stats_panel.size = Vector2(size.x - 16, 132)
	stats_panel.add_theme_constant_override("separation", 2)
	add_child(stats_panel)

	_stat_label = Label.new()
	_stat_label.add_theme_font_size_override("font_size", 12)
	_stat_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	stats_panel.add_child(_stat_label)

	_derived_label = Label.new()
	_derived_label.name = "DerivedLabel"
	_derived_label.add_theme_font_size_override("font_size", 12)
	_derived_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	stats_panel.add_child(_derived_label)

	await get_tree().process_frame
	_find_player()


func _find_player() -> void:
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		_player = rt.player_ref


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_rect().has_point(get_global_mouse_position()):
				_dragging = true
				_drag_offset = get_global_mouse_position() - position
		else:
			_dragging = false
	if event is InputEventMouseMotion and _dragging:
		position = get_global_mouse_position() - _drag_offset
	if event.is_action_pressed("ui_cancel"):  # ESC
		close()


func open() -> void:
	is_open = true
	visible = true
	refresh()


func close() -> void:
	is_open = false
	visible = false


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func _on_close() -> void:
	close()


## Refresh all slot rows and stats.
func refresh() -> void:
	if not _player or not visible:
		return

	# Clear
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()

	# Build slot rows
	for slot in SLOTS:
		var row := _create_slot_row(slot.var_name, slot.label)
		_container.add_child(row)

	# Stats
	var attrs = _format_attributes(_player)
	_stat_label.text = attrs.primary
	if _derived_label:
		_derived_label.text = attrs.derived


## Create one row: [slot label] [item name] [unequip button]
func _create_slot_row(var_name: String, label: String) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 28)

	# Slot label
	var slot_label := Label.new()
	slot_label.text = label
	slot_label.custom_minimum_size = Vector2(90, 24)
	slot_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	row.add_child(slot_label)

	# Item name or (empty)
	var item = _player.get(var_name) if var_name in _player else null
	var item_label := Label.new()
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if item and "item_name" in item:
		item_label.text = "  %s" % item.item_name
		item_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	else:
		item_label.text = "  (empty)"
		item_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	row.add_child(item_label)

	# Unequip button (only if slot is occupied)
	if item:
		var unequip_btn := Button.new()
		unequip_btn.text = "Unequip"
		unequip_btn.custom_minimum_size = Vector2(70, 22)
		unequip_btn.add_theme_font_size_override("font_size", 11)
		unequip_btn.pressed.connect(_on_unequip.bind(var_name))
		row.add_child(unequip_btn)

	return row


## Handle unequip button click.
func _on_unequip(slot_var: String) -> void:
	if not _player:
		return
	var inv = _player.get_node_or_null("Inventory")
	if not inv:
		return
	if inv.has_method("unequip_item"):
		inv.unequip_item(slot_var, _player)
		refresh()

		# Also refresh inventory panel if open
		var hud = get_node_or_null("/root/Main/HUD")
		if hud:
			var inv_panel = hud.get_node_or_null("InventoryPanel")
			if inv_panel and inv_panel.has_method("refresh"):
				inv_panel.refresh()


## Format 6 attributes + derived stats for display.
func _format_attributes(unit: Node) -> Dictionary:
	var str_val: int = unit.get("strength") if "strength" in unit else 0
	var dex_val: int = unit.get("dexterity") if "dexterity" in unit else 0
	var con_val: int = unit.get("constitution") if "constitution" in unit else 0
	var int_val: int = unit.get("intelligence") if "intelligence" in unit else 0
	var wis_val: int = unit.get("wisdom") if "wisdom" in unit else 0
	var cha_val: int = unit.get("charisma") if "charisma" in unit else 0

	var str_mod = _calc_mod(str_val)
	var dex_mod = _calc_mod(dex_val)
	var con_mod = _calc_mod(con_val)
	var int_mod = _calc_mod(int_val)
	var wis_mod = _calc_mod(wis_val)
	var cha_mod = _calc_mod(cha_val)

	var atk: int = unit.get_attack() if unit.has_method("get_attack") else 0
	var def: int = unit.get_defense() if unit.has_method("get_defense") else 0
	var acc: int = unit.get_accuracy() if unit.has_method("get_accuracy") else 0
	var eva: int = unit.get_evasion() if unit.has_method("get_evasion") else 0
	var init: int = unit.get_initiative() if unit.has_method("get_initiative") else 0

	var primary := "STR: %-3d (%+d)  DEX: %-3d (%+d)  CON: %-3d (%+d)\n" % [str_val, str_mod, dex_val, dex_mod, con_val, con_mod]
	primary += "INT: %-3d (%+d)  WIS: %-3d (%+d)  CHA: %-3d (%+d)" % [int_val, int_mod, wis_val, wis_mod, cha_val, cha_mod]

	var derived := "ATK: %d  DEF: %d  ACC: %d%%  EVA: %d%%  INIT: %d" % [atk, def, acc, eva, init]

	return {primary = primary, derived = derived}


## D&D-style modifier: floor((score - 10) / 2)
func _calc_mod(score: int) -> int:
	return floori((score - 10) / 2.0)
