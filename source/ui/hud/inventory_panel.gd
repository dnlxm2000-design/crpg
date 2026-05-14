# inventory_panel.gd — 인벤토리 UI 패널 (I키 토글).
# 보유 아이템 목록을 수량과 함께 표시하고 소모품 Use 버튼을 제공한다.
extends Panel

# 플레이어의 Inventory 컴포넌트 참조 (동적 타입 — class_name 로드 순서 문제 회피)
var _inventory = null
var _gold_label: Label = null  # 골드 표시
# 아이템 목록 스크롤 컨테이너
var _scroll: ScrollContainer = null
# VBoxContainer: 아이템 행(row)이 세로로 쌓이는 공간
var _container: VBoxContainer = null
# 현재 패널 표시 여부 (I키로 토글)
var is_open: bool = false
# 드래그 상태 (마우스로 패널 자유 이동)
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO   # 드래그 시작 시 마우스-패널 간 오프셋


func _ready() -> void:
	# ── 패널 외형: 중앙 360×480, 반투명 어두운 배경, 시작 시 숨김 ──
	size = Vector2(360, 480)
	position = Vector2(460, 120)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	add_theme_stylebox_override("panel", bg)
	visible = false

	# ── 제목 ──
	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	title.position = Vector2(12, 10)
	title.size = Vector2(300, 28)
	add_child(title)

	# ── 닫기 버튼 (X) ──
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(size.x - 36, 6)
	close_btn.size = Vector2(28, 24)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	# ── 골드 표시줄 ──
	_gold_label = Label.new()
	_gold_label.name = "InvGoldLabel"
	_gold_label.add_theme_font_size_override("font_size", 13)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	_gold_label.position = Vector2(12, 36)
	_gold_label.size = Vector2(336, 20)
	add_child(_gold_label)

	# ── 아이템 목록 (스크롤 가능) ──
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(8, 58)
	_scroll.size = Vector2(344, 386)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_container = VBoxContainer.new()
	_container.size = Vector2(328, 0)
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_container)

	# ── 닫기 힌트 ──
	var hint := Label.new()
	hint.text = "Press I / ESC to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.position = Vector2(12, 450)
	hint.size = Vector2(336, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)

	# 씬 트리 준비 후 플레이어 인벤토리 찾기
	await get_tree().process_frame
	_find_inventory()


## ─── 마우스 드래그로 패널 자유 이동 ───
# _gui_input 대신 _input을 사용하는 이유:
# 자식 컨트롤(ScrollContainer, Button, Label) 위를 클릭해도
# 패널 드래그가 시작되어야 하므로, 제어권 밖으로 나가는 _gui_input보다
# 전역 입력을 받는 _input이 적합하다.
# 단, 패널이 닫혀있을 때(visible == false)는 드래그하지 않는다.
# (visible=false 상태에서 _input이 월드 클릭을 흡수하여
#  패널이 화면 밖으로 밀려나는 버그 방지)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):  # ESC
		close()
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


## RealTimeManager에서 플레이어의 Inventory 컴포넌트를 찾아 연결한다.
func _find_inventory() -> void:
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		var inv = rt.player_ref.get_node_or_null("Inventory")
		if inv:
			_inventory = inv
			_inventory.item_added.connect(_on_inventory_changed)
			_inventory.item_removed.connect(_on_inventory_changed)
			print("[InventoryPanel] Found player inventory")


func _on_close() -> void:
	close()


func toggle() -> void:
	is_open = not is_open
	if is_open:
		visible = true
		refresh()
	else:
		visible = false


func open() -> void:
	is_open = true
	visible = true
	refresh()


func close() -> void:
	is_open = false
	visible = false


## 골드 표시 업데이트.
func _update_gold() -> void:
	if not _gold_label:
		return
	var gold = 0
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref") and "gold" in rt.player_ref:
		gold = rt.player_ref.gold
	_gold_label.text = "Gold: %d" % gold


## Rebuild the item list UI from inventory data.
func refresh() -> void:
	if not _inventory or not is_open:
		return
	_update_gold()

	# Clear existing rows
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()

	# ── Equipped section ──
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	var player = rt.player_ref if rt and rt.get("player_ref") else null
	if player:
		var eq_label := Label.new()
		eq_label.add_theme_font_size_override("font_size", 11)
		eq_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		var eq_text = "Equipped: "
		var wep = player.get("equipped_weapon")
		var arm = player.get("equipped_armor")
		if wep:
			eq_text += "[W] %s  " % wep.item_name
		if arm:
			eq_text += "[A] %s" % arm.item_name
		if not wep and not arm:
			eq_text += "none"
		eq_label.text = eq_text
		eq_label.size = Vector2(328, 22)
		_container.add_child(eq_label)

		# Separator
		var sep := HSeparator.new()
		sep.size = Vector2(328, 4)
		_container.add_child(sep)

	var item_list: Array[Dictionary] = _inventory.get_item_list()
	if item_list.is_empty():
		var empty := Label.new()
		empty.text = "  (empty)"
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		empty.size = Vector2(328, 24)
		_container.add_child(empty)
		return

	for entry in item_list:
		var row := _create_item_row(entry.item, entry.quantity)
		_container.add_child(row)


## Build a single item row: [icon] name x qty  [Use/Equip].
## 소모품은 Use, 무기/방어구는 Equip 버튼을 표시한다.
func _create_item_row(it, qty: int) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 32)

	# Icon placeholder (colored rect)
	var icon_rect := ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(24, 24)
	icon_rect.color = _pick_color(it)
	row.add_child(icon_rect)

	# Spacing
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	row.add_child(spacer)

	# Name + quantity
	var label := Label.new()
	label.text = "%s x%d" % [it.item_name, qty]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	row.add_child(label)

	# Action button
	if it.item_type == 0:  # CONSUMABLE
		var use_btn := Button.new()
		use_btn.text = "Use"
		use_btn.custom_minimum_size = Vector2(48, 24)
		use_btn.pressed.connect(_on_use_item.bind(it.id))
		row.add_child(use_btn)
	elif it.item_type == 1 or it.item_type == 2:  # WEAPON or ARMOR
		var equip_btn := Button.new()
		equip_btn.text = "Equip"
		equip_btn.custom_minimum_size = Vector2(48, 24)
		equip_btn.pressed.connect(_on_equip_item.bind(it.id))
		row.add_child(equip_btn)

	return row


## Handle Use button click (consumables).
func _on_use_item(item_id: String) -> void:
	if not _inventory:
		return
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if not rt or not rt.get("player_ref"):
		return
	var player = rt.player_ref

	if _inventory.use_item(item_id, player):
		refresh()
		var hud = get_node_or_null("/root/Main/HUD")
		if hud:
			var event_log = hud.get_node_or_null("EventLog")
			if event_log and event_log.has_method("add_entry"):
				event_log.add_entry("Used %s" % item_id, Color(0.3, 1.0, 0.3))
	else:
		print("[InventoryPanel] Failed to use item: %s" % item_id)


## Handle Equip button click (weapons/armor).
## 플레이어 유닛에 아이템을 장비하고, 이전 장비는 인벤토리로 반환한다.
func _on_equip_item(item_id: String) -> void:
	if not _inventory:
		return
	var rt = get_node_or_null("/root/Main/RealTimeManager")
	if not rt or not rt.get("player_ref"):
		return
	var player = rt.player_ref

	var result = _inventory.equip_item(item_id, player)
	if result.get("success", false):
		refresh()
		var hud = get_node_or_null("/root/Main/HUD")
		if hud:
			var event_log = hud.get_node_or_null("EventLog")
			if event_log and event_log.has_method("add_entry"):
				event_log.add_entry(result.get("message", "Equipped item"), Color(0.9, 0.9, 0.3))
	else:
		print("[InventoryPanel] Failed to equip: %s — %s" % [item_id, result.get("message", "unknown")])


func _pick_color(it) -> Color:
	if not it:
		return Color.GRAY
	match it.item_type:
		0:  return Color(0.2, 0.8, 0.3)
		1:  return Color(0.9, 0.3, 0.3)
		2:  return Color(0.3, 0.3, 0.9)
		3:  return Color(0.9, 0.8, 0.2)
		4:  return Color(1.0, 0.8, 0.0)
		_:  return Color.GRAY


func _on_inventory_changed(_a = null, _b = null) -> void:
	refresh()
