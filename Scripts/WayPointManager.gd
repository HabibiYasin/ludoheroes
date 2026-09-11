class_name WayPointsManager
extends Node2D

@export var main_path: Node2D
@export var green_path: Array[WayPoint]
@export var yellow_path: Array[WayPoint]
@export var blue_path: Array[WayPoint]
@export var red_path: Array[WayPoint]

func GetPath(player_color: GameManager.PlayerColor) -> Array[WayPoint]:
	match player_color:
		GameManager.PlayerColor.Green:
			return green_path
		GameManager.PlayerColor.Yellow:
			return yellow_path
		GameManager.PlayerColor.Blue:
			return blue_path
		GameManager.PlayerColor.Red:
			return red_path
	return []

func GetWayPoint(index: int, player_color: GameManager.PlayerColor) -> WayPoint:
	var path := GetPath(player_color)
	if index < 0 or index >= path.size():
		return null
	return path[index]

func GetPositionOfThisPoint(index: int, playerColor: GameManager.PlayerColor) -> Vector2:
	var waypoint := GetWayPoint(index, playerColor)
	if waypoint == null:
		push_error("Invalid waypoint: color %d, index %d" % [playerColor, index])
		return Vector2.ZERO
	return waypoint.position

func GetCount(playerColor: GameManager.PlayerColor) -> int:
	return GetPath(playerColor).size()

func SetPieceToThisWayPoint(index: int, piece: Piece) -> void:
	if piece == null:
		return
	# The configured path includes both shared cells and the faction's home lane.
	# Resolve from that path, without assuming a fixed index for the home lane.
	var waypoint := GetWayPoint(index, piece.CurrentPlayerColor)
	if waypoint == null:
		push_error("Invalid waypoint: color %d, index %d" % [piece.CurrentPlayerColor, index])
		return
	piece.CurrentWayPoint = waypoint
	waypoint.SetPiece(piece)