extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var knowledge = preload("res://Scripts/Knowledge.gd").new()
	add_child(knowledge)
	assert(get_tree().paused and knowledge.section == 0)
	for child in knowledge.page.get_children():
		if child is Button:
			assert(child.get_child(0).size == Vector2(185, 137))
	for id: String in preload("res://Scripts/HeroCatalog.gd").HEROES:
		assert(knowledge.page.get_node_or_null(id) != null)
		knowledge.page.get_node(id).pressed.emit()
		assert(knowledge.popup != null)
		knowledge.close_popup()
	_click(knowledge.tabs[1])
	assert(knowledge.section == 1)
	assert(knowledge.selected_item == 0)
	for index in range(6):
		_click(knowledge.equipment_buttons[index])
		assert(knowledge.selected_item == index)
	_click(knowledge.tabs[2])
	assert(knowledge.section == 2)
	for button: Button in knowledge.article_buttons:
		button.pressed.emit()
		assert(not knowledge.article_body.text.is_empty())
	knowledge.close()
	assert(not get_tree().paused)
	await get_tree().process_frame
	get_tree().paused = true
	knowledge = preload("res://Scripts/Knowledge.gd").new()
	add_child(knowledge)
	knowledge.close()
	assert(get_tree().paused)
	get_tree().paused = false
	await get_tree().process_frame
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	var hud = game.get_child(game.get_child_count() - 1)
	hud._open_skill("Knowledge")
	knowledge = hud.get_child(hud.get_child_count() - 1)
	assert(knowledge.section == 0 and get_tree().paused)
	if "--capture" in OS.get_cmdline_user_args():
		for mode in ["heroes", "hero", "equipment", "encyclopedia"]:
			match mode:
				"hero": knowledge.show_hero("Octavus")
				"equipment": knowledge.show_section(1)
				"encyclopedia": knowledge.show_section(2)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.godot/knowledge_%s.png" % mode)
	knowledge.close()
	assert(not get_tree().paused)
	game.queue_free()
	await get_tree().process_frame
	var menu = load("res://Levels/MainMenu.tscn").instantiate()
	add_child(menu)
	var entry: Button
	for button in menu._home.get_children():
		if button is Button and button.text == "Knowledge":
			entry = button
	assert(entry != null)
	entry.pressed.emit()
	knowledge = menu.get_child(menu.get_child_count() - 1)
	assert(knowledge.section == 0 and get_tree().paused)
	knowledge.close()
	assert(not get_tree().paused)
	menu.queue_free()
	await get_tree().process_frame
	print("PASS: Knowledge hero roster/popups, equipment default/selection, encyclopedia, in-game pause and return")
	get_tree().quit()

func _click(button: Button) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_transform_with_canvas() * (button.size * 0.5)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		get_viewport().push_input(event, true)
