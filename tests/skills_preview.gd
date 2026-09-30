extends Node

func _ready() -> void:
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Blue
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var hud = game.get_child(game.get_child_count() - 1)
	var caster: Piece = board.piecesManager.BluePieces.Pieces[1]
	_place(board, caster, 19)
	var enemies: Array[Piece] = []
	enemies.assign(board.piecesManager.RedPieces.Pieces)
	for index in range(4):
		_place(board, enemies[index], [18, 20, 22, 23][index])
		enemies[index].Health = 6
		enemies[index].MaxHealth = 6
	board._on_dice_root_on_dice_rolled([6, 2])
	GameManager.HeroInspected.emit(caster)
	var mode := "buttons"
	var args := OS.get_cmdline_user_args()
	if "--targets" in args:
		mode = "targets"
		hud._use_hero_skill(1, true)
	elif "--battle" in args or "--announcement" in args:
		board.skills.cast(caster, 0)
		mode = "announcement" if "--announcement" in args else "battle"
		if mode == "battle":
			while board.attack_presentation.stage == null:
				await get_tree().process_frame
			await get_tree().create_timer(0.3).timeout
		else:
			await get_tree().create_timer(0.2).timeout
	if "--capture" in args:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/skills_%s.png" % mode)
		get_tree().quit()

func _place(board: BoardManager, hero: Piece, cell_number: int) -> void:
	var cell: WayPoint = board.way_points.main_path.get_node(str(cell_number))
	hero.CurrentPosition = board.way_points.GetPath(hero.CurrentPlayerColor).find(cell)
	hero.CurrentWayPoint = cell
	hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
	hero.position = cell.position
	cell.myHoldings.append(hero)
