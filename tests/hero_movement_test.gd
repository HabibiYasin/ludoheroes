extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 30.0
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	for color in range(4):
		var path := board.way_points.GetPath(color)
		# Artwork cells are about 100-122 units wide/high. A skipped cell exceeds 130.
		for index in range(1, path.size()):
			var delta := (path[index].position - path[index - 1].position).abs()
			assert(delta.x <= 130.0 and delta.y <= 130.0,
				"Skipped board cell: %s -> %s" % [path[index - 1].name, path[index].name])
		for hero: Piece in board.piecesManager.GetPieceGroupBasedOnType(color).Pieces:
			while board.currentPlayerColor != color:
				board.UpdatePlayerTurn()
			board._on_dice_root_on_dice_rolled([6, 0])
			await board._on_player_select_piece(hero)
			assert(hero.CurrentPosition == 0 and hero.position == path[0].position)
			var next_die := 1
			while not hero.IsInHome:
				while board.currentPlayerColor != color:
					board.UpdatePlayerTurn()
				var start := hero.CurrentPosition
				var value := mini(next_die, path.size() - 1 - start)
				board._on_dice_root_on_dice_rolled([value, 0])
				await board._on_player_select_piece(hero)
				assert(hero.CurrentPosition == start + value, hero.HeroId)
				if hero.IsInHome:
					assert(hero.CurrentWayPoint == null and not hero.visible, hero.HeroId)
					assert(not path[start + value].myHoldings.has(hero), hero.HeroId)
					assert(is_instance_valid(hero.finish_marker), hero.HeroId)
					assert(hero.finish_marker.position == hero.LobbyPosition, hero.HeroId)
					assert(not hero.CanMoveWithDice(6, path.size()), hero.HeroId)
				else:
					assert(hero.CurrentWayPoint == path[start + value], hero.HeroId)
				assert(hero.position == path[start + value].position, hero.HeroId)
				next_die = next_die % 6 + 1
			print("PASS: ", hero.HeroId, " summon and dice 1-6 across entire board to home")
			hero.SendBackToLobby()
			assert(hero.visible and hero.finish_marker == null, hero.HeroId)
	get_tree().quit()
