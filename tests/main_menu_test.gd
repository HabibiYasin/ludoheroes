extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var saved := ConfigFile.new()
	saved.load("user://settings.cfg")
	var menu = load("res://Levels/MainMenu.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	assert(menu._home.visible)
	assert(not menu._settings.visible)
	menu._show_settings()
	assert(menu._settings.visible)
	assert(not menu._home.visible)
	var row: Dictionary = menu._audio_settings.controls["Music"]
	GameAudio.set_muted("Music", false)
	row.mute.pressed.emit()
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	row.mute.pressed.emit()
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	GameAudio.set_level("Music", 1)
	assert(row.left.disabled and row.level.text == "1 / 5")
	row.right.pressed.emit()
	assert(GameAudio.levels.Music == 2)
	menu._show_home()
	var stored := ConfigFile.new()
	stored.load("user://settings.cfg")
	assert(stored.get_value("audio", "Music_level") == 2)
	saved.save("user://settings.cfg")
	menu._start_game()
	await get_tree().scene_changed
	assert(get_tree().current_scene.scene_file_path == "res://Levels/Level_MainGamePlay.tscn")
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice)
	assert(get_tree().get_first_node_in_group("BoardManager") != null)
	print("PASS: home, settings, volume, Start opens gameplay")
	get_tree().quit()
