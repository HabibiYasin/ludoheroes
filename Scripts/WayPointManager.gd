class_name WayPointsManager
extends Node2D

@export var main_path: Node2D
@export var green_path: Array[WayPoint]
@export var yellow_path: Array[WayPoint]
@export var blue_path: Array[WayPoint]
@export var red_path: Array[WayPoint]

func GetTerritoryFaction(cell: WayPoint) -> String:
	# Each arm is split between its adjacent factions: the home lane and one
	# outer lane belong to its owner; the other outer lane belongs to its neighbor.
	# Board-local coordinates keep these territories attached when the board rotates.
	var point := to_local(cell.global_position)
	var half_lane := 1804.0 / 15.0 / 2.0
	if absf(point.x) > absf(point.y):
		if point.x > 0.0:
			return "Nerathis" if point.y < -half_lane else "Astherion"
		return "Thornvale" if point.y > half_lane else "Nekravia"
	if point.y > 0.0:
		return "Astherion" if point.x > half_lane else "Thornvale"
	return "Nekravia" if point.x < -half_lane else "Nerathis"

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

func IsItemTile(cell: WayPoint) -> bool:
	if cell == null or not cell.isThisSafePlace or cell.IsThisHomePlace or cell.get_parent() != main_path:
		return false
	return true

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
