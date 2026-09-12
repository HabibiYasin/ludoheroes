extends Node2D

# Visual-only sprites: no Piece script, waypoint holdings or input handlers.
const OPACITY := 0.35
var board: BoardManager
var previews: Dictionary = {}

func _ready() -> void:
	board = get_parent()
	z_index = 8
	GameManager.OnGameCurrentStateChange.connect(_state_changed)
	board.DiceSelectionChanged.connect(_dice_changed)
	for color in range(4):
		var group := board.piecesManager.GetPieceGroupBasedOnType(color)
		if group != null:
			for hero: Piece in group.Pieces:
				hero.StatsChanged.connect(refresh)

func _state_changed(_state: int) -> void:
	refresh()

func _dice_changed(_values: Array[int], _selected: int) -> void:
	refresh()

func clear() -> void:
	for entry: Dictionary in previews.values():
		entry.sprite.free()
	previews.clear()

func refresh() -> void:
	clear()
	if GameManager.GameCurrentState != GameManager.GameStateEnum.PlayerSelectPiece or not board.IsHumanTurn() or board.currentDiceValue <= 0:
		return
	var group := board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor)
	if group == null:
		return
	var destinations: Dictionary = {}
	for hero: Piece in group.Pieces:
		if hero.IsInLobby() or hero.IsInHome or hero.Health <= 0 or hero.PieceSprite == null or hero.PieceSprite.texture == null:
			continue
		if not hero.CanMoveWithDice(board.currentDiceValue, board.GetPathCount(hero.CurrentPlayerColor)):
			continue
		var target := hero.CurrentPosition + hero.GetMoveDistance(board.currentDiceValue)
		var cell := board.way_points.GetWayPoint(target, hero.CurrentPlayerColor)
		if cell == null:
			continue
		var ghost := Sprite2D.new()
		ghost.texture = hero.PieceSprite.texture
		ghost.flip_h = hero.PieceSprite.flip_h
		ghost.flip_v = hero.PieceSprite.flip_v
		ghost.modulate.a = OPACITY
		add_child(ghost)
		previews[hero] = {"sprite": ghost, "cell": cell, "target": target, "offset": Vector2.ZERO, "fit": 1.0}
		if not destinations.has(cell):
			destinations[cell] = []
		destinations[cell].append(hero)
	# Keep all four silhouettes readable if their destinations coincide.
	for heroes: Array in destinations.values():
		if heroes.size() <= 1:
			continue
		var columns := ceili(sqrt(float(heroes.size())))
		var rows := ceili(float(heroes.size()) / columns)
		for index in range(heroes.size()):
			var entry: Dictionary = previews[heroes[index]]
			entry.offset = Vector2((index % columns - (columns - 1) * 0.5) * 58.0, (index / columns - (rows - 1) * 0.5) * 58.0)
			entry.fit = 0.6
	_update_transforms()

func _process(_delta: float) -> void:
	_update_transforms()

func _update_transforms() -> void:
	for hero: Piece in previews:
		var entry: Dictionary = previews[hero]
		var ghost: Sprite2D = entry.sprite
		var cell: WayPoint = entry.cell
		ghost.global_position = cell.global_position + Vector2(entry.offset) * global_scale.abs()
		ghost.global_rotation = 0.0
		# Use the normal artwork scale, independent of selection pulse or shared-cell layout.
		ghost.global_scale = hero.GetBoardDisplayScale() * hero.get_parent().global_scale.abs() * float(entry.fit)
