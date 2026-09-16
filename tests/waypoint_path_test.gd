extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var paths := board.way_points
	assert(paths.green_path[0] == paths.main_path.get_node("0"))
	assert(paths.green_path[0].isThisSafePlace)
	assert(paths.green_path[1] == paths.main_path.get_node("1"))
	for color in range(4):
		var hero: Piece = board.piecesManager.GetPieceGroupBasedOnType(color).Pieces[0]
		var path: Array[WayPoint] = paths.GetPath(color)
		assert(path.size() == 57)
		var home_count := 6
		var last_shared := path.size() - home_count - 1
		assert(path[last_shared].get_parent() == paths.main_path)
		assert(path[last_shared + 1].get_parent() != paths.main_path)
		assert(paths.GetWayPoint(-1, color) == null)
		assert(paths.GetWayPoint(path.size(), color) == null)
		# Visit every configured cell, including the transition into the home lane.
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
		hero.SetCurrentPositionAndCheckKill(last_shared)
		board._on_dice_root_on_dice_rolled([1, home_count - 1])
		await board._on_player_select_piece(hero)
		assert(hero.CurrentPosition == last_shared + 1 and hero.CurrentWayPoint == path[last_shared + 1])
		assert(board.remainingDice == [0, home_count - 1])
		await board._on_player_select_piece(hero)
		assert(hero.CurrentPosition == path.size() - 1 and hero.IsInHome)
		assert(hero.CurrentState == GameManager.PieceStateEnum.InHouse)
		hero.SendBackToLobby()
		print("PASS: all configured waypoints and home entry/finish for color ", color)
	get_tree().quit()