class_name PiecesManager
extends Node2D

@export var BluePieces: PlayerPiecesGroup
@export var YellowPieces: PlayerPiecesGroup
@export var GreenPieces: PlayerPiecesGroup
@export var RedPieces: PlayerPiecesGroup

func IsGameOver() -> bool:
	return (
		BluePieces.HasThisPlayerCompleted()
		and YellowPieces.HasThisPlayerCompleted()
		and GreenPieces.HasThisPlayerCompleted()
		and RedPieces.HasThisPlayerCompleted()
	)

func GetWinner() -> PlayerPiecesGroup:
	for group: PlayerPiecesGroup in [GreenPieces, YellowPieces, BluePieces, RedPieces]:
		if group.HasThisPlayerCompleted():
			return group
	return null

func GetPieceGroupBasedOnType(playerColor: GameManager.PlayerColor) -> PlayerPiecesGroup:
	match playerColor:
		GameManager.PlayerColor.Green:
			return GreenPieces
		GameManager.PlayerColor.Yellow:
			return YellowPieces
		GameManager.PlayerColor.Blue:
			return BluePieces
		GameManager.PlayerColor.Red:
			return RedPieces
		_:
			return null

func HasThisPlayerUnlockedTurn(playerColor: GameManager.PlayerColor) -> bool:
	var group := GetPieceGroupBasedOnType(playerColor)
	return group != null and group.HasUnlockedAnyPiece()

func HasLegalMove(
	playerColor: GameManager.PlayerColor,
	dice_value: int,
	path_count: int
) -> bool:
	var group := GetPieceGroupBasedOnType(playerColor)
	return group != null and group.HasAnyLegalMove(dice_value, path_count)

func PlayAnimationByPlayerIndex(playerColor: GameManager.PlayerColor) -> void:
	var group := GetPieceGroupBasedOnType(playerColor)
	if group != null:
		group.PlayAllPieceAnimation()

func StopAnimation() -> void:
	GreenPieces.StopAllPieceAnimation()
	YellowPieces.StopAllPieceAnimation()
	BluePieces.StopAllPieceAnimation()
	RedPieces.StopAllPieceAnimation()
