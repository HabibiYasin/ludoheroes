extends Node

const Catalog = preload("res://Scripts/ItemCatalog.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	get_tree().create_timer(20).timeout.connect(func(): get_tree().quit(1))
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Green
	for id in range(6):
		var hero := Piece.new()
		hero.HeroId = "Garruk"
		hero.InitializeStats()
		var before := [hero.Attack, hero.MaxHealth, hero.MoveBonus, hero.SkillDamage, hero.PhysicalDefense, hero.MagicalDefense]
		var health := hero.Health
		assert(hero.EquipItem(id) and hero.EquipItem(id))
		var after := [hero.Attack, hero.MaxHealth, hero.MoveBonus, hero.SkillDamage, hero.PhysicalDefense, hero.MagicalDefense]
		for stat in range(6):
			assert(after[stat] == before[stat] + (2 if stat == id else 0))
		assert(hero.Health == health)
		assert(hero.Items[id] == 2 and hero.Items.size() == 1)
		assert(hero.EquipItem((id + 1) % 6))
		assert(not hero.EquipItem((id + 2) % 6))
		hero.StackRandomItem()
		assert(hero.Items.size() == 2)
		assert(int(hero.Items.values()[0]) + int(hero.Items.values()[1]) == 4)
		assert(Catalog.texture(id) != null)
		hero.free()
	for i in range(100):
		var choices := Catalog.choices()
		assert(choices.size() == 2 and choices[0] != choices[1])
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	board.BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	var hud = game.get_child(game.get_child_count() - 1)
	var hero: Piece = board.piecesManager.GreenPieces.Pieces[0]
	var stars: Array[int] = []
	for color in range(4):
		assert(board.way_points.IsItemTile(board.way_points.GetWayPoint(0, color)))
	for index in range(board.way_points.green_path.size()):
		if board.way_points.IsItemTile(board.way_points.green_path[index]):
			stars.append(index)
	assert(stars.size() == 8)
	# Summoning onto our own spawn awards an item before consuming the die.
	board._on_dice_root_on_dice_rolled([6, 4])
	board._on_player_select_piece(hero)
	while board.item_choice.stage == null:
		await get_tree().process_frame
	assert(board.remainingDice == [6, 4])
	var spawn_choice: int = board.item_choice.offered[0]
	hud._refresh_recommendations()
	assert(hud.recommendations.size() == 4)
	assert(hud.recommendation_icons[0].texture == hero.PieceTexture)
	assert(board.item_choice.buttons[board.item_choice.offered[0]].disabled)
	while board.item_choice.entering:
		await get_tree().process_frame
	hud._refresh_recommendations()
	assert(not board.item_choice.buttons[spawn_choice].disabled)
	_click(board.item_choice.buttons[spawn_choice])
	assert(board.item_choice.offered.is_empty())
	# Repeated taps cannot award the second item or inspect a hero.
	hud._inspect_recommendation(1)
	while board.item_choice.stage != null:
		await get_tree().process_frame
	assert(hero.Items.get(spawn_choice) == 1 and board.remainingDice == [0, 4])
	assert(hero.Items.size() == 1)
	hud._refresh_recommendations()
	assert(hud.recommendations.size() == 4)
	hero.MoveBonus = 0
	# Award checks include every enemy spawn, regardless of the hero's color.
	board.BotsEnabled = true
	board.currentPlayerColor = GameManager.PlayerColor.Red
	for color in range(1, 4):
		var visitor := Piece.new()
		visitor.InitializeStats()
		visitor.CurrentWayPoint = board.way_points.GetWayPoint(0, color)
		await board.AwardLandingItem(visitor)
		assert(visitor.Items.size() == 1)
		visitor.free()
	board.BotsEnabled = false
	board.currentPlayerColor = GameManager.PlayerColor.Green
	var destination := stars[1]
	hero.CurrentWayPoint.RemoveMyRef(hero)
	hero.SetCurrentPositionAndCheckKill(destination - 1)
	board._on_dice_root_on_dice_rolled([1, 4])
	board._on_player_select_piece(hero)
	while board.item_choice.stage == null:
		await get_tree().process_frame
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.Null)
	assert(board.remainingDice == [1, 4])
	var chosen: int = board.item_choice.offered[1]
	while board.item_choice.entering:
		await get_tree().process_frame
	hud._refresh_recommendations()
	_click(board.item_choice.buttons[chosen])
	assert(board.item_choice.offered.is_empty())
	while board.item_choice.stage != null:
		await get_tree().process_frame
	assert(hero.Items.has(chosen) and board.remainingDice == [0, 4])
	hero.Items.clear()
	# A second award can stack the same type without using another slot.
	board.AwardLandingItem(hero)
	assert(board.item_choice.stage != null)
	assert(board.item_choice.remaining == 10.0)
	await board.item_choice._select(board.item_choice.offered[0])
	while hero.Items.size() < 2:
		for id in range(6):
			if not hero.Items.has(id):
				hero.EquipItem(id)
				break
	var total: int = int(hero.Items.values()[0]) + int(hero.Items.values()[1])
	await board.AwardLandingItem(hero)
	assert(board.item_choice.stage == null)
	assert(int(hero.Items.values()[0]) + int(hero.Items.values()[1]) == total + 1)
	var other: Piece = board.piecesManager.GreenPieces.Pieces[1]
	other.SetCurrentPositionAndCheckKill(destination)
	var idle = game.get_node("CoreGamplay/PlayerIdleController")
	idle.AutoPlaying = true
	board.AwardLandingItem(other)
	assert(board.item_choice.stage != null)
	assert(board.item_choice.remaining == 5.0)
	get_tree().paused = true
	var seconds: float = board.item_choice.remaining
	await get_tree().process_frame
	assert(board.item_choice.remaining == seconds)
	hud._refresh_recommendations()
	assert(get_tree().paused)
	hud._inspect_recommendation(0)
	assert(board.item_choice.offered.size() == 2)
	get_tree().paused = false
	while board.item_choice.entering:
		await get_tree().process_frame
	board.item_choice._process(4.9)
	assert(other.Items.is_empty() and board.item_choice.stage != null)
	board.item_choice._process(0.11)
	assert(board.item_choice.offered.is_empty())
	while board.item_choice.stage != null:
		await get_tree().process_frame
	assert(other.Items.size() == 1 and board.item_choice.stage == null)
	hud._refresh_recommendations()
	assert(hud.recommendations.size() == 4)
	var bot: Piece = board.piecesManager.RedPieces.Pieces[0]
	bot.SetCurrentPositionAndCheckKill(board.way_points.red_path.find(hero.CurrentWayPoint))
	board.BotsEnabled = true
	board.currentPlayerColor = GameManager.PlayerColor.Red
	await board.AwardLandingItem(bot)
	assert(bot.Items.size() == 1 and board.item_choice.stage == null)
	var mover := Piece.new()
	mover.EquipItem(2)
	mover.EquipItem(2)
	assert(mover.GetMoveDistance(6) == 6 and mover.CanMoveWithDice(6, 10))
	mover.CurrentState = GameManager.PieceStateEnum.InWayPoint
	mover.CurrentPosition = 6
	assert(mover.GetMoveDistance(1) == 3 and mover.CanMoveWithDice(1, 10))
	assert(not mover.CanMoveWithDice(2, 10))
	mover.SendBackToLobby()
	assert(mover.MoveBonus == 2 and mover.Items[2] == 2)
	mover.free()
	game.queue_free()
	await get_tree().process_frame
	print("PASS: six item stats, unique offers, two type cap, stacks, eight reward tiles, own/enemy spawn rewards, summon reward, manual/timeout/bot awards, pause, die continuation and move bonus")
	get_tree().quit()

func _click(button: BaseButton) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
