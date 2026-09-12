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

	HealFriends(piece)
	var captured_piece := _find_capturable_opponent(piece)
	var direct := captured_piece != null and myHoldings.has(captured_piece)
	if captured_piece != null and piece.Attack > 0 and boardManager != null:
		boardManager.attack_presentation.queue_attack(piece, captured_piece, captured_piece.GetIncomingDamage(piece.Attack, direct))
	if captured_piece != null and captured_piece.TakeDamage(piece.Attack, direct):
		if captured_piece.CurrentWayPoint != null:
			captured_piece.CurrentWayPoint.RemoveMyRef(captured_piece)
		else:
			RemoveMyRef(captured_piece)
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

func HealFriends(incoming_piece: Piece) -> void:
	if not incoming_piece.HasClass("Support") or incoming_piece.Health <= 0:
		return
	for friend: Piece in myHoldings:
		if friend != incoming_piece and friend.CurrentPlayerColor == incoming_piece.CurrentPlayerColor:
			friend.Heal(1)

func _attack_cells(incoming_piece: Piece) -> Array[WayPoint]:
	var cells: Array[WayPoint] = [self]
	var manager := incoming_piece.wayPointManager
	if manager == null:
		return cells
	var offsets: Array[int] = []
	if incoming_piece.HasClass("Warrior"):
		offsets = [1, -1]
	elif incoming_piece.HasClass("Ranger"):
		offsets = [1, 2]
	var path := manager.GetPath(incoming_piece.CurrentPlayerColor)
	var index := path.find(self)
	if index < 0:
		return cells
	for offset in offsets:
		var cell := manager.GetWayPoint(index + offset, incoming_piece.CurrentPlayerColor)
		# Behind the starting square is still part of the shared track.
		if cell == null and index + offset < 0:
			for color in range(4):
				var other_path := manager.GetPath(color)
				var other_index := other_path.find(self)
				if other_index > 0:
					cell = other_path[other_index - 1]
					break
		if cell != null and not cells.has(cell):
			cells.append(cell)
	return cells

func _find_capturable_opponent(incoming_piece: Piece) -> Piece:
	if isThisSafePlace or IsThisHomePlace or incoming_piece.Health <= 0:
		return null
	var target: Piece = null
	var lowest := incoming_piece.HasClass("Assassin")
	for cell in _attack_cells(incoming_piece):
		if cell.isThisSafePlace or cell.IsThisHomePlace:
			continue
		for item: Piece in cell.myHoldings:
			if item == incoming_piece or item.CurrentPlayerColor == incoming_piece.CurrentPlayerColor or item.Health <= 0 or item.IsInHome:
				continue
			if target == null or (item.Health < target.Health if lowest else item.Health > target.Health):
				target = item
	return target

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
