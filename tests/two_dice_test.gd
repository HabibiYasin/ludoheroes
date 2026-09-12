extends Node

func _ready() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var dice: Dice = game.get_node("CoreGamplay/Dice/DiceRoot")
	var group: PlayerPiecesGroup = board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor)
	var first: Piece = group.Pieces[0]
	var second: Piece = group.Pieces[1]
	var initial_player: int = board.currentPlayerTurnIndex

	# A round starts with the selected player, even across the red/green boundary.
	var hud = game.get_child(game.get_child_count() - 1)
	for start_color in range(4):
		board.currentPlayerTurnIndex = start_color - 1
		board.UpdatePlayerTurn()
		var initial_round := board.currentRound
		for completed_turns in range(4):
			assert(board.currentRound == initial_round)
			board._on_dice_root_on_dice_rolled([2, 3])
		assert(board.currentRound == initial_round + 1)
		assert(hud.round_label.text == "RONDE %d" % board.currentRound)
	board.currentPlayerTurnIndex = initial_player - 1
	board.UpdatePlayerTurn()
	var round_before_moves := board.currentRound

	# The unplayable 3 must remain available after the 6 unlocks a piece.
	board._on_dice_root_on_dice_rolled([3, 6])
	assert(board.selectedDiceIndex == 1)
	await board._on_player_select_piece(first)
	assert(first.CurrentPosition == 0)
	assert(board.currentRound == round_before_moves)
	assert(board.currentDiceValue == 3)
	assert(board.remainingDice == [3, 0])
	await board._on_player_select_piece(first)
	assert(first.CurrentPosition == 3)
	assert(board.currentRound == round_before_moves)
	assert(board.remainingDice.is_empty())
	assert(board.currentPlayerTurnIndex == (initial_player + 1) % 4)
	while board.currentPlayerTurnIndex != initial_player:
		board.UpdatePlayerTurn()

	# Choose the second die first, then move a different piece.
	board._on_dice_root_on_dice_rolled([2, 6])
	board.SelectDie(1)
	await board._on_player_select_piece(second)
	assert(second.CurrentPosition == 0)
	assert(board.remainingDice == [2, 0])
	board.SelectDie(1)
	assert(board.selectedDiceIndex == 0)
	await board._on_player_select_piece(first)
	assert(first.CurrentPosition == 5)
	assert(second.CurrentPosition == 0)
	assert(board.currentPlayerTurnIndex == (initial_player + 1) % 4)
	while board.currentPlayerTurnIndex != initial_player:
		board.UpdatePlayerTurn()

	# Double six must not award another roll either.
	board._on_dice_root_on_dice_rolled([6, 6])
	await board._on_player_select_piece(first)
	assert(board.currentPlayerTurnIndex == initial_player)
	await board._on_player_select_piece(second)
	assert(board.currentPlayerTurnIndex == (initial_player + 1) % 4)
	while board.currentPlayerTurnIndex != initial_player:
		board.UpdatePlayerTurn()

	# A normal pair only advances the turn after both moves.
	board._on_dice_root_on_dice_rolled([1, 2])
	await board._on_player_select_piece(first)
	assert(board.currentPlayerTurnIndex == initial_player)
	await board._on_player_select_piece(second)
	assert(board.currentPlayerTurnIndex != initial_player)

	# All pieces in the next player's lobby: neither die can be used.
	var next_player: int = board.currentPlayerTurnIndex
	board._on_dice_root_on_dice_rolled([2, 3])
	assert(board.currentPlayerTurnIndex != next_player)
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice)

	# Real rolls emit two independent values, each in the inclusive 1..6 range.
	var seen: Dictionary = {}
	for attempt in range(16):
		dice.RollDice()
		var values: Array[int] = await dice.OnDiceRolled
		assert(values.size() == 2)
		for value in values:
			assert(value >= 1 and value <= 6)
		seen[str(values)] = true
		board.FinishTurn()
	assert(seen.size() > 1)
	print("PASS: two dice, same/split pieces, selection, consumed dice, turn progression, no legal moves, random rolls")
	get_tree().quit()
