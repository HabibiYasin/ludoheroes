extends Node

func _ready() -> void:
	var saved := ConfigFile.new()
	saved.load("user://settings.cfg")
	var menu = load("res://Levels/MainMenu.tscn").instantiate()
	add_child(menu)
	assert(GameAudio.music.playing and GameAudio.music.stream.loop)
	await get_tree().create_timer(0.2).timeout
	var position := GameAudio.music.get_playback_position()
	GameAudio.play_main_music()
	assert(GameAudio.music.get_playback_position() >= position)
	menu.queue_free()
	await get_tree().process_frame
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	assert(GameAudio.music.playing)
	var dice: Dice = game.get_node("CoreGamplay/Dice/DiceRoot")
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
	dice.RollDice()
	assert(GameAudio.dice_sound.playing)
	get_tree().paused = true
	await get_tree().process_frame
	assert(GameAudio.dice_sound.stream_paused)
	assert(not GameAudio.music.stream_paused)
	get_tree().paused = false
	await dice.OnDiceRolled
	GameAudio.set_muted("Music", false)
	GameAudio.set_muted("SFX", false)
	GameAudio.set_level("Music", 3)
	GameAudio.set_muted("Music", true)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	GameAudio.set_muted("Music", false)
	assert(GameAudio.levels.Music == 3)
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.6))
	GameAudio.set_level("SFX", 99)
	assert(GameAudio.levels.SFX == 5)
	GameAudio.set_level("SFX", -1)
	assert(GameAudio.levels.SFX == 1)
	GameAudio.set_muted("SFX", true)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert(GameAudio.music.bus == "Music" and GameAudio.dice_sound.bus == "SFX" and GameAudio.attack_sound.bus == "SFX")
	var stored := ConfigFile.new()
	stored.load("user://settings.cfg")
	assert(stored.get_value("audio", "Music_level") == 3)
	assert(stored.get_value("audio", "SFX_muted"))
	saved.save("user://settings.cfg")
	GameAudio.stop_for_results()
	assert(not GameAudio.music.playing and not GameAudio.dice_sound.playing)
	GameAudio.play_main_music()
	assert(GameAudio.music.playing)
	print("PASS: continuous looping music, dice sound, pause, master volume and music restart")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
