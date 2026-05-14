# turn_order_panel.gd — 상단 중앙 턴 순서 표시 패널.
# 전투모드 진입 시 모든 전투원의 턴 순서를 좌→우로 표시하고,
# 현재 턴인 전투원을 강조한다.
extends Panel

const PANEL_W: int = 600
const PANEL_H: int = 48

var _container: HBoxContainer = null
var _entry_nodes: Dictionary = {}  # Node -> {rect, name_label, container, default_color}
var _current: Node = null
var _turn_order: Array = []


func _ready() -> void:
	size = Vector2(PANEL_W, PANEL_H)
	position = Vector2(340, 0)  # Top center (1280/2 - 600/2 = 340)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.1, 0.7)
	bg.corner_radius_top_left = 0
	bg.corner_radius_top_right = 0
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", bg)

	_container = HBoxContainer.new()
	_container.name = "EntryContainer"
	_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_container.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_container)

	# ── Signals ──
	EventBus.turn_order_changed.connect(_on_turn_order_changed)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.unit_destroyed.connect(_on_unit_destroyed)

	visible = false


## Build/rebuild all turn order entries.
func _rebuild(order: Array) -> void:
	_turn_order = order
	_clear_entries()

	var index: int = 1
	for unit in order:
		if not is_instance_valid(unit):
			continue
		_add_entry(unit, index)
		index += 1

	_highlight_current()


## Add a single combatant entry with order number.
func _add_entry(unit: Node, order_index: int) -> void:
	var total: int = _turn_order.size()
	var entry := VBoxContainer.new()
	entry.name = "Entry_%s" % (unit.get("unit_name") if "unit_name" in unit else "Unknown")
	entry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	entry.alignment = BoxContainer.ALIGNMENT_CENTER

	var color := _resolve_color(unit)
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(36, 36)
	rect.custom_minimum_size = Vector2(36, 36)
	rect.position = Vector2(2, 0)
	rect.tooltip_text = unit.get("unit_name") if "unit_name" in unit else "?"
 
	var name_lbl := Label.new()
	name_lbl.text = "%s %d/%d" % [unit.get("unit_name") if "unit_name" in unit else "?", order_index, total]
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.custom_minimum_size = Vector2(48, 0)

	entry.add_child(rect)
	entry.add_child(name_lbl)

	_entry_nodes[unit] = {
		rect = rect,
		name_label = name_lbl,
		container = entry,
		default_color = color,
	}

	_container.add_child(entry)


## Highlight the current turn combatant (dim others, brighten current).
func _highlight_current() -> void:
	for unit_node in _entry_nodes:
		var data: Dictionary = _entry_nodes[unit_node]
		var r: ColorRect = data.rect
		r.modulate = Color(0.5, 0.5, 0.5)
		var lbl: Label = data.name_label
		lbl.self_modulate = Color(0.5, 0.5, 0.5)

	if _current and _current in _entry_nodes:
		var data: Dictionary = _entry_nodes[_current]
		var r: ColorRect = data.rect
		r.modulate = Color(1.0, 1.0, 1.0)
		var lbl: Label = data.name_label
		lbl.self_modulate = Color(1.0, 1.0, 1.0)


## Resolve a display color for a combatant unit.
func _resolve_color(unit: Node) -> Color:
	if unit.get("is_player"):
		return Color(0.2, 0.6, 1.0)
	# Enemies: try reading sprite texture, otherwise hash-based
	var sprite = unit.get_node_or_null("Sprite2D")
	if sprite and sprite.texture:
		# Godot 4 ImageTexture get_image approach — fallible
		var img = sprite.texture.get_image() if sprite.texture.has_method("get_image") else null
		if img:
			return img.get_pixel(16, 16)
	# Fallback: hash unit name or instance ID for a stable color
	var name_str: String = unit.get("unit_name") if "unit_name" in unit else str(unit.get_instance_id())
	var h: int = abs(hash(name_str))
	return Color(
		float(h % 100) / 100.0 * 0.6 + 0.2,
		float((h / 100) % 100) / 100.0 * 0.5 + 0.15,
		float((h / 10000) % 100) / 100.0 * 0.3 + 0.1
	)


func _clear_entries() -> void:
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()
	_entry_nodes.clear()


## ─── Signal handlers ───

func _on_turn_order_changed(order: Array) -> void:
	_turn_order = order
	_rebuild(order)


func _on_turn_started(unit: Node) -> void:
	_current = unit
	_highlight_current()


func _on_combat_started(_participants: Array) -> void:
	visible = true


func _on_combat_ended() -> void:
	visible = false
	_current = null
	_clear_entries()


func _on_unit_destroyed(unit: Node) -> void:
	if unit in _entry_nodes:
		var data = _entry_nodes[unit]
		_container.remove_child(data.container)
		data.container.queue_free()
		_entry_nodes.erase(unit)
		_highlight_current()
