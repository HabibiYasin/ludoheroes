extends Node

func _ready() -> void:
	call_deferred("_run")

func _hero() -> Piece:
	var hero := Piece.new()
	hero.MaxHealth = 100
	hero.Health = 100
	hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
	hero.CurrentPosition = 12
	return hero

func _run() -> void:
	var hero := _hero()
	for id: String in hero.StatusCatalog.DEFINITIONS:
		assert(hero.ApplyStatus(id, 2))
		var stackable: bool = hero.StatusCatalog.DEFINITIONS[id].stackable
		assert(hero.ApplyStatus(id, 3) == stackable)
		assert(hero.Status.effects[id].turns == (5 if stackable else 2))
		assert(hero.Status.count(id) == 1)
		assert(ResourceLoader.exists(hero.StatusCatalog.ASSET_PATH + hero.StatusCatalog.DEFINITIONS[id].file))
	hero.ClearStatuses()
	assert(not hero.ApplyStatus("missing", 1))
	assert(not hero.ApplyStatus("Stun", 0))
	hero.ApplyStatus("Stun", 2)
	assert(not hero.CanMoveWithDice(6, 57))
	hero.EndStatusTurn()
	assert(hero.HasStatus("Stun"))
	hero.EndStatusTurn()
	assert(hero.CanMoveWithDice(6, 57))
	hero.ApplyStatus("Frozen", 3)
	assert(not hero.CanMoveWithDice(5, 57))
	assert(hero.CanMoveWithDice(6, 57) and hero.HasStatus("Frozen"))
	hero.MoveBonus = 1
	assert(hero.CanMoveWithDice(6, 57))
	hero.MoveBonus = 0
	hero.ApplyStatus("Slowed", 2)
	hero.ApplyStatus("Slowed", 3)
	assert(not hero.CanMoveWithDice(6, 57))
	hero.RemoveStatus("Frozen")
	assert(hero.GetMoveDistance(6) == 5)
	assert(not hero.CanMoveWithDice(1, 57))
	print("PASS: all status assets, duration stacking, reapplication rejection, Stun, Frozen, Slowed")

	hero.ClearStatuses()
	hero.ApplyStatus("Shield", 3)
	assert(hero.GetIncomingDamage(999) == 0 and hero.HasStatus("Shield"))
	assert(not hero.TakeDamage(999, true, Piece.DamageType.MAGICAL))
	assert(hero.Health == 100 and not hero.HasStatus("Shield"))
	hero.TakeDamage(2)
	assert(hero.Health == 98)
	var attacker := _hero()
	hero.ApplyStatus("Nature Shield", 2)
	hero.ApplyStatus("Nature Shield", 3)
	hero.TakeDamage(3, true, Piece.DamageType.PHYSICAL, attacker)
	assert(hero.Health == 96 and attacker.Health == 99)
	attacker.ApplyStatus("Nature Shield", 2)
	hero.TakeDamage(1, true, Piece.DamageType.MAGICAL, attacker)
	assert(hero.Health == 96 and attacker.Health == 98)
	hero.ApplyStatus("Shield", 2)
	hero.TakeDamage(50, true, Piece.DamageType.PHYSICAL, attacker)
	assert(hero.Health == 96 and attacker.Health == 98)
	attacker.free()

	hero.ClearStatuses()
	hero.ApplyStatus("Bleed", 4)
	for entry in [[1, 0], [2, 1], [5, 2], [6, 3], [10, 3]]:
		hero.Health = 100
		hero.ApplyMovementStatuses(entry[0])
		assert(hero.Health == 100 - entry[1])
	hero.ClearStatuses()
	hero.Health = 100
	hero.ApplyStatus("Thorned", 2)
	hero.ApplyStatus("Thorned", 3)
	hero.ApplyMovementStatuses(6)
	assert(hero.Health == 97)
	hero.ApplyStatus("Drown", 3)
	hero.BeginStatusTurn()
	hero.EndStatusTurn()
	assert(hero.Health == 96)
	hero.BeginStatusTurn()
	hero.ApplyMovementStatuses(2)
	hero.EndStatusTurn()
	assert(hero.Health == 96)
	print("PASS: Shield consumption, Nature Shield reduction/reflection, Bleed cap, Thorned, Drown")

	hero.ClearStatuses()
	hero.ApplyStatus("Cursed")
	for turn in range(3):
		hero.BeginStatusTurn()
		hero.PrepareStatusRoll([1, 6])
		hero.EndStatusTurn()
		assert(not hero.IsInLobby())
	hero.PrepareStatusRoll([4, 1])
	assert(not hero.HasStatus("Cursed"))
	hero.ApplyStatus("Cursed")
	for turn in range(4):
		hero.BeginStatusTurn()
		hero.PrepareStatusRoll([2, 6])
		hero.EndStatusTurn()
	assert(hero.IsInLobby() and hero.Health == hero.MaxHealth and hero.Status.effects.is_empty())
	hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
	hero.CurrentPosition = 12
	hero.ApplyStatus("Confused", 3)
	var mixed := false
	for seed_value in range(100):
		hero.Status.confusion_seed = seed_value
		var route := hero.GetMovementPath(6)
		if route.max() != route.min() and absi(route.back() - 12) < 6:
			mixed = true
			assert(route.size() == 6 and route == hero.GetMovementPath(6))
			break
	assert(mixed)
	hero.CurrentPosition = 0
	assert(hero.GetMovementPath(6).min() >= 0)
	hero.free()
	print("PASS: Cursed four owner turns, dice-4 cleansing, death cleanup, stable mixed Confused steps")
	await _integration()
	get_tree().quit()

func _integration() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	game.get_node("CoreGamplay/BotController").set_process(false)
	game.get_node("CoreGamplay/PlayerIdleController").set_process(false)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	for cell: WayPoint in board.way_points.main_path.get_children():
		cell.isThisSafePlace = false
	var hero: Piece = board.piecesManager.GreenPieces.Pieces[0]
	hero.Attack = 0
	hero.MaxHealth = 50
	hero.Health = 50
	hero.SetCurrentPositionAndCheckKill(12)
	hero.position = hero.CurrentWayPoint.position
	hero.ApplyStatus("Frozen", 3)
	hero.ApplyStatus("Bleed", 3)
	hero.ApplyStatus("Thorned", 2)
	hero.ApplyStatus("Thorned", 3)
	board._on_dice_root_on_dice_rolled([6, 1])
	assert(hero.HasStatus("Frozen"))
	await board._on_player_select_piece(hero)
	assert(hero.CurrentPosition == 18 and hero.Health == 44)
	assert(not hero.HasStatus("Frozen") and hero.Status.effects["Thorned"].turns == 5)
	assert(board.remainingDice == [0, 1])
	assert(hero.get_node("StatusVisuals").markers.size() == 2)
	var core: Node2D = game.get_node("CoreGamplay")
	var visuals = hero.get_node("StatusVisuals")
	for rotation_index in range(4):
		core.rotation = -rotation_index * PI * 0.5
		hero.global_rotation = 0.0
		hero.SetSharedCellLayout(Vector2(24, -18), Vector2(52, 52))
		visuals._process(0.0)
		var bounds := hero.PieceSprite.get_rect()
		var head := hero.PieceSprite.to_global(Vector2(bounds.get_center().x, bounds.position.y))
		assert(visuals.global_position.distance_to(head) < 0.01)
		assert(absf(visuals.global_rotation) < 0.01)
	hero.SetSharedCellLayout(Vector2.ZERO)
	game._update_layout()
	GameManager.HeroInspected.emit(hero)
	var hud = game.get_child(game.get_child_count() - 1)
	assert(hud.hero_status_strip.get_child_count() == 2)
	hero.ClearStatuses()
	hero.ApplyStatus("Confused", 3)
	hero.Status.confusion_seed = 12
	board.remainingDice.assign([6, 1])
	board.SelectDie(0)
	var route := hero.GetMovementPath(6)
	var expected: int = route.back()
	board.move_preview.refresh()
	assert(board.move_preview.previews[hero].target == expected)
	await board._on_player_select_piece(hero)
	assert(hero.CurrentPosition == expected and board.remainingDice == [0, 1])
	# Turn ending processes statuses once for the owner, not once per die.
	hero.ClearStatuses()
	hero.ApplyStatus("Drown", 2)
	hero.BeginStatusTurn()
	var hp := hero.Health
	board.FinishTurn()
	assert(hero.Health == hp - 1 and hero.Status.effects["Drown"].turns == 1)
	board.FinishTurn()
	assert(hero.Health == hp - 1 and hero.Status.effects["Drown"].turns == 1)
	# A blocked hero cannot bypass Stun using a pair summon.
	var yellow: Piece = board.piecesManager.YellowPieces.Pieces[0]
	yellow.ApplyStatus("Stun", 2)
	board.currentPlayerColor = GameManager.PlayerColor.Yellow
	board.remainingDice.assign([2, 4])
	assert(not board.piecesManager.YellowPieces.GetMovablePieces(2, 57).has(yellow))
	# Fatal movement damage removes occupancy before a landing or a home goal.
	board.piecesManager.GreenPieces.Pieces[1].SetCurrentPositionAndCheckKill(3)
	hero.ClearStatuses()
	hero.Health = 1
	hero.ApplyStatus("Bleed", 3)
	board.currentPlayerColor = GameManager.PlayerColor.Green
	board.remainingDice.assign([2, 1])
	board.selectedDiceIndex = 0
	board.currentDiceValue = 2
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerSelectPiece)
	await board._on_player_select_piece(hero)
	assert(hero.IsInLobby() and hero.CurrentWayPoint == null and hero.Status.effects.is_empty())
	for cell: WayPoint in board.way_points.main_path.get_children():
		assert(not cell.myHoldings.has(hero))
	assert(board.remainingDice == [0, 1])
	print("PASS: real movement/preview, Frozen break, stacked duration, owner turn timing, pair-summon block, fatal movement cleanup")
	# A lethal hit and lethal reflection settle both heroes without blocking dice.
	var defender: Piece = board.piecesManager.RedPieces.Pieces[0]
	var cell := board.way_points.green_path[6]
	defender.CurrentState = GameManager.PieceStateEnum.InWayPoint
	defender.CurrentWayPoint = cell
	defender.Health = 1
	defender.ApplyStatus("Nature Shield", 2)
	cell.myHoldings.append(defender)
	hero.Health = 1
	hero.Attack = 0
	hero.SetCurrentPositionAndCheckKill(5)
	hero.Attack = 2
	board.remainingDice.assign([1, 2])
	board.currentDiceValue = 1
	board.selectedDiceIndex = 0
	await board._on_player_select_piece(hero)
	assert(hero.IsInLobby() and defender.IsInLobby())
	assert(hero.Status.effects.is_empty() and defender.Status.effects.is_empty())
	assert(not cell.myHoldings.has(hero) and not cell.myHoldings.has(defender))
	assert(board.remainingDice == [0, 2])
	print("PASS: mutual knockout from Nature Shield returns both heroes and continues dice")
	game.queue_free()
	await get_tree().process_frame
