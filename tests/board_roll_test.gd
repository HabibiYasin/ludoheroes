extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	for color in range(4):
		GameManager.LocalPlayerColor = color
		var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
		add_child(game)
		var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
		var dice: Dice = game.get_node("CoreGamplay/Dice/DiceRoot")
		var idle = game.get_node("CoreGamplay/PlayerIdleController")
		idle.Enabled = false
		dice.IsTestRun = true
		var artwork: Sprite2D = board.get_node("Sprite2D_Board/Artwork")
		var center := artwork.global_position
		GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
		assert(not dice.TryRollFromBoard(artwork.to_global(Vector2(2000, 2000))))
		board.HumanPlayerColor = (color + 1) % 4
		assert(not dice.TryRollFromBoard(center))
		board.HumanPlayerColor = color
		get_tree().paused = true
		assert(not dice.TryRollFromBoard(center))
		get_tree().paused = false
		var points: Array[Vector2] = [center]
		for name in ["Green", "Yellow", "Blue", "Red"]:
			points.append(board.get_node("Sprite2D_Board/Sprite2D_" + name).global_position)
		for point in points:
			GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
			idle.AutoPlaying = true
			idle.ConsecutiveIdleTurns = 5
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.position = get_viewport().get_canvas_transform() * point
			dice._unhandled_input(click)
			assert(dice._is_rolling)
			assert(not idle.AutoPlaying and idle.ConsecutiveIdleTurns == 0)
			assert(not dice.TryRollFromBoard(point))
			await dice.OnDiceRolled
			assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerSelectPiece)
			assert(not dice.TryRollFromBoard(point))
		print("PASS: board and four bases roll once, human/state/pause/bounds guards and idle reset, rotation ", color)
		game.queue_free()
		await get_tree().process_frame
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Green
	get_tree().quit()