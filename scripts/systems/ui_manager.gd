extends Control

var hp_label: Label
var ap_label: Label
var level_label: Label
var hp_bar: ProgressBar
var ap_bar: ProgressBar
var xp_bar: ProgressBar

var status_panel: PanelContainer
var minimap_panel: PanelContainer
var equipment_panel: PanelContainer
var skills_button: Button
var log_panel: PanelContainer
var log_text: RichTextLabel

var player_ref: Node
var minimap_canvas: ColorRect
var minimap_player_marker: ColorRect
var map_width: int = 20
var map_height: int = 20
var minimap_size: int = 150
var walkable_map_ref: Array = []

var inventory_window: PanelContainer
var skill_window: PanelContainer

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_target: Control = null

func _ready():
	_setup_ui()

func _setup_ui():
	status_panel = _create_status_panel()
	status_panel.position = Vector2(10, 10)
	add_child(status_panel)
	
	minimap_panel = _create_minimap_panel()
	minimap_panel.position = Vector2(700, 10)
	add_child(minimap_panel)
	
	equipment_panel = _create_equipment_panel()
	equipment_panel.position = Vector2(10, 150)
	add_child(equipment_panel)
	
	skills_button = Button.new()
	skills_button.text = "스킬"
	skills_button.custom_minimum_size = Vector2(120, 40)
	skills_button.position = Vector2(700, 500)
	skills_button.pressed.connect(_on_skills_pressed)
	add_child(skills_button)
	
	log_panel = _create_log_panel()
	log_panel.position = Vector2(10, 550)
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(log_panel)
	
	_create_inventory_popup()
	_create_skill_popup()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_target = _get_panel_under_mouse()
				if drag_target:
					drag_offset = drag_target.position - get_global_mouse_position()
			else:
				dragging = false
				drag_target = null
	elif event is InputEventMouseMotion and dragging and drag_target:
		drag_target.position = get_global_mouse_position() + drag_offset

func _get_panel_under_mouse() -> Control:
	var pos = get_global_mouse_position()
	if _inside(status_panel, pos): return status_panel
	if _inside(minimap_panel, pos): return minimap_panel
	if _inside(equipment_panel, pos): return equipment_panel
	if _inside(log_panel, pos): return log_panel
	return null

func _inside(panel: Control, pos: Vector2) -> bool:
	var p = panel.get_global_position()
	return pos.x >= p.x and pos.x <= p.x + panel.size.x and pos.y >= p.y and pos.y <= p.y + panel.size.y

func _create_status_panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(180, 100)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v = VBoxContainer.new()
	p.add_child(v)
	var t = Label.new()
	t.text = "=== 상태 ==="
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size = Vector2(180, 25)
	v.add_child(t)
	hp_label = Label.new()
	hp_label.text = "HP: 10/10"
	hp_label.custom_minimum_size = Vector2(180, 0)
	v.add_child(hp_label)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(180, 15)
	hp_bar.max_value = 10
	v.add_child(hp_bar)
	ap_label = Label.new()
	ap_label.text = "AP: 10/10"
	ap_label.custom_minimum_size = Vector2(180, 0)
	v.add_child(ap_label)
	ap_bar = ProgressBar.new()
	ap_bar.custom_minimum_size = Vector2(180, 12)
	ap_bar.max_value = 10
	v.add_child(ap_bar)
	level_label = Label.new()
	level_label.text = "Lv.1 XP: 0/300"
	level_label.custom_minimum_size = Vector2(180, 20)
	v.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(180, 10)
	xp_bar.max_value = 300
	v.add_child(xp_bar)
	return p

func _create_minimap_panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(170, 190)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v = VBoxContainer.new()
	p.add_child(v)
	var t = Label.new()
	t.text = "=== 미니맵 ==="
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size = Vector2(170, 25)
	v.add_child(t)
	var map_c = Control.new()
	map_c.custom_minimum_size = Vector2(150, 150)
	v.add_child(map_c)
	minimap_canvas = ColorRect.new()
	minimap_canvas.custom_minimum_size = Vector2(150, 150)
	minimap_canvas.color = Color(0.1, 0.1, 0.15, 1)
	map_c.add_child(minimap_canvas)
	minimap_player_marker = ColorRect.new()
	minimap_player_marker.custom_minimum_size = Vector2(8, 8)
	minimap_player_marker.color = Color(0, 1, 0, 1)
	minimap_canvas.add_child(minimap_player_marker)
	var coord = Label.new()
	coord.name = "CoordLabel"
	coord.text = "X: 0 Y: 0"
	coord.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coord.custom_minimum_size = Vector2(170, 20)
	v.add_child(coord)
	return p

func _create_equipment_panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(180, 200)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v = VBoxContainer.new()
	p.add_child(v)
	var t = Label.new()
	t.text = "=== 장비 ==="
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size = Vector2(180, 25)
	v.add_child(t)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(170, 120)
	v.add_child(grid)
	var slots = ["머리", "갑옷", "왼손", "오른손", "다리", "신발"]
	for s in slots:
		var btn = Button.new()
		btn.text = s
		btn.custom_minimum_size = Vector2(80, 35)
		grid.add_child(btn)
	var inv_btn = Button.new()
	inv_btn.text = "인벤토리"
	inv_btn.custom_minimum_size = Vector2(180, 35)
	inv_btn.pressed.connect(_on_inventory_pressed)
	v.add_child(inv_btn)
	return p

func _create_log_panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 150)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v = VBoxContainer.new()
	p.add_child(v)
	var t = Label.new()
	t.text = "=== 게임 로그 ==="
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(t)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 130)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.custom_minimum_size = Vector2(0, 130)
	log_text.scroll_following = true
	log_text.text = "[color=#888]Welcome![/color]\n"
	sc.add_child(log_text)
	return p

func _create_inventory_popup():
	inventory_window = PanelContainer.new()
	inventory_window.visible = false
	inventory_window.offset_left = 300
	inventory_window.offset_top = 100
	inventory_window.offset_right = 600
	inventory_window.offset_bottom = 400
	add_child(inventory_window)
	var v = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_window.add_child(v)
	var t = Label.new()
	t.text = "인벤토리"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var btn = Button.new()
	btn.text = "X"
	btn.custom_minimum_size = Vector2(40, 30)
	btn.pressed.connect(_close_inventory)
	v.add_child(btn)

func _create_skill_popup():
	skill_window = PanelContainer.new()
	skill_window.visible = false
	skill_window.offset_left = 500
	skill_window.offset_top = 100
	skill_window.offset_right = 700
	skill_window.offset_bottom = 350
	add_child(skill_window)
	var v = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_window.add_child(v)
	var t = Label.new()
	t.text = "스킬"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var btn = Button.new()
	btn.text = "X"
	btn.custom_minimum_size = Vector2(40, 30)
	btn.pressed.connect(_close_skill)
	v.add_child(btn)

func _on_inventory_pressed():
	inventory_window.visible = not inventory_window.visible
	if inventory_window.visible:
		skill_window.visible = false

func _on_skills_pressed():
	skill_window.visible = not skill_window.visible
	if skill_window.visible:
		inventory_window.visible = false

func _close_inventory():
	inventory_window.visible = false

func _close_skill():
	skill_window.visible = false

func bind_player(p: Node):
	player_ref = p

func bind_walkable_map(m: Array, w: int, h: int):
	walkable_map_ref = m
	map_width = w
	map_height = h

func _process(_delta):
	if player_ref:
		hp_label.text = "HP: %d/%d" % [player_ref.current_hp, player_ref.max_hp]
		hp_bar.max_value = player_ref.max_hp
		hp_bar.value = player_ref.current_hp
		ap_label.text = "AP: %d/%d" % [player_ref.current_ap, player_ref.max_ap]
		ap_bar.max_value = player_ref.max_ap
		ap_bar.value = player_ref.current_ap
		if level_label and xp_bar:
			var xp_needed = player_ref.xp_to_next_level if player_ref.xp_to_next_level > 0 else 300
			level_label.text = "Lv.%d XP: %d/%d" % [player_ref.level, player_ref.current_xp, xp_needed]
			xp_bar.max_value = xp_needed
			xp_bar.value = player_ref.current_xp
		_update_minimap()

func _update_minimap():
	if not minimap_canvas or not player_ref:
		return
	for c in minimap_canvas.get_children():
		if c != minimap_player_marker:
			c.queue_free()
	var ts = float(minimap_size) / max(map_width, map_height)
	var ox = (minimap_size - map_width * ts) / 2
	var oy = (minimap_size - map_height * ts) / 2
	if walkable_map_ref.size() > 0:
		for y in range(map_height):
			for x in range(map_width):
				if y < walkable_map_ref.size() and x < walkable_map_ref[y].size():
					var tv = walkable_map_ref[y][x]
					var tr = ColorRect.new()
					tr.custom_minimum_size = Vector2(max(ts - 1, 1), max(ts - 1, 1))
					tr.position = Vector2(ox + x * ts, oy + y * ts)
					tr.color = Color(0.3, 0.2, 0.2, 1) if tv < 0 else Color(0.2, 0.2, 0.25, 1)
					minimap_canvas.add_child(tr)
	var px = player_ref.grid_position.x
	var py = player_ref.grid_position.y
	minimap_player_marker.position = Vector2(ox + px * ts - 4, oy + py * ts - 4)
	if minimap_panel:
		var l = minimap_panel.get_node_or_null("CoordLabel")
		if l:
			l.text = "X: %d Y: %d" % [px, py]
