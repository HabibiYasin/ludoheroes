extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 30.0
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	board.BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	for color in range(4):
		var path := board.way_points.GetPath(color)
		var lane_start := 0
		while path[lane_start].get_parent() == board.way_points.main_path:
			lane_start += 1
		var hero: Piece = board.piecesManager.GetPieceGroupBasedOnType(color).Pieces[0]
		board.piecesManager.GetPieceGroupBasedOnType(color).Pieces[1].SetCurrentPositionAndCheckKill(0)
		while board.currentPlayerColor != color:
			board.UpdatePlayerTurn()
		for kind in ["Tank", "Runner"]:
			hero.HeroClass = kind
			for bonus in [0, 1, 3]:
				hero.MoveBonus = bonus
				hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
				hero.CurrentPosition = 0
				assert(hero.GetMoveDistance(1) == 1 + bonus + (1 if kind == "Runner" else 0))
				# Crossing the boundary with either bonus uses only the die.
				hero.CurrentPosition = lane_start - 1
				assert(hero.GetMoveDistance(1) == 1)
				for index in range(lane_start, path.size()):
					hero.CurrentPosition = index
					for die in range(1, 7):
						assert(hero.GetMoveDistance(die) == die)
						assert(hero.CanMoveWithDice(die, path.size()) == (index + die < path.size()))
			# Reproduce the actual stuck state with three stacked boots.
			hero.SendBackToLobby()
			hero.Items.clear()
			hero.MoveBonus = 0
			for stack in range(3):
				hero.EquipItem(2)
			hero.SetCurrentPositionAndCheckKill(path.size() - 2)
			board._on_dice_root_on_dice_rolled([1, 4])
			assert(board.move_preview.previews.has(hero))
			assert(board.move_preview.previews[hero].target == path.size() - 1)
			await board._on_player_select_piece(hero)
			assert(hero.IsInHome and hero.CurrentPosition == path.size() - 1)
			assert(not hero.visible and board.remainingDice == [0, 4])
			assert(not board.move_preview.previews.has(hero))
			assert(hero.MoveBonus == 3 and hero.Items[2] == 3)
			hero.SendBackToLobby()
		print("PASS: home lane ignores item/Runner bonuses and stacked boots finish with die 1 for color ", color)
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
