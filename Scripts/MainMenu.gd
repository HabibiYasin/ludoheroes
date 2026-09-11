extends Control

const SETTINGS_PATH := "user://settings.cfg"
const GAME_SCENE := "res://Levels/Level_MainGamePlay.tscn"
const INK := Color("17243c")
const GOLD := Color("f4c563")

var _home: VBoxContainer
var _settings: VBoxContainer
var _color_selection: VBoxContainer
var _start: Button
var _volume: HSlider
var _fullscreen: CheckButton
var _config := ConfigFile.new()

func _ready() -> void:
	_config.load(SETTINGS_PATH)
	var background := ColorRect.new()
	background.color = Color("0c1425")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	panel.add_theme_stylebox_override("panel", _style(INK, 28, 28))
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)
	var colors := HBoxContainer.new()
	colors.alignment = BoxContainer.ALIGNMENT_CENTER
	colors.add_theme_constant_override("separation", 8)
	content.add_child(colors)
	for color in [Color("55c79a"), GOLD, Color("659cf3"), Color("f0777e")]:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(48, 6)
		chip.add_theme_stylebox_override("panel", _style(color, 3, 0))
		colors.add_child(chip)
	content.add_child(_label("LUDO", 52, Color.WHITE))
	content.add_child(_label("Dua dadu. Banyak kemungkinan.", 16, Color("aab8d0")))
	var dice_row := HBoxContainer.new()
	dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_row.add_theme_constant_override("separation", 14)
	content.add_child(dice_row)
	for face in [3, 6]:
		var die := TextureRect.new()
		die.texture = load("res://Arts/Textures_Game/Dices/Dice_%d.png" % face)
		die.custom_minimum_size = Vector2(96, 96)
		die.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		die.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dice_row.add_child(die)
	_home = VBoxContainer.new()
	_home.add_theme_constant_override("separation", 10)
	content.add_child(_home)
	_start = _button("Start", _show_color_selection, true)
	_home.add_child(_start)
	_home.add_child(_button("Settings", _show_settings))
	_home.add_child(_button("Exit", func(): get_tree().quit()))
	_color_selection = VBoxContainer.new()
	_color_selection.add_theme_constant_override("separation", 10)
	content.add_child(_color_selection)
	_color_selection.add_child(_label("PILIH WARNA KAMU", 24, Color.WHITE))
	var color_grid := GridContainer.new()
	color_grid.columns = 2
	color_grid.add_theme_constant_override("h_separation", 16)
	color_grid.add_theme_constant_override("v_separation", 16)
	_color_selection.add_child(color_grid)
	var palette := [Color("29975a"), Color("e7ba19"), Color("168ccd"), Color("d93c40")]
	for index in range(4):
		var choice := _button(["Hijau", "Kuning", "Biru", "Merah"][index], _choose_color.bind(index))
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.custom_minimum_size = Vector2(280, 90)
		choice.add_theme_stylebox_override("normal", _style(palette[index], 12, 10))
		choice.add_theme_color_override("font_color", INK if index == 1 else Color.WHITE)
		color_grid.add_child(choice)
	_color_selection.add_child(_button("Kembali", _cancel_color_selection))
	_color_selection.hide()
	_settings = VBoxContainer.new()
	_settings.add_theme_constant_override("separation", 12)
	_settings.hide()
	content.add_child(_settings)
	_settings.add_child(_label("SETTINGS", 20, Color.WHITE))
	_settings.add_child(_label("Volume suara", 16, Color("aab8d0")))
	_volume = HSlider.new()
	_volume.custom_minimum_size.y = 64
	_volume.min_value = 0
	_volume.max_value = 100
	_volume.step = 1
	_volume.value = clampf(float(_config.get_value("audio", "volume", 80)), 0, 100)
	_settings.add_child(_volume)
	_apply_volume(_volume.value)
	_volume.value_changed.connect(_apply_volume)
	_fullscreen = CheckButton.new()
	_fullscreen.text = "Layar penuh"
	_fullscreen.add_theme_font_size_override("font_size", 28)
	_fullscreen.custom_minimum_size.y = 64
	_fullscreen.button_pressed = bool(_config.get_value("display", "fullscreen", false))
	_settings.add_child(_fullscreen)
	_apply_fullscreen(_fullscreen.button_pressed)
	_fullscreen.toggled.connect(_apply_fullscreen)
	_settings.add_child(_button("Back", _show_home, true))
	content.add_child(_label("MAIN BERSAMA • 2 DADU PER GILIRAN", 12, Color("8394b2")))
	_start.grab_focus()

func _style(color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", roundi(font_size * 1.5))
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 84
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else Color("24344f"), 12, 10))
	button.add_theme_stylebox_override("hover", _style(Color("ffdb91") if primary else Color("354c70"), 12, 10))
	button.add_theme_stylebox_override("pressed", _style(Color("d8a94b") if primary else Color("1c2c44"), 12, 10))
	var focus := _style(Color.TRANSPARENT, 12, 10)
	focus.set_border_width_all(2)
	focus.border_color = Color.WHITE
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK if primary else Color.WHITE)
	button.pressed.connect(action)
	return button

func _show_settings() -> void:
	_home.hide()
	_settings.show()
	_volume.grab_focus()

func _show_color_selection() -> void:
	_home.hide()
	_color_selection.show()
	_color_selection.get_child(1).get_child(0).grab_focus()

func _cancel_color_selection() -> void:
	_color_selection.hide()
	_home.show()
	_start.grab_focus()

func _choose_color(color: GameManager.PlayerColor) -> void:
	GameManager.LocalPlayerColor = color
	_start_game()

func _show_home() -> void:
	_save_settings()
	_settings.hide()
	_home.show()
	_start.grab_focus()

func _apply_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.0001)))
	AudioServer.set_bus_mute(0, value == 0)
	_config.set_value("audio", "volume", value)

func _apply_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() != "headless" and OS.get_name() != "Android":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_config.set_value("display", "fullscreen", enabled)

func _save_settings() -> void:
	var error := _config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Pengaturan tidak dapat disimpan: %s" % error_string(error))

func _start_game() -> void:
	_start.disabled = true
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
	var error := get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		_start.disabled = false
		push_error("Game tidak dapat dibuka: %s" % error_string(error))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _color_selection.visible:
		_cancel_color_selection()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and _settings.visible:
		_show_home()
		get_viewport().set_input_as_handled()
