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
	var paths := board.way_points
	var star_names := ["8", "21", "34", "46"]
	for color in range(4):
		var path := paths.GetPath(color)
		var found: Array[String] = []
		for cell in path:
			if paths.IsItemTile(cell):
				found.append(str(cell.name))
		found.sort()
		var expected := star_names.duplicate()
		expected.sort()
		assert(found == expected, "All colors must see exactly the four artwork stars")
		var hero: Piece = board.piecesManager.GetPieceGroupBasedOnType(color).Pieces[0]
		hero.HeroClass = "Mage"
		while board.currentPlayerColor != color:
			board.UpdatePlayerTurn()
		for star_name in star_names:
			hero.Items.clear()
			hero.MoveBonus = 0
			var star: WayPoint = paths.main_path.get_node(star_name)
			var destination := path.find(star)
			hero.SendBackToLobby()
			hero.SetCurrentPositionAndCheckKill(destination - 1)
			board._on_dice_root_on_dice_rolled([1, 4])
			board._on_player_select_piece(hero)
			while board.item_choice.stage == null:
				await get_tree().process_frame
			assert(hero.CurrentPosition == destination and hero.position == star.position)
			assert(board.remainingDice == [1, 4])
			board.item_choice._select(board.item_choice.offered[0], true)
			assert(hero.Items.size() == 1 and board.remainingDice == [0, 4])
		hero.SendBackToLobby()
	assert(not paths.main_path.get_node("0").isThisSafePlace)
	assert(not paths.main_path.get_node("47").isThisSafePlace)
	# Green must complete the bottom edge before entering its home lane.
	var expected_tail := ["48", "49", "50", "51", "0", "52"]
	var green: Piece = board.piecesManager.GreenPieces.Pieces[0]
	green.Items.clear()
	green.MoveBonus = 0
	while board.currentPlayerColor != GameManager.PlayerColor.Green:
		board.UpdatePlayerTurn()
	var start := paths.green_path.find(paths.main_path.get_node("48"))
	green.SetCurrentPositionAndCheckKill(start)
	for step in range(1, expected_tail.size()):
		board._on_dice_root_on_dice_rolled([1, 4])
		await board._on_player_select_piece(green)
		assert(green.CurrentPosition == start + step)
		assert(str(green.CurrentWayPoint.name) == expected_tail[step])
		assert(board.item_choice.stage == null)
		assert(board.remainingDice == [0, 4])
	green.SendBackToLobby()
	# Runner's explicit bonus still lands on the corrected star.
	var runner: Piece = board.piecesManager.BluePieces.Pieces[3]
	runner.Items.clear()
	runner.MoveBonus = 0
	while board.currentPlayerColor != GameManager.PlayerColor.Blue:
		board.UpdatePlayerTurn()
	var star_index := paths.blue_path.find(paths.main_path.get_node("46"))
	runner.SetCurrentPositionAndCheckKill(star_index - 2)
	assert(runner.GetMoveDistance(1) == 2)
	board._on_dice_root_on_dice_rolled([1, 4])
	board._on_player_select_piece(runner)
	while board.item_choice.stage == null:
		await get_tree().process_frame
	assert(runner.CurrentPosition == star_index)
	board.item_choice._select(board.item_choice.offered[0])
	game.queue_free()
	await get_tree().process_frame
	print("PASS: real landings on all four artwork stars for every color, green outer loop without skipped cells, Runner landing and die consumption")
	get_tree().quit()
