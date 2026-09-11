extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var paths := board.way_points
	for color in range(4):
		var hero: Piece = board.piecesManager.GetPieceGroupBasedOnType(color).Pieces[0]
		var path: Array[WayPoint] = paths.GetPath(color)
		assert(path.size() == 57)
		assert(path[50].get_parent() == paths.main_path)
		assert(path[51].get_parent() != paths.main_path)
		assert(paths.GetWayPoint(-1, color) == null)
		assert(paths.GetWayPoint(path.size(), color) == null)
		# Visit every configured cell, including the previously failing index 51.
		for index in range(path.size()):
			if hero.CurrentWayPoint != null:
				hero.CurrentWayPoint.RemoveMyRef(hero)
			hero.SetCurrentPositionAndCheckKill(index)
			assert(hero.CurrentWayPoint == path[index])
			assert(path[index].myHoldings.has(hero))
			assert(paths.GetPositionOfThisPoint(index, color) == path[index].position)
		assert(hero.IsInHome)
		hero.SendBackToLobby()
		# Exercise actual movement into home and ensure the remaining die is usable.
		while int(board.currentPlayerColor) != color:
			board.UpdatePlayerTurn()
		hero.SetCurrentPositionAndCheckKill(50)
		board._on_dice_root_on_dice_rolled([1, 5])
		await board._on_player_select_piece(hero)
		assert(hero.CurrentPosition == 51 and hero.CurrentWayPoint == path[51])
		assert(board.remainingDice == [0, 5])
		await board._on_player_select_piece(hero)
		assert(hero.CurrentPosition == 56 and hero.IsInHome)
		assert(hero.CurrentState == GameManager.PieceStateEnum.InHouse)
		hero.SendBackToLobby()
		print("PASS: all 57 waypoints and home entry/finish for color ", color)
	get_tree().quit()