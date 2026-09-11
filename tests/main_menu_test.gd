extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu = load("res://Levels/MainMenu.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	assert(menu._home.visible)
	assert(not menu._settings.visible)
	menu._show_settings()
	assert(menu._settings.visible)
	assert(not menu._home.visible)
	menu._apply_volume(0)
	assert(AudioServer.is_bus_mute(0))
	menu._apply_volume(80)
	assert(not AudioServer.is_bus_mute(0))
	menu._start_game()
	await get_tree().scene_changed
	assert(get_tree().current_scene.scene_file_path == "res://Levels/Level_MainGamePlay.tscn")
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice)
	assert(get_tree().get_first_node_in_group("BoardManager") != null)
	print("PASS: home, settings, volume, Start opens gameplay")
	get_tree().quit()
