extends Node

func _ready() -> void:
	get_tree().create_timer(20).timeout.connect(func(): get_tree().quit(1))
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	for pair in [[3, 3], [4, 2], [2, 4], [5, 1], [1, 5]]:
		var group := board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor)
		for piece in group.Pieces:
			piece.SendBackToLobby()
		var turn := board.currentPlayerTurnIndex
		var values: Array[int] = []
		values.assign(pair)
		board._on_dice_root_on_dice_rolled(values)
		assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerSelectPiece)
		assert(board.CanSummonWithPair())
		assert(group.GetMovablePieces(values[0], board.GetPathCount(board.currentPlayerColor)).size() == 4)
		board.SelectDie(1)
		await board._on_player_select_piece(group.Pieces[0])
		assert(group.Pieces[0].CurrentPosition == 0)
		assert(group.Pieces[1].IsInLobby())
		assert(board.remainingDice.is_empty() and board.currentPlayerTurnIndex != turn)
		print("PASS: ", pair, " summons one hero and consumes both dice")

	var group := board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor)
	for piece in group.Pieces:
		piece.SendBackToLobby()
	board._on_dice_root_on_dice_rolled([6, 2])
	await board._on_player_select_piece(group.Pieces[0])
	assert(board.remainingDice == [0, 2])
	await board._on_player_select_piece(group.Pieces[0])
	while board.currentPlayerColor != group.CurrentPlayerColor:
		board.UpdatePlayerTurn()
	board._on_dice_root_on_dice_rolled([4, 2])
	var start := group.Pieces[0].CurrentPosition
	await board._on_player_select_piece(group.Pieces[0])
	assert(board.remainingDice == [0, 2] and not board.CanSummonWithPair())
	assert(not group.GetMovablePieces(2, board.GetPathCount(group.CurrentPlayerColor)).has(group.Pieces[1]))
	await board._on_player_select_piece(group.Pieces[0])
	assert(group.Pieces[0].CurrentPosition == start + 6)
	print("PASS: single 6 preserves the other die; total-6 pair can instead move individually")

	group = board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor)
	for piece in group.Pieces:
		piece.SendBackToLobby()
	var turn := board.currentPlayerTurnIndex
	board._on_dice_root_on_dice_rolled([2, 2])
	assert(board.currentPlayerTurnIndex != turn)
	group = board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor)
	for piece in group.Pieces:
		piece.SendBackToLobby()
	board._on_dice_root_on_dice_rolled([3, 3])
	var bot = game.get_node("CoreGamplay/BotController")
	assert(not bot.ChooseMove().is_empty())
	bot._play_move()
	assert(board.remainingDice.is_empty())
	assert(group.HasUnlockedAnyPiece())
	print("PASS: invalid totals cannot summon; bot can use paired summon")
	get_tree().quit()
