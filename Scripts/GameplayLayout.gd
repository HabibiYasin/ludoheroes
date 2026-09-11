extends Node2D

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
	$CoreGamplay.scale = Vector2.ONE * (1000.0 / board_sprite.texture.get_width()) * fit
	$CoreGamplay.position = origin + Vector2(960, 540) * fit
	$CoreGamplay.rotation = -float(GameManager.LocalPlayerColor) * PI * 0.5
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
