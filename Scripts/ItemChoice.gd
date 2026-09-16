extends CanvasLayer

const Catalog = preload("res://Scripts/ItemCatalog.gd")
const BACKGROUND = preload("res://Arts/Textures_Game/Board/Item Choose.png")
const DESIGN_SIZE := Vector2(1254, 1254)
signal selected(id: int)
var stage: Control
var remaining := 0.0
var offered: Array[int] = []
var countdown: Label
var backdrop: ColorRect
var buttons: Dictionary = {}
var entering := false
var entry_tween: Tween
var transition_zoom := 1.0:
	set(value):
		transition_zoom = value
		_resize()

func _ready() -> void:
	layer = 1
	get_viewport().size_changed.connect(_resize)

func choose(hero: Piece, choices: Array[int], timeout_seconds: float = 10.0) -> int:
	offered = choices.duplicate()
	remaining = timeout_seconds
	backdrop = ColorRect.new()
	backdrop.color = Color(0.07, 0.035, 0.015, 0.94)
	add_child(backdrop)
	stage = Control.new()
	stage.size = DESIGN_SIZE
	add_child(stage)
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = DESIGN_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(background)
	var title := _label("PILIH ITEM\nUNTUK %s" % hero.HeroId, Vector2(390, 218), Vector2(475, 72), 26)
	title.add_theme_color_override("font_color", Color("fff0ce"))
	title.add_theme_color_override("font_shadow_color", Color("351b0e"))
	title.add_theme_constant_override("shadow_offset_y", 2)
	countdown = _label("", Vector2(310, 949), Vector2(634, 65), 25)
	countdown.add_theme_color_override("font_color", Color("fff0ce"))
	countdown.add_theme_color_override("font_shadow_color", Color("351b0e"))
	countdown.add_theme_constant_override("shadow_offset_y", 2)
	_update_countdown()
	for index in range(choices.size()):
		var id := choices[index]
		var x := 0.0 if index == 0 else 670.0
		_label(Catalog.NAMES[id], Vector2(142 + x, 318), Vector2(300, 66), 29)
		var button := TextureButton.new()
		button.disabled = true
		button.texture_normal = Catalog.texture(id)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.position = Vector2(150 + x, 436)
		button.size = Vector2(284, 244)
		button.pivot_offset = button.size * 0.5
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = Catalog.NAMES[id] + "\n" + Catalog.EFFECTS[id]
		button.pressed.connect(_select.bind(id, true))
		stage.add_child(button)
		buttons[id] = button
		_label(Catalog.EFFECTS[id], Vector2(110 + x, 790), Vector2(370, 86), 30)
	entering = true
	transition_zoom = 0.96
	stage.modulate.a = 0.0
	backdrop.modulate.a = 0.0
	entry_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entry_tween.tween_property(backdrop, "modulate:a", 1.0, 0.35)
	entry_tween.tween_property(stage, "modulate:a", 1.0, 0.35)
	entry_tween.tween_property(self, "transition_zoom", 1.0, 0.4)
	entry_tween.finished.connect(func():
		entering = false
		for button: TextureButton in buttons.values():
			button.disabled = offered.is_empty()
	)
	var id: int = await selected
	stage.queue_free()
	backdrop.queue_free()
	stage = null
	backdrop = null
	buttons.clear()
	offered = []
	return id

func _select(id: int, manual: bool = false) -> void:
	if stage == null or not offered.has(id):
		return
	offered = []
	if manual:
		get_parent().ManualAction.emit()
	if entering:
		await entry_tween.finished
	countdown.text = "%s dipilih!" % Catalog.NAMES[id]
	var tween := create_tween().set_parallel(true)
	for option: int in buttons:
		var button: TextureButton = buttons[option]
		button.disabled = true
		if option == id:
			tween.tween_property(button, "scale", Vector2.ONE * 1.10, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(button, "scale", Vector2.ONE, 0.22).set_delay(0.18)
		else:
			tween.tween_property(button, "modulate", Color(0.5, 0.5, 0.5, 0.45), 0.25)
	tween.chain().tween_interval(0.15)
	await tween.finished
	var exit_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(stage, "modulate:a", 0.0, 0.3)
	exit_tween.tween_property(backdrop, "modulate:a", 0.0, 0.3)
	exit_tween.tween_property(self, "transition_zoom", 0.97, 0.3)
	await exit_tween.finished
	selected.emit(id)

func _process(delta: float) -> void:
	if stage == null or entering or offered.is_empty():
		return
	remaining -= delta
	_update_countdown()
	if remaining <= 0:
		_select(offered.pick_random())

func _update_countdown() -> void:
	countdown.text = "Dipilih otomatis dalam %d detik" % ceili(maxf(remaining, 0.0))

func _resize() -> void:
	if stage == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var fit := minf(viewport.x / DESIGN_SIZE.x, viewport.y / DESIGN_SIZE.y)
	backdrop.size = viewport
	stage.scale = Vector2.ONE * fit * transition_zoom
	stage.position = (viewport - DESIGN_SIZE * fit * transition_zoom) * 0.5

func _label(value: String, pos: Vector2, bounds: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = bounds
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("45250e"))
	stage.add_child(label)
	return label
