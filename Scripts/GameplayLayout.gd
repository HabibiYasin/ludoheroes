extends Node2D

# Base rectangles measured in the 1254 x 1254 Heroes board artwork.
# Its base areas are not square or symmetric like the original Ludo board.
const PLACE_BOUNDS := {
	"Yellow": Rect2(0, 0, 520, 487),
	"Blue": Rect2(740, 0, 514, 487),
	"Green": Rect2(0, 712, 520, 542),
	"Red": Rect2(740, 712, 514, 542),
}
func _ready() -> void:
	var hud := CanvasLayer.new()
	hud.set_script(load("res://Scripts/GameplayHUD.gd"))
	add_child(hud)
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()

func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	var origin := (viewport_size - Vector2(1920, 1080) * fit) * 0.5
	var board_sprite: Sprite2D = $CoreGamplay/Board/board_GamePlay/Sprite2D_Board
	$CoreGamplay.scale = Vector2.ONE * (1000.0 / 1804.0) * fit
	$CoreGamplay.position = origin + Vector2(960, 540) * fit
	$CoreGamplay.rotation = -float(GameManager.LocalPlayerColor) * PI * 0.5
	# Keep faction emblems at the top regardless of the player's board rotation.
	for color_name in ["Green", "Yellow", "Blue", "Red"]:
		var place: Sprite2D = board_sprite.get_node("Sprite2D_" + color_name)
		var bounds: Rect2 = PLACE_BOUNDS[color_name]
		var artwork: Sprite2D = board_sprite.get_node("Artwork")
		place.position = (bounds.get_center() - artwork.texture.get_size() * 0.5) * artwork.scale
		var display_size := bounds.size * artwork.scale
		# Upright art needs swapped dimensions when the board turns a quarter turn.
		if int(GameManager.LocalPlayerColor) % 2 == 1:
			display_size = Vector2(display_size.y, display_size.x)
		place.scale = display_size / place.texture.get_size()
		place.global_rotation = 0.0
	for group in $CoreGamplay/Pieces.get_children():
		for piece: Piece in group.Pieces:
			piece.global_rotation = 0.0
	var dice: Node2D = $CoreGamplay/Dice/DiceRoot
	dice.global_rotation = 0.0
	dice.global_position = origin + Vector2(230, 872) * fit
	dice.global_scale = Vector2.ONE * 0.72 * fit
	var status: Label = dice.get_node("StatusLabel")
	status.add_theme_font_size_override("font_size", 38)
	status.position = Vector2(-260, 125)
	status.size = Vector2(520, 150)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var background: Sprite2D = $BackGround2DSprite
	var texture_size := background.texture.get_size()
	background.position = viewport_size * 0.5
	background.scale = Vector2.ONE * maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
