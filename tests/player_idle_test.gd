extends Node

func _ready() -> void:
	get_tree().create_timer(15).timeout.connect(func(): get_tree().quit(1))
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/BotController").set_process(false)
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var dice: Dice = game.get_node("CoreGamplay/Dice/DiceRoot")
	var idle = game.get_node("CoreGamplay/PlayerIdleController")
	assert(idle.IdleSeconds == 10.0)
	idle.IdleSeconds = 0.05
	idle.AutoActionDelay = 0.02
	dice.IsTestRun = true
	get_tree().paused = true
	await get_tree().create_timer(0.15).timeout
	assert(not dice._is_rolling and idle.ConsecutiveIdleTurns == 0)
	get_tree().paused = false
	while board.IsHumanTurn():
		await get_tree().process_frame
	assert(idle.ConsecutiveIdleTurns == 1)
	assert(idle.AutoPlaying)
	# Subsequent turns must not wait for the idle timeout again.
	idle.IdleSeconds = 100.0
	assert(board.piecesManager.GreenPieces.HasUnlockedAnyPiece())
	assert(idle.WarningText().is_empty())
	# Two automated dice moves counted once; bot turns cannot count as idle.
	board.FinishTurn()
	assert(idle.ConsecutiveIdleTurns == 1)
	for count in range(2, 14):
		while not board.IsHumanTurn():
			board.UpdatePlayerTurn()
		for piece in board.piecesManager.GreenPieces.Pieces:
			piece.SendBackToLobby()
		board._on_dice_root_on_dice_rolled([3, 3])
		while board.IsHumanTurn():
			await get_tree().process_frame
		assert(idle.ConsecutiveIdleTurns == count)
		assert(idle.WarningText().is_empty() == (count < 4))
	assert(idle.WarningText().contains("12"))
	assert(GameManager.GameCurrentState != GameManager.GameStateEnum.GameOver)
	while not board.IsHumanTurn():
		board.UpdatePlayerTurn()
	board.ManualAction.emit()
	assert(idle.ConsecutiveIdleTurns == 0 and idle.WarningText().is_empty())
	assert(not idle.AutoPlaying)
	assert(is_equal_approx(idle.SecondsRemaining, idle.IdleSeconds))
	# Manual input cancels an almost-expired auto action.
	idle._elapsed = idle.IdleSeconds * 0.9
	board.ManualAction.emit()
	idle._process(idle.IdleSeconds * 0.5)
	assert(not dice._is_rolling and not idle._used_auto)
	assert(idle.SecondsRemaining > 0.0)
	# Inspecting any hero also stops auto-play, even during a bot turn.
	idle.AutoPlaying = true
	board.UpdatePlayerTurn()
	GameManager.HeroInspected.emit(board.piecesManager.GreenPieces.Pieces[0])
	assert(not idle.AutoPlaying)
	idle.Enabled = false
	await get_tree().create_timer(0.15).timeout
	assert(not idle.WaitingForPlayer)
	print("PASS: idle auto-roll/move, pause, one count per turn, 4/12/13 thresholds, manual reset, disable")
	get_tree().quit()