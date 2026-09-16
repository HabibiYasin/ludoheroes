extends Node

const Catalog = preload("res://Scripts/ItemCatalog.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
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
	var hero: Piece = board.piecesManager.GreenPieces.Pieces[0]
	var stars: Array[int] = []
	for color in range(4):
		assert(not board.way_points.IsItemTile(board.way_points.GetWayPoint(0, color)))
	for index in range(board.way_points.green_path.size()):
		if board.way_points.IsItemTile(board.way_points.green_path[index]):
			stars.append(index)
	assert(stars.size() == 4)
	hero.SetCurrentPositionAndCheckKill(0)
	await board.AwardLandingItem(hero)
	assert(hero.Items.is_empty() and board.item_choice.stage == null)
	var destination := stars[0]
	hero.CurrentWayPoint.RemoveMyRef(hero)
	hero.SetCurrentPositionAndCheckKill(destination - 1)
	board._on_dice_root_on_dice_rolled([1, 4])
	board._on_player_select_piece(hero)
	while board.item_choice.stage == null:
		await get_tree().process_frame
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.Null)
	assert(board.remainingDice == [1, 4])
	var chosen: int = board.item_choice.offered[0]
	board.item_choice._select(chosen, true)
	assert(hero.Items.get(chosen) == 1 and board.remainingDice == [0, 4])
	# A second award can stack the same type without using another slot.
	board.AwardLandingItem(hero)
	assert(board.item_choice.stage != null)
	assert(board.item_choice.remaining == 10.0)
	board.item_choice._select(board.item_choice.offered[0])
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
	get_tree().paused = false
	board.item_choice._process(4.9)
	assert(other.Items.is_empty() and board.item_choice.stage != null)
	board.item_choice._process(0.11)
	assert(other.Items.size() == 1 and board.item_choice.stage == null)
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
	print("PASS: six item stats, unique offers, two type cap, stacks, four stars, no start rewards, manual/timeout/bot awards, pause, die continuation and move bonus")
	get_tree().quit()
