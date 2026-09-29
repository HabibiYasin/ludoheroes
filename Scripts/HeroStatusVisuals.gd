extends Node2D

const Catalog = preload("res://Scripts/HeroStatus.gd")
var hero: Piece
var markers: Array[Node2D] = []
var phase := 0.0

func _ready() -> void:
	hero = get_parent()
	z_index = 15
	hero.StatsChanged.connect(refresh)
	refresh()

func refresh() -> void:
	for marker in markers:
		marker.free()
	markers.clear()
	for id: String in hero.Status.effects:
		var marker := Node2D.new()
		marker.name = id.replace(" ", "")
		var icon := Sprite2D.new()
		icon.texture = load(Catalog.ASSET_PATH + Catalog.DEFINITIONS[id].file)
		icon.scale = Vector2.ONE * 80.0 / float(maxi(icon.texture.get_width(), icon.texture.get_height()))
		marker.add_child(icon)
		var turns: int = hero.Status.effects[id].turns
		if id == "Cursed":
			turns = 4 - int(hero.Status.effects[id].elapsed)
		if turns > 0:
			var label := Label.new()
			label.text = "%dt" % turns
			label.position = Vector2(14, 8)
			label.add_theme_font_size_override("font_size", 24)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 4)
			marker.add_child(label)
		add_child(marker)
		markers.append(marker)
	_process(0.0)

func _process(delta: float) -> void:
	if hero.PieceSprite == null or hero.PieceSprite.texture == null or markers.is_empty():
		return
	phase += delta
	# Follow the rendered sprite, including selection pulses and shared-cell offsets.
	# Screen-facing markers remain readable under every board rotation.
	global_rotation = 0.0
	var board_scale: float = hero.get_parent().global_scale.abs().x if hero.get_parent() != null else 1.0
	global_scale = Vector2.ONE * board_scale
	var bounds := hero.PieceSprite.get_rect()
	global_position = hero.PieceSprite.to_global(Vector2(bounds.get_center().x, bounds.position.y))
	for index in range(markers.size()):
		var row := index / 5
		var row_count := mini(5, markers.size() - row * 5)
		markers[index].position = Vector2((index % 5 - (row_count - 1) * 0.5) * 68.0, -35.0 - row * 68.0 + sin(phase * 2.0) * 2.0)
