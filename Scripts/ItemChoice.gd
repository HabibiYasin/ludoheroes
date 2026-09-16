extends CanvasLayer

const Catalog = preload("res://Scripts/ItemCatalog.gd")
signal selected(id: int)
var stage: Control
var remaining := 0.0
var offered: Array[int] = []
var countdown: Label

func _ready() -> void:
	layer = 1
	get_viewport().size_changed.connect(_resize)

func choose(hero: Piece, choices: Array[int], timeout_seconds: float = 10.0) -> int:
	offered = choices
	remaining = timeout_seconds
	stage = Control.new()
	add_child(stage)
	var shade := ColorRect.new()
	shade.color = Color(0.95, 0.94, 0.90, 0.7)
	shade.position = Vector2(460, 40)
	shade.size = Vector2(1000, 1000)
	stage.add_child(shade)
	_label("PILIH ITEM UNTUK %s" % hero.HeroId, Vector2(470, 195), Vector2(980, 65), 34)
	countdown = _label("", Vector2(470, 825), Vector2(980, 60), 25)
	for index in range(2):
		var id := choices[index]
		var x := 530.0 + index * 460.0
		_label(Catalog.EFFECTS[id], Vector2(x, 300), Vector2(400, 65), 30)
		var button := TextureButton.new()
		button.texture_normal = Catalog.texture(id)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.position = Vector2(x, 380)
		button.size = Vector2(400, 360)
		button.tooltip_text = Catalog.NAMES[id] + "\n" + Catalog.EFFECTS[id]
		button.pressed.connect(_select.bind(id, true))
		stage.add_child(button)
		_label(Catalog.NAMES[id], Vector2(x, 750), Vector2(400, 50), 26)
	_resize()
	var id: int = await selected
	stage.queue_free()
	stage = null
	offered = []
	return id

func _select(id: int, manual: bool = false) -> void:
	if stage == null or not offered.has(id):
		return
	offered = []
	if manual:
		get_parent().ManualAction.emit()
	selected.emit(id)

func _process(delta: float) -> void:
	if stage == null or offered.is_empty():
		return
	remaining -= delta
	countdown.text = "Dipilih otomatis dalam %d detik" % ceili(maxf(remaining, 0.0))
	if remaining <= 0:
		_select(offered.pick_random())

func _resize() -> void:
	if stage == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var fit := minf(viewport.x / 1920.0, viewport.y / 1080.0)
	stage.scale = Vector2.ONE * fit
	stage.position = (viewport - Vector2(1920, 1080) * fit) * 0.5

func _label(value: String, pos: Vector2, bounds: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = bounds
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("17243c"))
	stage.add_child(label)
	return label
