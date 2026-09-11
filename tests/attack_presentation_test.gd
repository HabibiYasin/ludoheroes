extends Node

func _ready() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var presentation = board.attack_presentation
	var cell := WayPoint.new()
	add_child(cell)
	var attacker: Piece = board.piecesManager.GreenPieces.Pieces[0]
	var defender: Piece = board.piecesManager.RedPieces.Pieces[0]
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
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
