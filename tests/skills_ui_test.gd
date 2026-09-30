extends Node

func _ready() -> void:
	call_deferred("_run")

func _input_button(button: Button, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas() * (button.size * 0.5)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	get_viewport().push_input(event, true)

func _run() -> void:
	Engine.time_scale = 20.0
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var hud = game.get_child(game.get_child_count() - 1)
	board.currentPlayerColor = GameManager.PlayerColor.Red
	board.currentPlayerTurnIndex = 3
	var tank: Piece = board.piecesManager.RedPieces.Pieces[2]
	tank.SetCurrentPositionAndCheckKill(4)
	board._on_dice_root_on_dice_rolled([1, 6])
	var book: Button = hud.skill_buttons[2]
	assert(book.visible)
	var position_before := tank.CurrentPosition
	_input_button(book, true)
	_input_button(book, false)
	assert(tank.SkillCooldown == 1 and GameManager.GameCurrentState == GameManager.GameStateEnum.Null)
	while GameManager.GameCurrentState == GameManager.GameStateEnum.Null:
		await get_tree().process_frame
	assert(tank.CurrentPosition == position_before and tank.HasStatus("Shield"))
	assert(board.remainingDice == [0, 6] and not book.visible)
	# Hold a targeting skill: opening/releasing the book consumes neither die nor cooldown.
	var suki: Piece = board.piecesManager.RedPieces.Pieces[1]
	suki.SetCurrentPositionAndCheckKill(4)
	var enemies: Array[Piece] = [board.piecesManager.GreenPieces.Pieces[0], board.piecesManager.GreenPieces.Pieces[1]]
	for index in range(enemies.size()):
		var cell := board.way_points.red_path[5 + index]
		enemies[index].CurrentState = GameManager.PieceStateEnum.InWayPoint
		enemies[index].CurrentPosition = board.way_points.green_path.find(cell)
		enemies[index].CurrentWayPoint = cell
		enemies[index].Health = 10
		enemies[index].MaxHealth = 10
		cell.myHoldings.append(enemies[index])
	board._on_dice_root_on_dice_rolled([3, 6])
	book = hud.skill_buttons[1]
	assert(book.visible)
	_input_button(book, true)
	book._process(0.5)
	assert(hud.skill_target_picker.stage != null and get_tree().paused)
	_input_button(book, false)
	assert(suki.SkillCooldown == 0 and board.remainingDice == [3, 6])
	var target_button: Button
	for child in hud.skill_target_picker.stage.get_children():
		if child is Button and child.tooltip_text.begins_with(enemies[1].HeroId):
			target_button = child
	assert(target_button != null)
	_input_button(target_button, true)
	_input_button(target_button, false)
	assert(hud.skill_target_picker.selected == [enemies[1]])
	var confirm: Button = hud.skill_target_picker.confirm
	_input_button(confirm, true)
	_input_button(confirm, false)
	assert(not get_tree().paused and hud.skill_target_picker.stage == null)
	while GameManager.GameCurrentState == GameManager.GameStateEnum.Null:
		await get_tree().process_frame
	assert(enemies[0].Health == 10 and enemies[1].Health == 8)
	assert(board.remainingDice == [0, 6])
	suki.SkillCooldown = 0
	board._on_dice_root_on_dice_rolled([3, 6])
	_input_button(book, true)
	book._process(0.5)
	_input_button(book, false)
	assert(get_tree().paused)
	var cancel: Button
	for child in hud.skill_target_picker.stage.get_children():
		if child is Button and child.text == "Batal":
			cancel = child
	assert(cancel != null)
	_input_button(cancel, true)
	_input_button(cancel, false)
	assert(not get_tree().paused and board.remainingDice == [3, 6] and suki.SkillCooldown == 0)
	print("PASS: book tap casts without moving, hold/release opens targeting without casting, manual target confirmation consumes one die")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
