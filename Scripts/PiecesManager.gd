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

# Score ties use goals, then the fixed player-color order. MVP ties keep roster order.
func GetMatchResults() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for color in range(4):
		var group := GetPieceGroupBasedOnType(color)
		var score := 0
		var goals := 0
		var mvp: Piece = null
		for hero: Piece in group.Pieces:
			score += hero.MatchScore
			goals += 1 if hero.IsInHome else 0
			if mvp == null or hero.MatchScore > mvp.MatchScore:
				mvp = hero
		results.append({"color": color, "score": score, "goals": goals, "mvp": mvp})
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.score != b.score:
			return a.score > b.score
		if a.goals != b.goals:
			return a.goals > b.goals
		return a.color < b.color
	)
	for index in range(results.size()):
		results[index]["rank"] = index + 1
		results[index]["mmr"] = [100, 50, 25, -50][index]
	return results

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
