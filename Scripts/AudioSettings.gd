extends VBoxContainer

var controls: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	for channel in GameAudio.CHANNELS:
		var title := Label.new()
		title.text = "Volume " + channel
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 26)
		add_child(title)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		add_child(row)
		var left := _button("<", row)
		left.tooltip_text = "Kurangi volume " + channel
		var level := Label.new()
		level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level.add_theme_font_size_override("font_size", 28)
		row.add_child(level)
		var right := _button(">", row)
		right.tooltip_text = "Tambah volume " + channel
		var mute := _button("Mute", row)
		mute.custom_minimum_size.x = 138
		mute.toggle_mode = true
		left.pressed.connect(func(): GameAudio.set_level(channel, GameAudio.levels[channel] - 1))
		right.pressed.connect(func(): GameAudio.set_level(channel, GameAudio.levels[channel] + 1))
		mute.pressed.connect(func(): GameAudio.set_muted(channel, not GameAudio.muted[channel]))
		controls[channel] = {"left": left, "right": right, "level": level, "mute": mute}
	GameAudio.settings_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for channel in controls:
		var row: Dictionary = controls[channel]
		row.level.text = "%d / 5" % GameAudio.levels[channel]
		row.left.disabled = GameAudio.levels[channel] == 1
		row.right.disabled = GameAudio.levels[channel] == 5
		row.mute.set_pressed_no_signal(GameAudio.muted[channel])
		row.mute.text = "Unmute" if GameAudio.muted[channel] else "Mute"

func _button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(70, 64)
	button.add_theme_font_size_override("font_size", 26)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f4c563") if state == "normal" else Color("ffdc8a")
		if state == "pressed":
			style.bg_color = Color("ce9c42")
		elif state == "disabled":
			style.bg_color = Color("304059")
		style.set_corner_radius_all(12)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("17243c"))
	parent.add_child(button)
	return button
