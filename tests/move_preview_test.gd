extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 30.0
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Blue
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	board.BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	var preview = board.move_preview
	var heroes := board.piecesManager.BluePieces.Pieces
	for index in range(4):
		heroes[index].SetCurrentPositionAndCheckKill(index * 4)
	board._on_dice_root_on_dice_rolled([3, 4])
	assert(preview.previews.size() == 4)
	for hero: Piece in heroes:
		var entry: Dictionary = preview.previews[hero]
		assert(entry.target == hero.CurrentPosition + hero.GetMoveDistance(3))
		assert(entry.sprite.texture == hero.PieceSprite.texture)
		assert(entry.sprite.modulate.a > 0 and entry.sprite.modulate.a < 0.5)
		assert(entry.sprite.get_script() == null)
		assert(entry.sprite.global_position.is_equal_approx(entry.cell.global_position))
		assert(is_zero_approx(entry.sprite.global_rotation))
		assert(entry.cell.myHoldings.all(func(occupant: Piece): return occupant.get_instance_id() != entry.sprite.get_instance_id()))
	board.SelectDie(1)
	for hero: Piece in heroes:
		assert(preview.previews[hero].target == hero.CurrentPosition + hero.GetMoveDistance(4))
	var mover: Piece = heroes[0]
	mover.EquipItem(2)
	assert(preview.previews[mover].target == mover.CurrentPosition + 5)
	var destination: int = preview.previews[mover].target
	board._on_player_select_piece(mover)
	assert(preview.previews.is_empty())
	while GameManager.GameCurrentState == GameManager.GameStateEnum.Null:
		if board.item_choice.stage != null:
			board.item_choice._select(board.item_choice.offered[0])
		await get_tree().process_frame
	assert(mover.CurrentPosition == destination and board.remainingDice == [3, 0])
	assert(preview.previews.size() == 4)
	# Overlapping targets must remain separate sprites without adding real pieces.
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
	for hero: Piece in heroes:
		hero.SendBackToLobby()
		hero.MoveBonus = 0
		hero.SetCurrentPositionAndCheckKill(0)
	board._on_dice_root_on_dice_rolled([4, 3])
	assert(preview.previews.size() == 4)
	var positions: Array[Vector2] = []
	for hero: Piece in heroes:
		var ghost: Sprite2D = preview.previews[hero].sprite
		assert(not positions.has(ghost.global_position))
		positions.append(ghost.global_position)
	# Board rotation and scaling preserve upright artwork and centered destinations.
	var core: Node2D = game.get_node("CoreGamplay")
	core.rotation += PI * 0.5
	core.scale *= 0.8
	preview._update_transforms()
	for hero: Piece in heroes:
		assert(is_zero_approx(preview.previews[hero].sprite.global_rotation))
	heroes[0].SendBackToLobby()
	heroes[1].CurrentPosition = board.GetPathCount(GameManager.PlayerColor.Blue) - 2
	heroes[2].IsInHome = true
	preview.refresh()
	assert(preview.previews.size() == 1 and preview.previews.has(heroes[3]))
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
	assert(preview.previews.is_empty())
	board.BotsEnabled = true
	board.currentPlayerColor = GameManager.PlayerColor.Red
	board._on_dice_root_on_dice_rolled([6, 3])
	assert(preview.previews.is_empty())
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.GameOver)
	assert(preview.previews.is_empty())
	game.queue_free()
	await get_tree().process_frame
	print("PASS: four previews, selected dice, Runner/items, actual landing, movement cleanup, shared targets, rotation/scale, illegal/lobby/home filtering and bot turns")
	get_tree().quit()
