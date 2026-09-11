extends Node

func _ready() -> void:
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var cell := WayPoint.new()
	cell.isThisSafePlace = true
	add_child(cell)
	var pieces: Array[Piece] = []
	for group: PlayerPiecesGroup in [board.piecesManager.GreenPieces, board.piecesManager.YellowPieces, board.piecesManager.BluePieces, board.piecesManager.RedPieces]:
		pieces.append_array(group.Pieces)
	var normal_scale := pieces[0].scale
	for count in [2, 3, 4, 16]:
		cell.ClearMe()
		for i in range(count):
			cell.SetPiece(pieces[i])
		var rectangles: Array[Rect2] = []
		for piece in cell.myHoldings:
			var size := piece.PieceSprite.texture.get_size() * piece.scale
			var center := piece.PieceSprite.position * piece.scale
			var rect := Rect2(center - size * 0.5, size)
			assert(Rect2(-56, -56, 112, 112).encloses(rect))
			for other in rectangles:
				assert(not rect.intersects(other))
			rectangles.append(rect)
		print("PASS: ", count, " heroes fit without overlap")
	for i in range(1, pieces.size()):
		cell.RemoveMyRef(pieces[i])
	assert(pieces[0].scale.is_equal_approx(normal_scale))
	assert(pieces[0].PieceSprite.position.is_zero_approx())
	cell.SetPiece(pieces[1])
	pieces[1].CurrentWayPoint = cell
	pieces[1].SendBackToLobby()
	assert(cell.myHoldings.size() == 1)
	assert(pieces[0].scale.is_equal_approx(normal_scale))
	assert(pieces[1].PieceSprite.position.is_zero_approx())
	assert(pieces[1].position == pieces[1].LobbyPosition)
	cell.ClearMe()
	print("PASS: remaining hero and returning hero restore normal size and alignment")
	get_tree().quit()
