extends Node

func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	viewport.add_child(game)
	for resolution in [Vector2i(1920, 1080), Vector2i(2400, 1080), Vector2i(2520, 1080), Vector2i(1920, 1440)]:
		viewport.size = resolution
		await get_tree().process_frame
		var sprite: Sprite2D = game.get_node("CoreGamplay/Board/board_GamePlay/Sprite2D_Board")
		var board_size := sprite.texture.get_size() * sprite.global_scale
		var top_left := sprite.global_position - board_size * 0.5
		var bottom_right := sprite.global_position + board_size * 0.5
		assert(is_equal_approx(board_size.x, board_size.y))
		assert(board_size.y >= 950.0)
		assert(top_left.x >= 40.0 and top_left.y >= 39.0)
		assert(bottom_right.y <= resolution.y - 39.0)
		var dice: Node2D = game.get_node("CoreGamplay/Dice/DiceRoot")
		assert(dice.global_position.x + 190.0 < top_left.x)
		assert(dice.global_position.x - 190.0 >= 39.0)
		assert(dice.global_scale.is_equal_approx(Vector2.ONE * 0.72))
		var background: Sprite2D = game.get_node("BackGround2DSprite")
		var background_size := background.texture.get_size() * background.scale
		assert(background_size.x >= resolution.x - 1 and background_size.y >= resolution.y - 1)
		print("PASS: board, dice and background fit ", resolution)
	var hud = game.get_child(game.get_child_count() - 1)
	var piece: Piece = game.get_node("CoreGamplay/Pieces/Green/Piece_green3")
	GameManager.HeroInspected.emit(piece)
	assert(hud.hero_name.text == "Pirunrun")
	assert(hud.hero_icon.texture == piece.PieceTexture)
	hud._react("GG!")
	assert(hud.emote.visible and hud.emote.text == "GG!")
	assert(not hud.reactions.visible)
	hud._open_menu()
	assert(get_tree().paused and hud.modal.visible and hud.menu_panel.visible)
	hud._close_menu()
	assert(not get_tree().paused and not hud.modal.visible)
	print("PASS: hero inspection, local reaction, menu pause/resume")
	get_tree().quit()
