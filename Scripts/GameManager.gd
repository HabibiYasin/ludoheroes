extends Node

enum GameStateEnum {
	Null,
	PlayerCanRollDice,
	PlayerSelectPiece,
	GameOver
}

enum PieceStateEnum {
	InLobby,
	InWayPoint,
	InHouse
}

enum PlayerColor {
	Green,
	Yellow,
	Blue,
	Red
}

var GameCurrentState: GameStateEnum = GameStateEnum.PlayerCanRollDice
var LocalPlayerColor: PlayerColor = PlayerColor.Green

signal OnGameCurrentStateChange(updatedGameState: GameStateEnum)
signal OnPlayerSelectPiece(value: Piece)
signal HeroInspected(value: Piece)

func UpdateGameCurrentState(updateGameCurrentState: GameStateEnum) -> void:
	if GameCurrentState == updateGameCurrentState:
		return

	GameCurrentState = updateGameCurrentState
	OnGameCurrentStateChange.emit(GameCurrentState)
