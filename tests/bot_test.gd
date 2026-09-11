extends Node

var rolls := 0

func _ready() -> void:
	get_tree().create_timer(25.0).timeout.connect(func():
		push_error("Bot test timed out: turn stalled")
		get_tree().quit(1))
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var dice: Dice = game.get_node("CoreGamplay/Dice/DiceRoot")
	var bot = game.get_node("CoreGamplay/BotController")
	bot.ThinkDelay = 0.02
	dice.IsTestRun = true
	dice.OnDiceRollBegin.connect(func(): rolls += 1)
	await get_tree().create_timer(0.15).timeout
	assert(board.IsHumanTurn() and rolls == 0)
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice)

	# Green passes; yellow must use the 6 before the previously unusable 3.
	board._on_dice_root_on_dice_rolled([1, 2])
	assert(board.currentPlayerColor == GameManager.PlayerColor.Yellow)
	assert(not board.IsHumanTurn())
	board._on_dice_root_on_dice_rolled([3, 6])
	var chosen: Dictionary = bot.ChooseMove()
	assert(chosen.die_index == 1 and chosen.piece.IsInLobby())
	get_tree().paused = true
	await get_tree().create_timer(0.15).timeout
	assert(board.remainingDice == [3, 6] and rolls == 0)
	get_tree().paused = false

	# Yellow moves, then blue and red each roll and consume both dice.
	while not board.IsHumanTurn():
		await get_tree().process_frame
	assert(rolls == 2)
	var yellow := board.piecesManager.YellowPieces
	var yellow_progress := 0
	for piece in yellow.Pieces:
		if piece.CurrentPosition == 3:
			yellow_progress += 1
	assert(yellow_progress == 1)
	for group: PlayerPiecesGroup in [board.piecesManager.BluePieces, board.piecesManager.RedPieces]:
		var unlocked := 0
		for piece in group.Pieces:
			if not piece.IsInLobby():
				unlocked += 1
		assert(unlocked == 2)
	assert(board.remainingDice.is_empty())
	await get_tree().create_timer(0.15).timeout
	assert(board.IsHumanTurn() and rolls == 2)
	print("PASS: green stays manual; three bots use both dice and return the turn; pause stops thinking")

	# No legal move skips a bot without waiting for user input.
	for piece in yellow.Pieces:
		piece.SendBackToLobby()
	board.FinishTurn()
	board._on_dice_root_on_dice_rolled([2, 3])
	assert(board.currentPlayerColor == GameManager.PlayerColor.Blue)
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice)

	# Set up an exact finish: prefer the legal 1 over an overshooting 6.
	while board.currentPlayerColor != GameManager.PlayerColor.Yellow:
		board.UpdatePlayerTurn()
	for index in range(3):
		yellow.Pieces[index].IsInHome = true
	var last := yellow.Pieces[3]
	last.CurrentPosition = board.GetPathCount(GameManager.PlayerColor.Yellow) - 2
	last.CurrentState = GameManager.PieceStateEnum.InWayPoint
	board._on_dice_root_on_dice_rolled([6, 1])
	chosen = bot.ChooseMove()
	assert(chosen.die_index == 1 and chosen.piece == last)
	while GameManager.GameCurrentState != GameManager.GameStateEnum.GameOver:
		await get_tree().process_frame
	assert(last.IsInHome)
	var final_rolls := rolls
	await get_tree().create_timer(0.15).timeout
	assert(rolls == final_rolls)
	print("PASS: bot skips impossible rolls, finishes with an exact roll, and stops at game over")
	get_tree().quit()
