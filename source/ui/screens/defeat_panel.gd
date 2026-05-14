# defeat_panel.gd - Game over screen shown on combat defeat.
# Shows DEFEAT message with restart option.
# Created dynamically by GameLoop when player dies in combat.
extends CanvasLayer

## Signal emitted when player chooses to restart.
signal restart_requested()


func _ready() -> void:
	layer = 10  # Above HUD
	_show_defeat_screen()


func _show_defeat_screen() -> void:
	# Dim background
	var dim := ColorRect.new()
	dim.name = "DimOverlay"
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# Center anchor for screen-center layout
	var center_anchor := Control.new()
	center_anchor.name = "CenterAnchor"
	center_anchor.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center_anchor.size = Vector2(400, 300)
	add_child(center_anchor)

	# VBox inside center anchor
	var vbox := VBoxContainer.new()
	vbox.name = "CenterBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	center_anchor.add_child(vbox)

	# DEFEAT title
	var title := Label.new()
	title.name = "DefeatTitle"
	title.text = "DEFEAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "You have fallen in battle..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(subtitle)

	# Stretch spacer to push button down
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND
	vbox.add_child(spacer)

	# Restart button row (centered)
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var restart_btn := Button.new()
	restart_btn.name = "RestartButton"
	restart_btn.text = "Restart"
	restart_btn.custom_minimum_size = Vector2(200, 50)
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.pressed.connect(_on_restart_pressed)
	hbox.add_child(restart_btn)

	# Animate in
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)


func _on_restart_pressed() -> void:
	restart_requested.emit()
