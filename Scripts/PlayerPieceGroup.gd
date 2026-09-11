class_name PlayerPiecesGroup
extends Node2D

@export var Pieces: Array[Piece]
@export var PlayerFirstPosition: int
@export var CurrentPlayerColor: GameManager.PlayerColor
@export var IsAutoPieceSelect: bool = false

var boardManager: BoardManager
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	boardManager = get_tree().get_first_node_in_group("BoardManager")

	for piece in Pieces:
		piece.SetStartPosition(PlayerFirstPosition)
		piece.CurrentState = GameManager.PieceStateEnum.InLobby

	if IsAutoPieceSelect:
		GameManager.OnGameCurrentStateChange.connect(_on_game_current_state_change)

func _on_game_current_state_change(updatedState: GameManager.GameStateEnum) -> void:
	if not IsAutoPieceSelect:
		return

	if boardManager == null or boardManager.currentPlayerColor != CurrentPlayerColor:
		return

	if updatedState == GameManager.GameStateEnum.PlayerSelectPiece:
		await get_tree().create_timer(0.6).timeout
		var my_piece := GetPieceForAI()
		if my_piece != null:
			my_piece.AIInput()

func GetPieceForAI() -> Piece:
	if boardManager == null:
		return null

	var valid_pieces := GetMovablePieces(
		boardManager.currentDiceValue,
		boardManager.GetPathCount(CurrentPlayerColor)
	)

	if valid_pieces.is_empty():
		return null

	return valid_pieces[_rng.randi_range(0, valid_pieces.size() - 1)]

func GetMovablePieces(dice_value: int, path_count: int) -> Array[Piece]:
	var result: Array[Piece] = []

	for piece in Pieces:
		var pair_summon := boardManager != null and boardManager.currentPlayerColor == CurrentPlayerColor and boardManager.CanSummonWithPair() and piece.IsInLobby() and not piece.IsInHome
		if piece.CanMoveWithDice(dice_value, path_count) or pair_summon:
			result.append(piece)

	return result

func HasAnyLegalMove(dice_value: int, path_count: int) -> bool:
	return not GetMovablePieces(dice_value, path_count).is_empty()

func GetPieceByIndex(index: int) -> Piece:
	if index < 0 or index >= Pieces.size():
		return null

	return Pieces[index]

func HasThisPlayerCompleted() -> bool:
	for item: Piece in Pieces:
		if not item.IsInHome:
			return false

	return true

func HasUnlockedAnyPiece() -> bool:
	for piece in Pieces:
		if piece.CurrentState != GameManager.PieceStateEnum.InLobby:
			return true

	return false

func PlayAllPieceAnimation() -> void:
	if boardManager == null:
		return

	var valid_pieces := GetMovablePieces(
		boardManager.currentDiceValue,
		boardManager.GetPathCount(CurrentPlayerColor)
	)

	for piece in Pieces:
		piece.StopAnimation()

	for piece in valid_pieces:
		piece.PlayAnimation()

func StopAllPieceAnimation() -> void:
	for piece in Pieces:
		piece.StopAnimation()
