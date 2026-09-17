extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_match(true)
	await _check_match(false)
	print("PASS: actual final-goal pipeline, score winner differs from finisher, victory/defeat audio, click-through, goals, kill persistence, ranking, MVP, MMR, restart reset")
	get_tree().quit()

func _check_match(local_wins: bool) -> void:
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Green
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	board.BotsEnabled = false
	add_child(game)
	var hud = game.get_child(game.get_child_count() - 1)
	var overlay = hud.match_results
	assert(not overlay.visible)
	# A premature game-over notification must not start result music.
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.GameOver)
	assert(not overlay.presented and not overlay.sound.playing)
	assert(GameAudio.music.playing)
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
	var scoring_color := GameManager.PlayerColor.Green if local_wins else GameManager.PlayerColor.Red
	var finishing_color := GameManager.PlayerColor.Red if local_wins else GameManager.PlayerColor.Green
	var scoring_group := board.piecesManager.GetPieceGroupBasedOnType(scoring_color)
	var finishing_group := board.piecesManager.GetPieceGroupBasedOnType(finishing_color)
	for hero: Piece in scoring_group.Pieces:
		assert(hero.MatchScore == 0 and not hero.GoalScored)
	var mvp: Piece = scoring_group.Pieces[0]
	for i in range(11):
		mvp.RecordKill()
	mvp.SendBackToLobby()
	assert(mvp.MatchScore == 110 and mvp.MatchKills == 11)
	for group in [scoring_group, finishing_group]:
		for i in range(3):
			var hero: Piece = group.Pieces[i]
			hero.SetCurrentPositionAndCheckKill(board.GetPathCount(hero.CurrentPlayerColor) - 1)
			hero.RecordGoal() # Duplicate notification must not double-count.
	assert(mvp.MatchScore == 210)
	var final_hero: Piece = finishing_group.Pieces[3]
	final_hero.SetCurrentPositionAndCheckKill(board.GetPathCount(finishing_color) - 2)
	board.currentPlayerColor = finishing_color
	board.currentPlayerTurnIndex = int(finishing_color)
	board._on_dice_root_on_dice_rolled([1, 2])
	await board._on_player_select_piece(final_hero)
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.GameOver)
	assert(overlay.visible and overlay.presented and overlay.is_victory == local_wins)
	assert(overlay.sound.stream.resource_path == "res://Sounds/Music/" + ("Victory.mp3" if local_wins else "Defeated.mp3"))
	assert(not GameAudio.music.playing)
	assert(overlay.banner.texture.resource_path.ends_with("Victory.png" if local_wins else "Defeated.png"))
	assert(overlay.results[0].color == scoring_color and overlay.results[0].score == 410)
	assert(overlay.results[0].goals == 3 and overlay.results[0].mvp == mvp)
	assert(overlay.results[1].score == 400 and overlay.results[1].goals == 4)
	for index in range(4):
		assert(overlay.results[index].mmr == [100, 50, 25, -50][index])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	overlay._on_backdrop_input(click)
	assert(overlay.showing_scores and overlay.table != null)
	var table: Control = overlay.table
	overlay.ShowScores()
	assert(overlay.table == table)
	for color in range(4):
		var row: Panel = table.get_node("ResultRow%d" % color)
		assert(row.get_theme_stylebox("panel").border_color == overlay.TEAM_COLORS[color])
	# Optional rendered capture for reviewing the real UI.
	if "--capture-results" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://match_results_%s.png" % ("victory" if local_wins else "defeated"))
	game.queue_free()
	await get_tree().process_frame
