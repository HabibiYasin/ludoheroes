extends CanvasLayer

const Heroes = preload("res://Scripts/HeroCatalog.gd")
const Items = preload("res://Scripts/ItemCatalog.gd")
const Skills = preload("res://Scripts/SkillCatalog.gd")
const Data = preload("res://Scripts/KnowledgeData.gd")
const GREEN := Color("60b4a7")
const DARK := Color("102d31")
const LIGHT := Color("e6f4ed")
var root: Control
var page: Control
var popup: Control
var tabs: Array[Button] = []
var previous_pause := false
var section := 0
var equipment_detail: Control
var equipment_buttons: Array[Button] = []
var selected_item := -1
var article_body: RichTextLabel
var article_buttons: Array[Button] = []

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_pause = get_tree().paused
	get_tree().paused = true
	var blocker := ColorRect.new()
	blocker.color = DARK
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(blocker)
	root = Control.new()
	root.size = Vector2(1920, 1080)
	add_child(root)
	_picture(root, Rect2(0, 0, 1920, 1080), preload("res://Arts/Textures_Game/Background/background.png"))
	var veil := ColorRect.new()
	veil.color = Color(0.025, 0.08, 0.09, 0.78)
	veil.size = root.size
	root.add_child(veil)
	_button(root, "‹  Kembali", Rect2(55, 50, 280, 76), close)
	_label(root, "KNOWLEDGE", Rect2(65, 190, 390, 60), 42, GREEN)
	_label(root, "Panduan Ludo Heroes", Rect2(65, 252, 390, 45), 26, LIGHT)
	for index in range(3):
		tabs.append(_button(root, ["Hero", "Equipment", "Ensiklopedia"][index], Rect2(55, 355 + index * 115, 395, 90), show_section.bind(index)))
	_label(root, "Kenali hero. Susun strategi.", Rect2(65, 940, 390, 50), 24, GREEN)
	get_viewport().size_changed.connect(_resize)
	_resize()
	show_section(0)

func _resize() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var fit := minf(viewport.x / 1920.0, viewport.y / 1080.0)
	root.scale = Vector2.ONE * fit
	root.position = (viewport - root.size * fit) * 0.5

func close() -> void:
	get_tree().paused = previous_pause
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(popup):
			close_popup()
		else:
			close()
		get_viewport().set_input_as_handled()

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(18)
	style.set_border_width_all(2)
	style.border_color = GREEN
	return style

func _panel(parent: Node, bounds: Rect2, color: Color = DARK) -> Panel:
	var panel := Panel.new()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.add_theme_stylebox_override("panel", _style(color))
	parent.add_child(panel)
	return panel

func _label(parent: Node, text: String, bounds: Rect2, size: int, color: Color = LIGHT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = bounds.position
	label.size = bounds.size
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, bounds: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = bounds.position
	button.size = bounds.size
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", LIGHT)
	button.add_theme_color_override("font_hover_color", DARK)
	button.add_theme_color_override("font_pressed_color", DARK)
	button.add_theme_stylebox_override("normal", _style(DARK))
	button.add_theme_stylebox_override("hover", _style(GREEN))
	button.add_theme_stylebox_override("pressed", _style(GREEN.lightened(0.1)))
	button.add_theme_stylebox_override("focus", _style(Color(0.38, 0.7, 0.65, 0.25)))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _picture(parent: Node, bounds: Rect2, texture: Texture2D) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.texture = texture
	picture.position = bounds.position
	picture.size = bounds.size
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _text(parent: Node, text: String, bounds: Rect2, size: int = 28) -> RichTextLabel:
	var body := RichTextLabel.new()
	body.position = bounds.position
	body.size = bounds.size
	body.text = text
	body.add_theme_font_size_override("normal_font_size", size)
	body.add_theme_color_override("default_color", LIGHT)
	body.add_theme_constant_override("line_separation", 9)
	parent.add_child(body)
	return body

func show_section(index: int) -> void:
	close_popup()
	section = index
	if is_instance_valid(page):
		page.free()
	page = _panel(root, Rect2(495, 50, 1370, 980), Color("173e40"))
	for i in range(tabs.size()):
		tabs[i].add_theme_stylebox_override("normal", _style(GREEN if i == index else DARK))
		tabs[i].add_theme_color_override("font_color", DARK if i == index else LIGHT)
	match index:
		0: _heroes()
		1: _equipment()
		2: _encyclopedia()

func _heroes() -> void:
	_label(page, "HERO", Rect2(30, 20, 500, 55), 38, GREEN)
	_label(page, "16 hero • 4 faksi • Ketuk hero untuk detail", Rect2(30, 78, 1100, 40), 26)
	var factions := ["Astherion", "Nerathis", "Thornvale", "Nekravia"]
	for row in range(factions.size()):
		var faction: String = factions[row]
		var y := 140 + row * 202
		_picture(page, Rect2(22, y, 170, 157), load("res://Arts/Textures_Game/Board/%s Finish.png" % faction))
		var name_label := _label(page, faction, Rect2(15, y + 157, 185, 36), 25, GREEN)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var column := 0
		for id: String in Heroes.HEROES:
			if Heroes.HEROES[id][1] != faction:
				continue
			var card := _button(page, "", Rect2(215 + column * 280, y, 265, 188), show_hero.bind(id))
			card.name = id
			card.tooltip_text = "%s · %s" % [id, Heroes.HEROES[id][0]]
			_picture(card, Rect2(40, 5, 185, 137), Data.hero_texture(id))
			var caption := _label(card, id, Rect2(10, 145, 245, 35), 27)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			column += 1

func show_hero(id: String) -> void:
	close_popup()
	popup = Control.new()
	popup.size = root.size
	root.add_child(popup)
	var shade := ColorRect.new()
	shade.size = root.size
	shade.color = Color(0, 0, 0, 0.75)
	popup.add_child(shade)
	var panel := _panel(popup, Rect2(355, 70, 1330, 940), DARK)
	_label(panel, "DETAIL HERO", Rect2(40, 24, 900, 60), 36, GREEN)
	_button(panel, "×", Rect2(1220, 20, 75, 70), close_popup)
	var stats: Array = Heroes.HEROES[id]
	_label(panel, id, Rect2(50, 110, 460, 70), 48)
	_picture(panel, Rect2(45, 210, 440, 550), Data.hero_texture(id))
	_label(panel, "%s  /  %s" % [stats[1], stats[0]], Rect2(50, 800, 500, 50), 29, GREEN)
	_label(panel, "ATRIBUT DASAR", Rect2(555, 120, 680, 45), 31, GREEN)
	_text(panel, "HP  %d     •     Attack  %d\nPhysical Defense  %d\nMagical Defense  %d\nMove Bonus  +0     •     Skill Damage  +0" % [stats[3], stats[2], stats[4], stats[5]], Rect2(555, 180, 710, 210), 30)
	var skill: Dictionary = Skills.get_skill(id)
	_picture(panel, Rect2(550, 420, 80, 80), preload("res://Arts/Textures_Game/UI/Controller/skills.png"))
	_label(panel, skill.name, Rect2(655, 432, 620, 62), 34, GREEN)
	var dice_values := PackedStringArray()
	for value in skill.dice:
		dice_values.append(str(value))
	var range_text := "Diri sendiri" if skill.front == 0 and skill.behind == 0 else "Depan %d / Belakang %d" % [skill.front, skill.behind]
	_text(panel, "Dadu: %s   •   Cooldown: %d\nJangkauan: %s\n\n%s" % [" / ".join(dice_values), skill.cooldown, range_text, Data.skill_description(id)], Rect2(555, 520, 710, 355))

func close_popup() -> void:
	if is_instance_valid(popup):
		popup.free()
	popup = null

func _equipment() -> void:
	equipment_buttons.clear()
	_label(page, "EQUIPMENT", Rect2(30, 20, 700, 60), 38, GREEN)
	for id in range(Items.NAMES.size()):
		var button := _button(page, "", Rect2(30, 105 + id * 137, 180, 122), select_item.bind(id))
		button.tooltip_text = Items.NAMES[id]
		_picture(button, Rect2(32, 6, 116, 110), Items.texture(id))
		equipment_buttons.append(button)
	equipment_detail = Control.new()
	equipment_detail.position = Vector2(245, 110)
	page.add_child(equipment_detail)
	select_item(0)

func select_item(id: int) -> void:
	selected_item = id
	for child in equipment_detail.get_children():
		child.free()
	for i in range(equipment_buttons.size()):
		equipment_buttons[i].add_theme_stylebox_override("normal", _style(GREEN if i == id else DARK))
	_label(equipment_detail, Items.NAMES[id], Rect2(20, 30, 1050, 80), 48, GREEN)
	_picture(equipment_detail, Rect2(20, 180, 460, 460), Items.texture(id))
	_label(equipment_detail, "EFEK PER STACK", Rect2(530, 190, 550, 50), 30, GREEN)
	_text(equipment_detail, "%s\n\nDapat ditumpuk untuk menambah atribut yang sama.\n\nHero dapat membawa dua jenis equipment. Item tetap tersimpan setelah hero kalah.%s" % [Items.EFFECTS[id], "\n\nHP maksimum bertambah; HP saat ini tidak langsung dipulihkan." if id == 1 else ""], Rect2(530, 260, 540, 510), 30)

func _encyclopedia() -> void:
	_label(page, "ENSIKLOPEDIA", Rect2(30, 20, 1100, 60), 38, GREEN)
	article_buttons.clear()
	var index := 0
	for title: String in Data.ARTICLES:
		var button := _button(page, title, Rect2(28 + index * 220, 105, 207, 76), select_article.bind(title))
		button.add_theme_font_size_override("font_size", 25)
		article_buttons.append(button)
		index += 1
	article_body = _text(page, "", Rect2(45, 220, 1280, 700), 30)
	select_article("Peraturan")

func select_article(title: String) -> void:
	article_body.text = Data.ARTICLES[title]
	article_body.scroll_to_line(0)
	for button in article_buttons:
		button.add_theme_stylebox_override("normal", _style(GREEN if button.text == title else DARK))
		button.add_theme_color_override("font_color", DARK if button.text == title else LIGHT)
