extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	for color in range(4):
		var menu = load("res://Levels/MainMenu.tscn").instantiate()
		get_tree().root.add_child(menu)
		get_tree().current_scene = menu
		menu._start.pressed.emit()
		assert(menu._color_selection.visible and not menu._home.visible)
		menu._cancel_color_selection()
		assert(menu._home.visible and not menu._color_selection.visible)
		menu._show_color_selection()
		menu._color_selection.get_child(1).get_child(color).pressed.emit()
		await get_tree().scene_changed
		var game := get_tree().current_scene
		var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
		for color_name in ["Green", "Yellow", "Blue", "Red"]:
			var place: Sprite2D = board.get_node("Sprite2D_Board/Sprite2D_" + color_name)
			assert(is_zero_approx(place.global_rotation))
		assert(int(board.HumanPlayerColor) == color)
		assert(board.IsHumanTurn() and int(board.currentPlayerColor) == color)
		var group := board.piecesManager.GetPieceGroupBasedOnType(board.HumanPlayerColor)
		var center: Vector2 = game.get_node("CoreGamplay").global_position
		for piece in group.Pieces:
			assert(piece.global_position.x < center.x and piece.global_position.y > center.y)
			assert(is_zero_approx(piece.global_rotation))
		var dice: Dice = game.get_node("CoreGamplay/Dice/DiceRoot")
		assert(is_zero_approx(dice.global_rotation))
		var hud = game.get_child(game.get_child_count() - 1)
		var card: Panel = hud.root.get_node("PlayerCard%d" % color)
		assert(card.position == Vector2(1510, 722))
		assert(card.get_child(0).texture.resource_path.ends_with("player 4.jpg"))
		# Entry and subsequent movement still use the chosen color's path.
		board._on_dice_root_on_dice_rolled([6, 1])
		await board._on_player_select_piece(group.Pieces[0])
		assert(group.Pieces[0].CurrentPosition == 0)
		await board._on_player_select_piece(group.Pieces[0])
		assert(group.Pieces[0].CurrentPosition == 1)
		assert(not board.IsHumanTurn())
		print("PASS: color ", color, " selection, lower-left base, upright art, own profile, path and bot ownership")
		game.queue_free()
		await get_tree().process_frame
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Green
	get_tree().quit()
