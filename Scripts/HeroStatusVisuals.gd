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
	if hero.PieceSprite != null:
		hero.PieceSprite.modulate.a = 0.45 if hero.HasStatus("Hidden") else 1.0
	for marker in markers:
		marker.free()
	markers.clear()
	for id: String in hero.Status.effects:
		var marker := Node2D.new()
		marker.name = id.replace(" ", "")
		marker.set_meta("above_head", id in ["Stun", "Confused"])
		var icon := Sprite2D.new()
		if not String(Catalog.DEFINITIONS[id].file).is_empty():
			icon.texture = load(Catalog.ASSET_PATH + Catalog.DEFINITIONS[id].file)
			icon.scale = Vector2.ONE * 80.0 / float(maxi(icon.texture.get_width(), icon.texture.get_height()))
			marker.add_child(icon)
		else:
			icon.free()
			var hidden_label := Label.new()
			hidden_label.text = "HIDDEN"
			hidden_label.position = Vector2(-40, -15)
			hidden_label.add_theme_font_size_override("font_size", 22)
			hidden_label.add_theme_color_override("font_outline_color", Color.BLACK)
			hidden_label.add_theme_constant_override("outline_size", 5)
			marker.add_child(hidden_label)
		var turns: int = hero.Status.effects[id].turns
		var charges: int = hero.Status.effects[id].get("charges", 0)
		if id == "Cursed":
			turns = 4 - int(hero.Status.effects[id].elapsed)
		if turns > 0 or charges > 0:
			var label := Label.new()
			label.text = "%dx" % charges if charges > 0 else "%dt" % turns
			if id == "Nature Shield":
				label.text = "%d" % charges
			label.name = "Counter"
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
	var head_count := 0
	for marker in markers:
		if marker.get_meta("above_head"):
			head_count += 1
	var head_index := 0
	var body_index := 0
	var body_center := to_local(hero.PieceSprite.to_global(bounds.get_center()))
	var body_size := bounds.size * hero.PieceSprite.global_scale.abs() / global_scale.abs()
	for marker in markers:
		if marker.get_meta("above_head"):
			marker.position = Vector2((head_index - (head_count - 1) * 0.5) * 68.0, -35.0 + sin(phase * 2.0) * 2.0)
			head_index += 1
		else:
			marker.position = body_center
			var icon := marker.get_child(0) as Sprite2D
			if icon != null:
				icon.scale = body_size / icon.texture.get_size()
			var counter := marker.get_node_or_null("Counter") as Label
			if counter != null:
				counter.position = Vector2(body_size.x * 0.4, -body_size.y * 0.5 + body_index * 26.0)
				body_index += 1
