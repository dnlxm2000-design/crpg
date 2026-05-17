# equipment_panel.gd — 캐릭터 스테이터스 패널 (E키 토글).
# 상단: 6속성 + 파생 스탯 → 중간: 장비 슬롯 → 하단: 인벤토리 목록.
# ESC/X 버튼으로 닫기.
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
var _inventory = null
var _slot_container: VBoxContainer = null
var _inv_container: VBoxContainer = null
var _stat_label: Label = null
var _derived_label: Label = null
var _gold_label: Label = null
var is_open: bool = false
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Panel style
	size = Vector2(420, 720)
	position = Vector2(60, 60)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	add_theme_stylebox_override("panel", bg)
	visible = false

	# ── 1. Title bar: 캐릭터 스테이터스 ──
	var title := Label.new()
	title.text = "캐릭터 스테이터스"
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

	# ── 2. Stats section (6 attributes + derived) ──
	var stats_bg := PanelContainer.new()
	stats_bg.position = Vector2(8, 42)
	stats_bg.size = Vector2(size.x - 16, 72)
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.06, 0.06, 0.1, 0.6)
	stats_style.corner_radius_top_left = 4
	stats_style.corner_radius_top_right = 4
	stats_style.corner_radius_bottom_left = 4
	stats_style.corner_radius_bottom_right = 4
	stats_bg.add_theme_stylebox_override("panel", stats_style)
	add_child(stats_bg)

	var stats_inner := VBoxContainer.new()
	stats_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_inner.add_theme_constant_override("margin_left", 8)
	stats_inner.add_theme_constant_override("margin_top", 4)
	stats_inner.add_theme_constant_override("margin_right", 8)
	stats_inner.add_theme_constant_override("margin_bottom", 4)
	stats_inner.add_theme_constant_override("separation", 2)
	stats_bg.add_child(stats_inner)

	_stat_label = Label.new()
	_stat_label.add_theme_font_size_override("font_size", 12)
	_stat_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	stats_inner.add_child(_stat_label)

	_derived_label = Label.new()
	_derived_label.name = "DerivedLabel"
	_derived_label.add_theme_font_size_override("font_size", 12)
	_derived_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	stats_inner.add_child(_derived_label)

	# ── 3. Equipment slots ──
	var eq_title := Label.new()
	eq_title.text = "장비"
	eq_title.add_theme_font_size_override("font_size", 13)
	eq_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	eq_title.position = Vector2(12, 122)
	eq_title.size = Vector2(200, 22)
	add_child(eq_title)

	var eq_scroll := ScrollContainer.new()
	eq_scroll.position = Vector2(8, 146)
	eq_scroll.size = Vector2(size.x - 16, 260)
	eq_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(eq_scroll)

	_slot_container = VBoxContainer.new()
	_slot_container.size = Vector2(size.x - 24, 0)
	_slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_container.add_theme_constant_override("separation", 2)
	eq_scroll.add_child(_slot_container)

	# ── 4. Inventory items ──
	var inv_title := Label.new()
	inv_title.text = "장비목록"
	inv_title.add_theme_font_size_override("font_size", 13)
	inv_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	inv_title.position = Vector2(12, 414)
	inv_title.size = Vector2(200, 22)
	add_child(inv_title)

	# 골드 표시
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 12)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	_gold_label.position = Vector2(260, 414)
	_gold_label.size = Vector2(148, 22)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_gold_label)

	var inv_scroll := ScrollContainer.new()
	inv_scroll.position = Vector2(8, 438)
	inv_scroll.size = Vector2(size.x - 16, 240)
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(inv_scroll)

	_inv_container = VBoxContainer.new()
	_inv_container.size = Vector2(size.x - 24, 0)
	_inv_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_container.add_theme_constant_override("separation", 2)
	inv_scroll.add_child(_inv_container)

	await get_tree().process_frame
	_find_player()
	_find_inventory()


func _find_player() -> void:
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		_player = rt.player_ref


func _find_inventory() -> void:
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		var inv = rt.player_ref.get_node_or_null("Inventory")
		if inv:
			_inventory = inv
			if not _inventory.item_added.is_connected(_on_inventory_changed):
				_inventory.item_added.connect(_on_inventory_changed)
			if not _inventory.item_removed.is_connected(_on_inventory_changed):
				_inventory.item_removed.connect(_on_inventory_changed)


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


func _on_inventory_changed() -> void:
	if is_open:
		refresh()


## Refresh all sections.
func refresh() -> void:
	if not _player or not visible:
		return

	# Stats
	var attrs = _format_attributes(_player)
	_stat_label.text = attrs.primary
	if _derived_label:
		_derived_label.text = attrs.derived

	# Equipment slots
	_refresh_slots()

	# Inventory items
	_refresh_inventory()

	# Gold
	_update_gold()


func _refresh_slots() -> void:
	if not _slot_container:
		return

	# Clear
	for child in _slot_container.get_children():
		_slot_container.remove_child(child)
		child.queue_free()

	# Build slot rows
	for slot in SLOTS:
		var row := _create_slot_row(slot.var_name, slot.label)
		_slot_container.add_child(row)


func _refresh_inventory() -> void:
	if not _inv_container:
		return

	# Clear
	for child in _inv_container.get_children():
		_inv_container.remove_child(child)
		child.queue_free()

	if not _inventory:
		var empty := Label.new()
		empty.text = "  (no inventory)"
		empty.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
		_inv_container.add_child(empty)
		return

	var item_list: Array[Dictionary] = _inventory.get_item_list()
	if item_list.is_empty():
		var empty := Label.new()
		empty.text = "  (empty)"
		empty.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
		_inv_container.add_child(empty)
		return

	for item_data in item_list:
		var row := _create_inv_row(item_data)
		_inv_container.add_child(row)


func _update_gold() -> void:
	if not _gold_label:
		return
	var gold = 0
	if _player and "gold" in _player:
		gold = _player.gold
	_gold_label.text = "Gold: %d" % gold


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


## Create inventory item row: [item name] [qty] [use/equip button]
func _create_inv_row(item_data: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 28)

	var item = item_data.get("item")
	var qty = item_data.get("quantity", 1)

	# Item name
	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if item and "item_name" in item:
		name_label.text = "  %s" % item.item_name
		name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	else:
		name_label.text = "  (unknown)"
	row.add_child(name_label)

	# Quantity
	if qty > 1:
		var qty_label := Label.new()
		qty_label.text = "x%d" % qty
		qty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		row.add_child(qty_label)

	# Equip button (for equippable items)
	if item and item.get("item_type") in ["WEAPON", "ARMOR", "HELMET", "NECKLACE", "CLOAK", "BELT", "RING", "GLOVE", "BOOTS", "OFF_HAND"]:
		var equip_btn := Button.new()
		equip_btn.text = "Equip"
		equip_btn.custom_minimum_size = Vector2(60, 22)
		equip_btn.add_theme_font_size_override("font_size", 11)
		equip_btn.pressed.connect(_on_equip.bind(item))
		row.add_child(equip_btn)

	# Use button (for consumables)
	if item and item.get("item_type") == "CONSUMABLE":
		var use_btn := Button.new()
		use_btn.text = "Use"
		use_btn.custom_minimum_size = Vector2(50, 22)
		use_btn.add_theme_font_size_override("font_size", 11)
		use_btn.pressed.connect(_on_use.bind(item))
		row.add_child(use_btn)

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


## Handle equip button click.
func _on_equip(item: Resource) -> void:
	if not _player:
		return
	var inv = _player.get_node_or_null("Inventory")
	if not inv:
		return
	if inv.has_method("equip_item"):
		inv.equip_item(item, _player)
		refresh()


## Handle use button click (consumables).
func _on_use(item: Resource) -> void:
	if not _player:
		return
	var inv = _player.get_node_or_null("Inventory")
	if not inv:
		return
	if inv.has_method("use_item"):
		inv.use_item(item, _player)
		refresh()


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
