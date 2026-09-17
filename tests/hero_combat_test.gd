extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var catalog = preload("res://Scripts/HeroCatalog.gd")
	var seen := {}
	for group in [board.piecesManager.GreenPieces, board.piecesManager.YellowPieces, board.piecesManager.BluePieces, board.piecesManager.RedPieces]:
		for hero: Piece in group.Pieces:
			assert(catalog.HEROES.has(hero.HeroId))
			assert(hero.Health == hero.MaxHealth and hero.Health > 0)
			assert(hero.PhysicalDefense == 0 and hero.MagicalDefense == 0)
			assert(hero.HeroClass == catalog.HEROES[hero.HeroId][0])
			seen[hero.HeroId] = true
	assert(seen.size() == 16)
	var attacker: Piece = board.piecesManager.GreenPieces.Pieces[1] # Garruk: 1 ATK
	var target: Piece = board.piecesManager.RedPieces.Pieces[2] # Mordian: 4 HP
	var cell: WayPoint = board.way_points.green_path[1]
	assert(not cell.isThisSafePlace)
	target.CurrentWayPoint = cell
	target.CurrentState = GameManager.PieceStateEnum.InWayPoint
	target.CurrentPosition = 40
	cell.SetPiece(target)
	GameManager.HeroInspected.emit(target)
	var hud = game.get_child(game.get_child_count() - 1)
	assert(hud.hero_health.text == "HP  4 / 4" and hud.hero_attack.text == "ATK  1")
	attacker.SetCurrentPositionAndCheckKill(0)
	board._on_dice_root_on_dice_rolled([1, 2])
	await board._on_player_select_piece(attacker)
	assert(target.Health == 3 and not target.IsInLobby())
	assert(attacker.MatchScore == 0 and attacker.MatchKills == 0)
	assert(cell.myHoldings.size() == 2 and not board.hasKill)
	assert(board.remainingDice == [0, 2])
	assert(hud.hero_health.text == "HP  3 / 4" and hud.hero_attack.text == "ATK  1")
	cell.SetPiece(attacker) # Re-registering does not attack again.
	assert(target.Health == 3)
	# Lethal landing uses the real asynchronous death/turn pipeline.
	target.TakeDamage(2)
	cell.RemoveMyRef(attacker)
	attacker.SetCurrentPositionAndCheckKill(0)
	board._on_dice_root_on_dice_rolled([1, 2])
	await board._on_player_select_piece(attacker)
	assert(target.Health == target.MaxHealth and target.IsInLobby())
	assert(attacker.MatchScore == 10 and attacker.MatchKills == 1)
	assert(GameManager.GameCurrentState != GameManager.GameStateEnum.GameOver)
	assert(not hud.match_results.presented and not hud.match_results.sound.playing)
	assert(GameAudio.music.playing)
	assert(target.position == target.LobbyPosition and target.CurrentWayPoint == null)
	assert(not cell.myHoldings.has(target) and board.remainingDice == [0, 2])
	assert(hud.hero_health.text == "HP  4 / 4" and hud.hero_attack.text == "ATK  1")
	target.SetCurrentPositionAndCheckKill(0)
	assert(target.Health == 4 and not target.IsInLobby())
	assert(hud.hero_health.text == "HP  4 / 4" and hud.hero_attack.text == "ATK  1")
	# Isolated safe cell, friendly landing, and zero attack all preserve HP.
	var safe := WayPoint.new()
	safe.isThisSafePlace = true
	add_child(safe)
	safe.SetPiece(target)
	safe.SetPiece(attacker)
	assert(target.Health == 4)
	safe.ClearMe()
	safe.isThisSafePlace = false
	safe.SetPiece(target)
	var support: Piece = board.piecesManager.RedPieces.Pieces[3]
	safe.SetPiece(support) # Same faction.
	assert(target.Health == 4)
	safe.RemoveMyRef(support)
	support.CurrentPlayerColor = GameManager.PlayerColor.Blue
	safe.SetPiece(support) # Anata has zero attack.
	assert(target.Health == 4 and safe.myHoldings.size() == 2)
	assert(not target.TakeDamage(-2) and target.Health == 4)
	assert(target.TakeDamage(99) and target.Health == 0)
	print("PASS: 16 hero classes/stats, damage, surviving shared cell, lethal landing, dice continuation, base return, respawn, live HUD, safe/friendly cells, zero attack and HP clamp")
	assert(hud.hero_physical_defense.text == "P. Def  0" and hud.hero_magical_defense.text == "M.Def  0")
	target.Health = 4
	target.PhysicalDefense = 2
	target.MagicalDefense = 1
	assert(hud.hero_physical_defense.text == "P. Def  2" and hud.hero_magical_defense.text == "M.Def  1")
	assert(not target.TakeDamage(2) and target.Health == 4)
	assert(not target.TakeDamage(3) and target.Health == 3)
	assert(not target.TakeDamage(2, true, Piece.DamageType.MAGICAL) and target.Health == 2)
	assert(target.GetIncomingDamage(3, false) == 0) # Tank passive stacks.
	assert(target.GetIncomingDamage(0, true, Piece.DamageType.MAGICAL) == 0)
	target.PhysicalDefense = -1
	assert(target.PhysicalDefense == 0)
	print("PASS: physical/magical defenses, blocked damage, Tank stacking, live defense HUD")
	# Base revival uses item-boosted max HP and refreshes both HUD presentations.
	target.EquipItem(1)
	target.EquipItem(1)
	assert(target.TakeDamage(99) and target.Health == 0)
	target.SendBackToLobby()
	assert(target.Health == 6 and target.MaxHealth == 6 and target.Items[1] == 2)
	assert(hud.hero_health.text == "HP  6 / 6")
	board.currentPlayerColor = target.CurrentPlayerColor
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
	hud._refresh_recommendations()
	var portrait_index: int = hud.recommendations.find(target)
	assert(portrait_index >= 0)
	assert(hud.hero_portraits[portrait_index].shade.color == Color.TRANSPARENT)
	print("PASS: death restores item-boosted max HP at base, equipment retained, health label and portrait updated")
	_test_highest_health_target()
	get_tree().quit()
func _test_highest_health_target() -> void:
	var cell := WayPoint.new()
	var heroes: Array[Piece] = []
	for hp in [2, 5, 5, 9, 0]:
		var hero := Piece.new()
		hero.Health = hp
		hero.MaxHealth = 10
		hero.CurrentPlayerColor = GameManager.PlayerColor.Red
		heroes.append(hero)
		cell.myHoldings.append(hero)
	heroes[3].CurrentPlayerColor = GameManager.PlayerColor.Green
	var attacker := Piece.new()
	attacker.CurrentPlayerColor = GameManager.PlayerColor.Green
	attacker.Attack = 1
	cell.SetPiece(attacker)
	assert(heroes[0].Health == 2)
	assert(heroes[1].Health == 4)
	assert(heroes[2].Health == 5)
	assert(heroes[3].Health == 9 and heroes[4].Health == 0)
	cell.SetPiece(attacker)
	assert(heroes[1].Health == 4)
	cell.RemoveMyRef(attacker)
	cell.SetPiece(attacker)
	assert(heroes[1].Health == 4 and heroes[2].Health == 4)
	cell.RemoveMyRef(attacker)
	cell.isThisSafePlace = true
	cell.SetPiece(attacker)
	assert(heroes[1].Health == 4 and heroes[2].Health == 4)
	cell.ClearMe()
	for hero in heroes:
		hero.free()
	attacker.free()
	cell.free()
	print("PASS: single highest-current-health target, stable ties, allies/dead excluded, safe cells")
