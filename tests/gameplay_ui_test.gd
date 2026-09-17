extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	get_tree().create_timer(25).timeout.connect(func(): get_tree().quit(1))
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Blue
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	add_child(game)
	game.get_node("CoreGamplay/BotController").set_process(false)
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var dice: Dice = game.get_node("CoreGamplay/Dice/DiceRoot")
	var hud = game.get_child(game.get_child_count() - 1)
	assert(hud.recommendations.size() == 4)
	assert(hud.recommendation_buttons.size() == 4)
	assert(hud.item_icons.size() == 2)
	assert(hud.hero_name.text.contains(" - ("))
	assert(hud.faction_button.portrait.texture.resource_path.ends_with("Nerathis Finish.png"))
	for hero: Piece in hud.recommendations:
		assert(hero.CurrentPlayerColor == GameManager.LocalPlayerColor)
	assert(not dice.roll_stage.visible)
	for value in [1, 5, 10, 11, 20, 21, 261]:
		hud._refresh_round(value)
		assert(hud.round_label.text == ({1: "A", 5: "A", 10: "A", 11: "B", 20: "B", 21: "C", 261: "AA"})[value])
		for i in range(10):
			assert(hud.round_crosses[i].visible == (i < (value - 1) % 10))
	hud._refresh_round(3)
	assert(hud.round_numbers[4].get_theme_color("font_color") == hud.GOLD)
	assert(hud.round_numbers[9].get_theme_color("font_color") == Color("ff414b"))
	# The last portrait also rolls, regardless of whether its piece has finished.
	dice.IsTestRun = true
	_click(hud.recommendation_buttons[3])
	assert(dice._is_rolling and dice.roll_stage.visible)
	assert(not dice.TryRollFromBoard(Vector2(960, 580)))
	await get_tree().create_timer(0.25).timeout
	await _capture("ui-dice-roll.png")
	await dice.OnDiceRolled
	assert(not dice.roll_stage.visible)
	assert(board.remainingDice == [6, 6])
	assert(dice.roll_sprites[0].texture == dice.Maindice.texture)
	assert(dice.roll_sprites[1].texture == dice.SecondDice.texture)
	# Stable four-slot roster, including unavailable pieces and pair summons.
	var roster: Array[Piece] = hud.recommendations.duplicate()
	board._on_dice_root_on_dice_rolled([2, 4])
	assert(hud._hero_die(roster[3]) >= 0)
	board.remainingDice.assign([1, 1])
	board.currentDiceValue = 1
	hud._refresh_recommendations()
	assert(hud.recommendations == roster)
	assert(hud._hero_action(roster[3]) == "blocked")
	assert(hud.hero_portraits[3].shade.color == Color(0, 0, 0, 0.68))
	# Predict the same combat target as the board, without changing its holdings.
	var attacker := roster[0]
	attacker.CurrentPosition = 0
	attacker.CurrentState = GameManager.PieceStateEnum.InWayPoint
	attacker.Health = 1
	attacker.MaxHealth = 3
	var target := board.way_points.GetWayPoint(1, attacker.CurrentPlayerColor)
	var defender: Piece = board.piecesManager.RedPieces.Pieces[0]
	defender.CurrentState = GameManager.PieceStateEnum.InWayPoint
	defender.CurrentWayPoint = target
	target.myHoldings.append(defender)
	hud._refresh_recommendations()
	assert(hud._hero_action(attacker) == "attack")
	assert(hud.hero_portraits[0].ring_color == Color("ff414b"))
	assert(hud.hero_portraits[0].shade.color == Color(1, 0.06, 0.09, 0.40))
	assert(target.myHoldings == [defender])
	target.isThisSafePlace = true
	assert(hud._hero_action(attacker) == "move")
	target.isThisSafePlace = false
	target.myHoldings.clear()
	roster[3].IsInHome = true
	hud._refresh_recommendations()
	assert(hud._hero_action(roster[3]) == "blocked")
	# Bot turns retain the human roster; local multiplayer follows the active human.
	board.currentPlayerColor = GameManager.PlayerColor.Red
	hud._refresh_recommendations()
	assert(hud.recommendations == roster)
	board.BotsEnabled = false
	hud._refresh_recommendations()
	assert(hud.displayed_player == GameManager.PlayerColor.Red)
	assert(hud.recommendations == board.piecesManager.RedPieces.Pieces)
	board.BotsEnabled = true
	board.currentPlayerColor = GameManager.PlayerColor.Blue
	hud._refresh_recommendations()
	for title in ["Domain Authority", "Battle Status", "Knowledge", "Chat & Emoji"]:
		hud._open_skill(title)
		assert(get_tree().paused and hud.skill_panel.visible)
		assert(hud.skill_description.text.contains("Coming soon"))
		hud._close_menu()
		assert(not get_tree().paused and not hud.modal.visible)
	hud._open_settings()
	assert(get_tree().paused and hud.settings_panel.visible and not hud.menu_panel.visible)
	await _capture("ui-settings.png")
	hud._close_menu()
	roster[1].EquipItem(2)
	roster[1].EquipItem(5)
	hud._inspect_hero(roster[1])
	assert(hud.item_icons[0].texture != null and hud.item_icons[1].texture != null)
	hud._open_storage()
	assert(get_tree().paused and hud.storage_panel.visible)
	# Disposable storage must never expose hero equipment.
	assert(hud.storage_content.get_child(1).text == "Belum ada item disposable.")
	await _capture("ui-storage.png")
	hud._close_menu()
	hud.show_player_chat(int(GameManager.LocalPlayerColor), "Pesan contoh")
	hud.show_player_emote(int(GameManager.LocalPlayerColor), ":)")
	var chat: Label = hud.chat_bubbles[int(GameManager.LocalPlayerColor)]
	assert(chat.visible and hud.emote.visible)
	assert(chat.position.y <= hud.scores[int(GameManager.LocalPlayerColor)].position.y)
	await _capture("ui-overview.png")
	await get_tree().create_timer(5.1).timeout
	assert(not chat.visible and not hud.emote.visible)
	game.queue_free()
	await get_tree().process_frame
	print("PASS: rounds, four human portraits, die animation, legal actions, attack/safe preview, health overlays, hotseat, popups, disposable storage, chat presentation")
	get_tree().quit()

func _capture(filename: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture-ui"):
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://" + filename)
	print("CAPTURE: ", OS.get_user_data_dir().path_join(filename))

func _click(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_transform_with_canvas() * (button.size * 0.5)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
