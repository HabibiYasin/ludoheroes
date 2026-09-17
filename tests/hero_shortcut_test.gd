extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	get_tree().create_timer(15).timeout.connect(func(): get_tree().quit(1))
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	add_child(game)
	game.get_node("CoreGamplay/BotController").set_process(false)
	var idle = game.get_node("CoreGamplay/PlayerIdleController")
	idle.Enabled = false
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var hud = game.get_child(game.get_child_count() - 1)
	for hero: Piece in board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor).Pieces:
		hero.EquipItem(0)
		hero.EquipItem(1)
	# All four fixed hero buttons summon, including switching from an unusable die.
	for index in range(4):
		board._on_dice_root_on_dice_rolled([1, 6])
		board.SelectDie(0)
		hud._refresh_recommendations()
		var hero: Piece = hud.recommendations[index]
		assert(hero.IsInLobby())
		idle.AutoPlaying = true
		_click(hud.recommendation_buttons[index])
		while GameManager.GameCurrentState == GameManager.GameStateEnum.Null:
			await get_tree().process_frame
		assert(not hero.IsInLobby() and hero.CurrentPosition == 0)
		assert(board.remainingDice == [1, 0])
		assert(not idle.AutoPlaying)
		assert(hud.inspected_hero == hero)
		# Pause must prevent a shortcut from starting a move.
		hud._refresh_recommendations()
		get_tree().paused = true
		hud._inspect_recommendation(0)
		assert(board.remainingDice == [1, 0])
		get_tree().paused = false
		# The remaining die moves the summoned hero, using the same action path.
		var moving: Piece = hud.recommendations[0]
		var target := moving.CurrentPosition + moving.GetMoveDistance(1)
		_click(hud.recommendation_buttons[0])
		while GameManager.GameCurrentState == GameManager.GameStateEnum.Null:
			await get_tree().process_frame
		assert(moving.CurrentPosition == target)
		# Restore the local turn for the next independent button scenario.
		board.currentPlayerColor = GameManager.LocalPlayerColor
		board.currentPlayerTurnIndex = int(GameManager.LocalPlayerColor)
	print("PASS: all four hero shortcuts summon/move, select a legal die, reset autoplay and respect pause")
	get_tree().quit()

func _click(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_transform_with_canvas() * (button.size * 0.5)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
