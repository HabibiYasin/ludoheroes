extends Button

signal quick_cast
signal choose_targets
const HOLD_SECONDS := 0.45
var _elapsed := 0.0
var _holding := false
var _long_press := false

func _ready() -> void:
	tooltip_text = "Klik: gunakan skill otomatis\nTahan: pilih target"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.04, 0.16, 0.85)
		style.set_corner_radius_all(45)
		style.set_border_width_all(3)
		style.border_color = Color("b97bff")
		add_theme_stylebox_override(state, style)
	var icon := TextureRect.new()
	icon.texture = preload("res://Arts/Textures_Game/UI/Controller/skills.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate.a = 0.8
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 7
	icon.offset_top = 7
	icon.offset_right = -7
	icon.offset_bottom = -7
	button_down.connect(func():
		_holding = true
		_long_press = false
		_elapsed = 0.0)
	button_up.connect(func(): _holding = false)
	pressed.connect(func():
		if not _long_press:
			quick_cast.emit())
	mouse_exited.connect(func(): _holding = false)

func _process(delta: float) -> void:
	if not visible or disabled:
		_holding = false
	if not _holding or _long_press:
		return
	_elapsed += delta
	if _elapsed >= HOLD_SECONDS:
		_long_press = true
		_holding = false
		choose_targets.emit()
