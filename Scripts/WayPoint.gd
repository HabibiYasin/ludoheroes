class_name WayPoint
extends Node2D

@export var isThisSafePlace: bool
@export var IsThisHomePlace: bool

var myHoldings: Array[Piece] = []
var boardManager: BoardManager

func _ready() -> void:
	boardManager = get_tree().get_first_node_in_group("BoardManager")

func SetPiece(piece: Piece) -> void:
	if piece == null:
		return

	if myHoldings.has(piece):
		return
	# Defensive cleanup: the same piece must never exist twice in this waypoint.
	myHoldings.erase(piece)
	myHoldings.append(piece)

	if boardManager != null:
		boardManager.DetectKill(null)

	var captured_piece := _find_capturable_opponent(piece)
	if captured_piece != null and captured_piece.TakeDamage(piece.Attack):
		myHoldings.erase(captured_piece)
		captured_piece.SetSharedCellLayout(Vector2.ZERO)
		if boardManager != null:
			boardManager.DetectKill(captured_piece)
		else:
			captured_piece.SendBackToLobby()

	if IsThisHomePlace:
		piece.IsInHome = true
	_update_shared_layout()

func _update_shared_layout() -> void:
	var count := myHoldings.size()
	if count == 1:
		myHoldings[0].SetSharedCellLayout(Vector2.ZERO)
		return
	if count == 0:
		return
	# Keep enlarged heroes closer together while retaining a small gap.
	# Artwork may extend beyond the cell; logical positions stay at its center.
	var columns := ceili(sqrt(float(count)))
	var rows := ceili(float(count) / columns)
	var slot := Vector2(112.0 / columns, 112.0 / rows)
	for index in range(count):
		var row := index / columns
		var column := index % columns
		var row_count := mini(columns, count - row * columns)
		var offset := Vector2((column - (row_count - 1) * 0.5) * slot.x, (row - (rows - 1) * 0.5) * slot.y)
		myHoldings[index].SetSharedCellLayout(offset * 1.5, slot - Vector2(4, 4))

func _find_capturable_opponent(incoming_piece: Piece) -> Piece:
	if isThisSafePlace:
		return null

	for item: Piece in myHoldings:
		if item == incoming_piece:
			continue

		if item.CurrentPlayerColor != incoming_piece.CurrentPlayerColor:
			return item

	return null

func ClearMe() -> void:
	for piece in myHoldings:
		piece.SetSharedCellLayout(Vector2.ZERO)
	myHoldings.clear()

func HasWeHaveOpponentPiece() -> bool:
	if isThisSafePlace or myHoldings.size() < 2:
		return false

	var reference_color: GameManager.PlayerColor = myHoldings.back().CurrentPlayerColor
	for item: Piece in myHoldings:
		if item.CurrentPlayerColor != reference_color:
			return true

	return false

func RemoveMyRef(piece: Piece) -> void:
	myHoldings.erase(piece)
	piece.SetSharedCellLayout(Vector2.ZERO)
	_update_shared_layout()
