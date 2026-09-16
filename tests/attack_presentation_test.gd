extends Node

func _ready() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var presentation = board.attack_presentation
	# All three lanes of each arm retain their territory under every board rotation.
	var core: Node2D = game.get_node("CoreGamplay")
	var original_rotation := core.rotation
	for rotation_index in range(4):
		core.rotation = -rotation_index * PI * 0.5
		for waypoint: WayPoint in board.way_points.main_path.get_children():
			var index := int(waypoint.name)
			var expected := "Thornvale"
			if index >= 5 and index <= 17:
				expected = "Nekravia"
			elif index >= 18 and index <= 30:
				expected = "Nerathis"
			elif index >= 31 and index <= 43:
				expected = "Astherion"
			assert(board.way_points.GetTerritoryFaction(waypoint) == expected)
	core.rotation = original_rotation
	print("PASS: every shared cell territory across all board rotations")
	var cell := WayPoint.new()
	add_child(cell)
	var attacker: Piece = board.piecesManager.GreenPieces.Pieces[0]
	var defender: Piece = board.piecesManager.RedPieces.Pieces[0]
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
	# A fixed pair of heroes must show each target territory's artwork.
	for entry in [["1", "Thornvale"], ["6", "Nekravia"], ["19", "Nerathis"], ["32", "Astherion"]]:
		var target_cell: WayPoint = board.way_points.main_path.get_node(entry[0])
		presentation.queue_attack(attacker, defender, 1, target_cell)
		var attack: Dictionary = presentation.pending.pop_front()
		assert(attack.territory == entry[1])
		presentation._play(attack)
		var background: TextureRect = presentation.stage.get_node("BattleBackground")
		assert(background.texture.resource_path.ends_with(entry[1] + "Battle.png"))
		while presentation.stage != null:
			await get_tree().process_frame
	print("PASS: background follows territory with unchanged hero factions")
	for faction in ["Astherion", "Nekravia", "Nerathis", "Thornvale"]:
		cell.ClearMe()
		attacker.Faction = faction
		attacker.Attack = 1
		defender.Health = 4
		cell.SetPiece(defender)
		cell.SetPiece(attacker)
		assert(defender.Health == 3)
		assert(presentation.pending.size() == 1)
		assert(presentation.pending[0].damage == 1)
		await board._wait_for_kill_if_needed()
		assert(presentation.stage == null)
		assert(presentation.pending.is_empty())
		print("PASS: nonlethal attack animation ", faction)
	cell.ClearMe()
	defender.Health = 1
	attacker.Attack = 3
	cell.SetPiece(defender)
	cell.SetPiece(attacker)
	assert(board.hasKill)
	assert(presentation.pending[0].damage == 1)
	await board._wait_for_kill_if_needed()
	assert(defender.IsInLobby())
	assert(presentation.stage == null)
	print("PASS: lethal attack completes without blocking")
	cell.ClearMe()
	cell.isThisSafePlace = true
	defender.Health = 4
	cell.SetPiece(defender)
	cell.SetPiece(attacker)
	assert(defender.Health == 4)
	assert(presentation.pending.is_empty())
	print("PASS: safe cell does not attack")
	get_tree().quit()
