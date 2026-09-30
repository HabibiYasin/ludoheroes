extends CanvasLayer

signal completed(targets: Array[Piece])
var stage: Control
var selected: Array[Piece] = []
var limit := 1
var confirm: Button
var was_paused := false

func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS

func choose(hero: Piece, manager: Node) -> Array[Piece]:
	if stage != null:
		return []
	var candidates: Array[Piece] = manager.candidates(hero)
	if candidates.is_empty():
		return []
	var skill: Dictionary = manager.definition(hero)
	limit = mini(int(skill.targets), candidates.size())
	selected.clear()
	was_paused = get_tree().paused
	get_tree().paused = true
	stage = Control.new()
	stage.size = Vector2(1920, 1080)
	add_child(stage)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.06, 0.94)
	shade.size = stage.size
	stage.add_child(shade)
	var title := Label.new()
	title.text = "%s\nPilih hingga %d target" % [skill.name, limit]
	title.position = Vector2(280, 50)
	title.size = Vector2(1360, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	stage.add_child(title)
	for index in range(candidates.size()):
		var target := candidates[index]
		var angle := -PI * 0.5 + TAU * index / candidates.size()
		var radius := 0.0 if candidates.size() == 1 else 270.0
		var button = preload("res://Scripts/HUDPortrait.gd").new()
		button.size = Vector2(130, 130)
		button.position = Vector2(960, 515) + Vector2(cos(angle), sin(angle)) * radius - button.size * 0.5
		stage.add_child(button)
		button.portrait.texture = target.PieceSprite.texture
		button.background.texture = load("res://Arts/Textures_Game/Board/%sBattle.png" % target.Faction)
		button.tooltip_text = "%s - HP %d/%d" % [target.HeroId, target.Health, target.MaxHealth]
		button.pressed.connect(_toggle.bind(target, button))
		var label := Label.new()
		label.text = "%s\n%d/%d HP" % [target.HeroId, target.Health, target.MaxHealth]
		label.position = button.position + Vector2(-35, 132)
		label.size = Vector2(200, 60)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		stage.add_child(label)
	confirm = _button("Gunakan skill", Vector2(985, 955), func(): _finish(selected.duplicate()))
	confirm.disabled = true
	_button("Batal", Vector2(635, 955), func(): _finish([]))
	_process(0.0)
	var result: Array[Piece] = await completed
	return result

func _toggle(hero: Piece, button: Button) -> void:
	if selected.has(hero):
		selected.erase(hero)
		button.ring_color = Color.WHITE
	elif selected.size() < limit:
		selected.append(hero)
		button.ring_color = Color("65ff9b")
	confirm.disabled = selected.is_empty()
	confirm.text = "Gunakan (%d/%d)" % [selected.size(), limit]

func _button(text: String, pos: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(300, 75)
	button.add_theme_font_size_override("font_size", 28)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("edc46b")
	style.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_color_override("font_color", Color("18233c"))
	button.pressed.connect(callback)
	stage.add_child(button)
	return button

func _finish(targets: Array[Piece]) -> void:
	if stage == null:
		return
	stage.queue_free()
	stage = null
	get_tree().paused = was_paused
	completed.emit(targets)

func _unhandled_input(event: InputEvent) -> void:
	if stage != null and event.is_action_pressed("ui_cancel"):
		_finish([])
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if stage == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var fit := minf(viewport.x / 1920.0, viewport.y / 1080.0)
	stage.scale = Vector2.ONE * fit
	stage.position = (viewport - Vector2(1920, 1080) * fit) * 0.5
