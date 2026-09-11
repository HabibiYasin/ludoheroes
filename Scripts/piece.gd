class_name Piece
extends Node2D

# -1 means the piece is still in the lobby/base.
var CurrentPosition: int = -1
var CurrentState: GameManager.PieceStateEnum = GameManager.PieceStateEnum.InLobby
var StartingPosition: int = 0
var wayPointManager: WayPointsManager
var CurrentWayPoint: WayPoint
var IsInHome: bool = false
var LobbyPosition: Vector2
var _normal_scale := Vector2.ONE
var _normal_sprite_position := Vector2.ZERO

@export var CurrentPlayerColor: GameManager.PlayerColor
@export var PieceSprite: Sprite2D
@export var animation_PieceSelect: AnimationPlayer
@export var PieceTexture: Texture2D

func _ready() -> void:
	LobbyPosition = position
	if PieceTexture != null and PieceSprite != null:
		# Fit replacement artwork into the original piece's footprint.
		# Scale the root so the sprite's selection animation stays relative.
		if PieceSprite.texture != null:
			var original_size := PieceSprite.texture.get_size()
			var replacement_size := PieceTexture.get_size()
			if replacement_size.x > 0.0 and replacement_size.y > 0.0:
				var fit_scale := minf(original_size.x / replacement_size.x, original_size.y / replacement_size.y)
				scale *= fit_scale
		PieceSprite.texture = PieceTexture
	_normal_scale = scale
	if PieceSprite != null:
		_normal_sprite_position = PieceSprite.position
	wayPointManager = get_tree().get_first_node_in_group("WayPointManagerGroup")

# Offset only the artwork: logical movement stays at the waypoint center.
# Root scaling remains independent of the sprite's selection animation.
func SetSharedCellLayout(offset: Vector2, slot_size: Vector2 = Vector2.ZERO) -> void:
	if PieceSprite == null or PieceSprite.texture == null:
		return
	var fit := 1.0
	if slot_size != Vector2.ZERO:
		var normal_size := PieceSprite.texture.get_size() * _normal_scale.abs()
		fit = minf(1.0, minf(slot_size.x / normal_size.x, slot_size.y / normal_size.y))
	scale = _normal_scale * fit
	PieceSprite.position = _normal_sprite_position + offset / scale

func SetStartPosition(index: int) -> void:
	StartingPosition = index
	CurrentPosition = -1
	CurrentState = GameManager.PieceStateEnum.InLobby
	IsInHome = false
	CurrentWayPoint = null

func SetCurrentPositionAndCheckKill(index: int) -> void:
	if IsInHome:
		return

	CurrentPosition = index
	CurrentState = GameManager.PieceStateEnum.InWayPoint

	if wayPointManager != null:
		wayPointManager.SetPieceToThisWayPoint(index, self)

func SendBackToLobby() -> void:
	if CurrentWayPoint != null:
		CurrentWayPoint.RemoveMyRef(self)

	CurrentWayPoint = null
	CurrentPosition = -1
	CurrentState = GameManager.PieceStateEnum.InLobby
	IsInHome = false
	position = LobbyPosition
	SetSharedCellLayout(Vector2.ZERO)

func GetCurrentPosition() -> int:
	return CurrentPosition

func IsInLobby() -> bool:
	return CurrentState == GameManager.PieceStateEnum.InLobby

func HasThisPlayerUnlockedPiece() -> bool:
	return CurrentState != GameManager.PieceStateEnum.InLobby

func CanMoveWithDice(dice_value: int, path_count: int) -> bool:
	if IsInHome:
		return false

	# Standard Ludo rule: a piece can leave the base only with a 6.
	if IsInLobby():
		return dice_value == 6

	var target_position := CurrentPosition + dice_value
	return target_position < path_count

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("PlayerClick"):
		return

	if PieceSprite == null:
		return

	var local_mouse_position := PieceSprite.get_local_mouse_position()
	if PieceSprite.is_pixel_opaque(local_mouse_position):
		GameManager.HeroInspected.emit(self)
		var board: BoardManager = get_tree().get_first_node_in_group("BoardManager")
		if board != null and board.IsHumanTurn() and GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerSelectPiece:
			AIInput()
		get_viewport().set_input_as_handled()

func AIInput() -> void:
	if IsInHome:
		return

	# Do not remove the waypoint reference here.
	# BoardManager validates the move first, then removes it when movement starts.
	GameManager.OnPlayerSelectPiece.emit(self)

func PlayAnimation() -> void:
	if CurrentState != GameManager.PieceStateEnum.InHouse and not IsInHome:
		if animation_PieceSelect != null:
			animation_PieceSelect.play("PieceAnimation_Select")

func StopAnimation() -> void:
	if animation_PieceSelect != null:
		animation_PieceSelect.stop()
