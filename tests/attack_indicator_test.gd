extends Node

var board: BoardManager
var hud

func _ready() -> void:
	call_deferred("_run")

func _place(hero: Piece, cell: WayPoint) -> void:
	if hero.CurrentWayPoint != null:
		hero.CurrentWayPoint.RemoveMyRef(hero)
	hero.CurrentPosition = board.way_points.GetPath(hero.CurrentPlayerColor).find(cell)
	hero.CurrentWayPoint = cell
	hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
	hero.position = cell.position
	cell.myHoldings.append(hero)

func _run() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	board = game.get_node("CoreGamplay/Board/board_GamePlay")
	hud = game.get_child(game.get_child_count() - 1)
	# Tile 8 is safe; a Ranger landing on tile 6 can attack tile 7 ahead.
	var hero: Piece = board.piecesManager.GreenPieces.Pieces[0]
	var enemy: Piece = board.piecesManager.RedPieces.Pieces[0]
	var path := board.way_points.green_path
	_place(hero, path[5])
	_place(enemy, path[7])
	board._on_dice_root_on_dice_rolled([1, 3])
	assert(hud.hero_portraits[0].action_overlay.visible, "Ranger must show attack from its landing tile immediately")
	board.SelectDie(1)
	assert(not hud.hero_portraits[0].action_overlay.visible, "Switching to a safe destination must clear the old attack icon immediately")
	board.SelectDie(0)
	assert(hud.hero_portraits[0].action_overlay.visible)
	# From tile 7, Ranger can reach tile 9 beyond a safe tile in between.
	_place(hero, path[6])
	_place(enemy, path[9])
	hud._refresh_recommendations()
	assert(hud.hero_portraits[0].action_overlay.visible, "Ranger must detect an enemy two tiles beyond landing")
	_place(enemy, path[8])
	hud._refresh_recommendations()
	assert(not hud.hero_portraits[0].action_overlay.visible, "A safe enemy cannot be attacked from range")
	# Warrior and hybrid Warrior can attack one tile behind their destination.
	_place(enemy, path[6])
	hero.HeroClass = "Warrior - mage"
	hud._refresh_recommendations()
	assert(hud.hero_portraits[0].action_overlay.visible)
	hero.ApplyStatus("Stun", 2)
	assert(not hud.hero_portraits[0].action_overlay.visible, "Status changes must clear an unavailable attack immediately")
	hero.RemoveStatus("Stun")
	assert(hud.hero_portraits[0].action_overlay.visible)
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
	assert(not hud.hero_portraits[0].action_overlay.visible, "Moving/animation state must hide all action overlays")
	print("PASS: safe landing, safe ranged target, Ranger +1/+2, hybrid Warrior -1, selected die and status transitions")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
