extends CanvasLayer

const GOLD := Color("f4c563")
const INK := Color("17243c")
var root: Control
var hero_icon: TextureRect
var hero_name: Label
var modal: ColorRect
var menu_panel: Panel
var settings_panel: Panel
var reactions: Panel
var emote: Label
var emote_timer: Timer
var config := ConfigFile.new()
var settings_dirty := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_button(root, "MENU", Rect2(40, 40, 220, 78), _open_menu)
	var hero := _panel(root, Rect2(40, 170, 380, 580))
	_label(hero, "HERO DIPILIH", Rect2(20, 16, 340, 34), 24, GOLD)
	hero_icon = _picture(hero, Rect2(65, 55, 250, 245), null)
	hero_name = _label(hero, "Ketuk hero di papan", Rect2(10, 305, 360, 42), 30)
	_label(hero, "HP  — / —     ATK  —", Rect2(10, 355, 360, 38), 27)
	_label(hero, "SKILLS                 ITEMS", Rect2(20, 412, 340, 32), 22, GOLD)
	for i in range(4):
		var slot := _panel(hero, Rect2(28 + i * 84, 455, 72, 64), Color("304059"))
		_label(slot, "—", Rect2(0, 8, 72, 44), 30)
	_label(hero, "Statistik, skill & item segera hadir", Rect2(10, 535, 360, 30), 19, Color("aab8d0"))
	var colors := [Color("29975a"), Color("e7ba19"), Color("168ccd"), Color("d93c40")]
	var color_names := ["HIJAU", "KUNING", "BIRU", "MERAH"]
	var player_order: Array[int] = []
	for color in [2, 3, 1, 0]:
		if color != int(GameManager.LocalPlayerColor):
			player_order.append(color)
	player_order.append(int(GameManager.LocalPlayerColor))
	for i in range(4):
		var local_player := i == 3
		var bounds := Rect2(1580, 40 + i * 222, 220, 206)
		if local_player:
			bounds = Rect2(1510, 722, 360, 318)
		var player_color := player_order[i]
		var card := _panel(root, bounds, colors[player_color])
		card.name = "PlayerCard%d" % player_color
		var image_bounds := Rect2(25, 12, 170, 154)
		if local_player:
			image_bounds = Rect2(55, 12, 250, 218)
		_picture(card, image_bounds, load("res://Arts/Player/player %d.jpg" % (i + 1)))
		_label(card, ("KAMU · " if local_player else "BOT · ") + color_names[player_color], Rect2(0, bounds.size.y - 40 if not local_player else 230, bounds.size.x, 32), 23)
		if local_player:
			_button(card, "REACT  :)", Rect2(100, 266, 160, 44), func(): reactions.visible = not reactions.visible)
	emote = _label(root, "", Rect2(1500, 665, 380, 56), 34, GOLD)
	emote.add_theme_stylebox_override("normal", _style(INK))
	emote.hide()
	emote_timer = Timer.new()
	emote_timer.one_shot = true
	emote_timer.wait_time = 3.0
	emote_timer.timeout.connect(emote.hide)
	add_child(emote_timer)
	reactions = _panel(root, Rect2(1500, 548, 380, 164))
	for i in range(4):
		var reaction: String = [":)  Senang", "GG!", ":O  Wow", ":(  Sedih"][i]
		_button(reactions, reaction, Rect2(12 + (i % 2) * 184, 12 + (i / 2) * 72, 172, 62), _react.bind(reaction))
	reactions.hide()
	_build_menu()
	GameManager.HeroInspected.connect(_inspect_hero)
	get_viewport().size_changed.connect(_resize)
	_resize()

func _resize() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	root.scale = Vector2.ONE * fit
	root.position = (viewport_size - Vector2(1920, 1080) * fit) * 0.5
	if modal != null:
		modal.position = -root.position / fit
		modal.size = viewport_size / fit

func _inspect_hero(piece: Piece) -> void:
	hero_icon.texture = piece.PieceSprite.texture
	hero_name.text = hero_icon.texture.resource_path.get_file().get_basename()

func _react(value: String) -> void:
	reactions.hide()
	emote.text = value
	emote.show()
	emote_timer.start()

func _build_menu() -> void:
	modal = ColorRect.new()
	modal.color = Color(0, 0, 0, 0.72)
	root.add_child(modal)
	menu_panel = _panel(root, Rect2(650, 280, 620, 520))
	menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(menu_panel, "MENU", Rect2(20, 30, 580, 60), 40, GOLD)
	_button(menu_panel, "Lanjutkan", Rect2(60, 125, 500, 80), _close_menu)
	_button(menu_panel, "Settings", Rect2(60, 235, 500, 80), func(): menu_panel.hide(); settings_panel.show())
	_button(menu_panel, "Exit", Rect2(60, 345, 500, 80), func(): get_tree().quit())
	settings_panel = _panel(root, Rect2(650, 280, 620, 520))
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(settings_panel, "SETTINGS", Rect2(20, 30, 580, 60), 40, GOLD)
	_label(settings_panel, "Volume suara", Rect2(40, 130, 540, 50), 30)
	config.load("user://settings.cfg")
	var volume := HSlider.new()
	volume.position = Vector2(60, 215)
	volume.size = Vector2(500, 70)
	volume.max_value = 100
	volume.value = float(config.get_value("audio", "volume", 80))
	settings_panel.add_child(volume)
	volume.value_changed.connect(_volume_changed)
	_button(settings_panel, "Kembali", Rect2(60, 345, 500, 80), func(): settings_panel.hide(); menu_panel.show())
	modal.hide()
	menu_panel.hide()
	settings_panel.hide()

func _volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.0001)))
	AudioServer.set_bus_mute(0, value == 0)
	config.set_value("audio", "volume", value)
	settings_dirty = true

func _open_menu() -> void:
	reactions.hide()
	modal.show()
	menu_panel.show()
	get_tree().paused = true

func _close_menu() -> void:
	if settings_dirty:
		var error := config.save("user://settings.cfg")
		if error != OK:
			push_warning("Pengaturan tidak dapat disimpan: %s" % error_string(error))
		else:
			settings_dirty = false
	modal.hide()
	menu_panel.hide()
	settings_panel.hide()
	get_tree().paused = false

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if modal.visible:
			_close_menu()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(18)
	return style

func _panel(parent: Node, bounds: Rect2, color: Color = Color("17243ce8")) -> Panel:
	var panel := Panel.new()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(color))
	parent.add_child(panel)
	return panel

func _label(parent: Node, value: String, bounds: Rect2, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.position = bounds.position
	label.size = bounds.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _picture(parent: Node, bounds: Rect2, texture: Texture2D) -> TextureRect:
	var picture := TextureRect.new()
	picture.position = bounds.position
	picture.size = bounds.size
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _button(parent: Node, value: String, bounds: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.position = bounds.position
	button.size = bounds.size
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_stylebox_override("normal", _style(GOLD))
	button.add_theme_stylebox_override("hover", _style(Color("ffdc8a")))
	button.add_theme_stylebox_override("pressed", _style(Color("ce9c42")))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, INK)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
