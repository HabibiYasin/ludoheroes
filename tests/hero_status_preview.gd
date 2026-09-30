extends Node

# Run this scene to inspect status assets and the additional skill effects.
func _ready() -> void:
	GameManager.LocalPlayerColor = GameManager.PlayerColor.Blue
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	game.get_node("CoreGamplay/BotController").set_process(false)
	game.get_node("CoreGamplay/PlayerIdleController").set_process(false)
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var ids := preload("res://Scripts/HeroStatus.gd").DEFINITIONS.keys()
	var slots := [2, 6, 10, 15, 19, 23, 28, 32, 36, 41, 45, 49]
	for index in range(ids.size()):
		var group := board.piecesManager.GetPieceGroupBasedOnType(index / 4)
		var hero: Piece = group.Pieces[index % 4]
		var cell: WayPoint = board.way_points.main_path.get_node(str(slots[index]))
		hero.CurrentPosition = board.way_points.GetPath(hero.CurrentPlayerColor).find(cell)
		hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
		hero.CurrentWayPoint = cell
		cell.myHoldings.append(hero)
		hero.position = cell.position
		hero.ApplyStatus(ids[index], 3)
	var selected: Piece = board.piecesManager.GreenPieces.Pieces[0]
	selected.ApplyStatus("Shield", 2)
	selected.ApplyStatus("Thorned", 4)
	GameManager.HeroInspected.emit(selected)
	if "--capture-status-preview" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/hero_status_preview.png")
		get_tree().quit()
