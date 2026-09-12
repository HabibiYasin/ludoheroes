extends Node

@export var ThinkDelay: float = 0.65

var _board: BoardManager
var _dice: Dice
var _elapsed := 0.0
var _last_state: int = -1
var _last_player: int = -1
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_board = get_parent().get_node("Board/board_GamePlay")
	_dice = get_parent().get_node("Dice/DiceRoot")
	_rng.randomize()

# A single scheduler drives both dice and moves, using the board's rules.
# Processing and think time stop with the game's pause menu.
func _process(delta: float) -> void:
	var state := GameManager.GameCurrentState
	if state != _last_state or _board.currentPlayerTurnIndex != _last_player:
		_elapsed = 0.0
		_last_state = state
		_last_player = _board.currentPlayerTurnIndex
	if _board.IsHumanTurn() or state not in [GameManager.GameStateEnum.PlayerCanRollDice, GameManager.GameStateEnum.PlayerSelectPiece]:
		_elapsed = 0.0
		return
	_elapsed += delta
	if _elapsed < ThinkDelay:
		return
	_elapsed = 0.0
	if state == GameManager.GameStateEnum.PlayerCanRollDice:
		_dice.RollDice()
	else:
		_play_move()

func _play_move() -> void:
	var move := ChooseMove()
	if move.is_empty():
		_board.FinishTurn()
		return
	_board.SelectDie(move.die_index)
	_board._on_player_select_piece(move.piece)

# Keep decision making separate so future combat/skill rules can replace it.
func ChooseMove() -> Dictionary:
	var group := _board.piecesManager.GetPieceGroupBasedOnType(_board.currentPlayerColor)
	var path_count := _board.GetPathCount(_board.currentPlayerColor)
	var best: Dictionary = {}
	var best_score := -1.0
	for index in range(_board.remainingDice.size()):
		var value := _board.remainingDice[index]
		if value <= 0:
			continue
		for piece in group.GetMovablePieces(value, path_count):
			var score := _rng.randf()
			if not piece.IsInLobby() and piece.CurrentPosition + piece.GetMoveDistance(value) == path_count - 1:
				score += 100.0
			elif piece.IsInLobby():
				score += 10.0
			else:
				score += float(piece.CurrentPosition + piece.GetMoveDistance(value)) / float(path_count)
			if score > best_score:
				best_score = score
				best = {"die_index": index, "piece": piece}
	return best
