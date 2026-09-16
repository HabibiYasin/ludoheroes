extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var watchdog := Timer.new()
	add_child(watchdog)
	watchdog.timeout.connect(func(): get_tree().quit(1))
	watchdog.start(15)
	for local_color in range(4):
		GameManager.LocalPlayerColor = local_color
		GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
		var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
		var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
		board.BotsEnabled = false
		game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
		# Verify the game can start with Places and its animation player removed.
		for color in ["Green", "Yellow", "Blue", "Red"]:
			board.get_node("Sprite2D_Board/Sprite2D_" + color).free()
		board.get_node("AnimationPlayer").free()
		add_child(game)
		assert(game.base_artworks.size() == 4)
		for base: Sprite2D in game.base_artworks:
			assert(base.visible and is_zero_approx(base.global_rotation))
			var artwork: Sprite2D = board.get_node("Sprite2D_Board/Artwork")
			var expected_size := artwork.texture.get_size() * artwork.global_scale.abs() * 0.4
			assert((base.texture.get_size() * base.global_scale.abs()).distance_to(expected_size) < 1.0)
		game._update_layout()
		for base: Sprite2D in game.base_artworks:
			assert(is_zero_approx(base.global_rotation))
		var indicator = board.turn_indicator
		assert(indicator.visible and indicator.faction == local_color)
		assert(is_zero_approx(angle_difference(indicator.global_rotation, -local_color * PI * 0.5)))
		for turn in range(4):
			assert(indicator.visible and indicator.faction == board.currentPlayerColor)
			indicator._process(0.3)
			assert(indicator.modulate.a < 0.9)
			get_tree().paused = true
			var phase: float = indicator.phase
			await get_tree().process_frame
			assert(indicator.phase == phase)
			get_tree().paused = false
			board._on_dice_root_on_dice_roll_begin()
			assert(not indicator.visible)
			GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerSelectPiece)
			assert(not indicator.visible)
			board.FinishTurn()
			assert(indicator.visible)
		GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.GameOver)
		assert(not indicator.visible)
		game.queue_free()
		await get_tree().process_frame
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Green
	print("PASS: turn indicator without Places, four rotations/factions, pulse, pause, roll, turn change and game over")
	get_tree().quit()
