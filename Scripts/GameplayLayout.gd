extends Node2D

const BASE_ORIGINS := {
	"Green": Vector2(0.0, 0.6),
	"Yellow": Vector2(0.0, 0.0),
	"Blue": Vector2(0.6, 0.0),
	"Red": Vector2(0.6, 0.6),
}
var base_artworks: Array[Sprite2D] = []

func _ready() -> void:
	# Keep legacy Places hidden; static base art and turn effects are independent.
	for color_name in ["Green", "Yellow", "Blue", "Red"]:
		var place := get_node_or_null("CoreGamplay/Board/board_GamePlay/Sprite2D_Board/Sprite2D_" + color_name)
		if place != null:
			place.hide()
	_setup_base_artworks()
	var hud := CanvasLayer.new()
	hud.set_script(load("res://Scripts/GameplayHUD.gd"))
	add_child(hud)
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()

func _setup_base_artworks() -> void:
	var board_sprite: Sprite2D = $CoreGamplay/Board/board_GamePlay/Sprite2D_Board
	var artwork: Sprite2D = board_sprite.get_node("Artwork")
	var texture_size := artwork.texture.get_size()
	for color_name in BASE_ORIGINS:
		var crop := AtlasTexture.new()
		crop.atlas = artwork.texture
		crop.region = Rect2(BASE_ORIGINS[color_name] * texture_size, texture_size * 0.4)
		crop.filter_clip = true
		var base := Sprite2D.new()
		base.name = "BaseArtwork" + color_name
		base.texture = crop
		board_sprite.add_child(base)
		base_artworks.append(base)

func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	var origin := (viewport_size - Vector2(1920, 1080) * fit) * 0.5
	var board_sprite: Sprite2D = $CoreGamplay/Board/board_GamePlay/Sprite2D_Board
	$CoreGamplay.scale = Vector2.ONE * (1000.0 / 1804.0) * fit
	$CoreGamplay.position = origin + Vector2(960, 540) * fit
	$CoreGamplay.rotation = -float(GameManager.LocalPlayerColor) * PI * 0.5
	# Fit the square artwork to the board's existing coordinate space.
	var artwork: Sprite2D = board_sprite.get_node("Artwork")
	var texture_size_board := artwork.texture.get_size()
	artwork.scale = Vector2.ONE * (1804.0 / maxf(texture_size_board.x, texture_size_board.y))
	for base in base_artworks:
		var crop := base.texture as AtlasTexture
		base.position = (crop.region.get_center() - texture_size_board * 0.5) * artwork.scale
		base.scale = artwork.scale
		# Follow the base's position, but keep its illustration facing the player.
		base.global_rotation = 0.0
	for group in $CoreGamplay/Pieces.get_children():
		for piece: Piece in group.Pieces:
			piece.global_rotation = 0.0
			if is_instance_valid(piece.finish_marker):
				piece.finish_marker.global_rotation = 0.0
				piece.UpdateFinishMarkerPosition()
	var dice: Node2D = $CoreGamplay/Dice/DiceRoot
	dice.global_rotation = 0.0
	dice.global_position = origin + Vector2(230, 872) * fit
	dice.global_scale = Vector2.ONE * 0.72 * fit
	var status: Label = dice.get_node("StatusLabel")
	status.add_theme_font_size_override("font_size", 30)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.clip_text = true
	status.max_lines_visible = 2
	status.custom_minimum_size = Vector2.ZERO
	status.position = Vector2(-260, 125)
	status.size = Vector2(520, 100)
	var background: Sprite2D = $BackGround2DSprite
	var texture_size := background.texture.get_size()
	background.position = viewport_size * 0.5
	background.scale = Vector2.ONE * maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
