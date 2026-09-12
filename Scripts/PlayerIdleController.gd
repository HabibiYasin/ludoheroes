extends Node

@export var Enabled := true
@export var IdleSeconds := 10.0
@export var AutoActionDelay := 0.65
@export var AutoRollDelay := 2.0
var AutoPlaying := false
var ConsecutiveIdleTurns := 0
var SecondsRemaining := 10.0
var WaitingForPlayer := false
var _elapsed := 0.0
var _used_auto := false
var _last_state: int = -1
var _board: BoardManager
var _dice: Dice
var _bot: Node

func _ready() -> void:
	_board = get_parent().get_node("Board/board_GamePlay")
	_dice = get_parent().get_node("Dice/DiceRoot")
	_bot = get_parent().get_node("BotController")
	_board.ManualAction.connect(_manual_action)
	_board.TurnFinished.connect(_turn_finished)
	GameManager.HeroInspected.connect(func(_piece: Piece): _manual_action())

func _process(delta: float) -> void:
	var state := GameManager.GameCurrentState
	WaitingForPlayer = Enabled and _board.currentPlayerColor == _board.HumanPlayerColor and state in [GameManager.GameStateEnum.PlayerCanRollDice, GameManager.GameStateEnum.PlayerSelectPiece]
	if not WaitingForPlayer or state != _last_state:
		_elapsed = 0.0
	_last_state = state
	if WaitingForPlayer:
		_elapsed += delta
	var action_delay := IdleSeconds
	if AutoPlaying:
		action_delay = AutoRollDelay if state == GameManager.GameStateEnum.PlayerCanRollDice else AutoActionDelay
	SecondsRemaining = maxf(0.0, action_delay - _elapsed)
	if WaitingForPlayer and _elapsed >= action_delay:
		AutoPlaying = true
		_elapsed = 0.0
		_used_auto = true
		if state == GameManager.GameStateEnum.PlayerCanRollDice:
			_dice.RollDice()
		else:
			_bot._play_move()

func _manual_action() -> void:
	AutoPlaying = false
	_elapsed = 0.0
	SecondsRemaining = IdleSeconds
	_used_auto = false
	ConsecutiveIdleTurns = 0

func _turn_finished(color: GameManager.PlayerColor) -> void:
	if color != _board.HumanPlayerColor:
		return
	if _used_auto:
		ConsecutiveIdleTurns += 1
	else:
		ConsecutiveIdleTurns = 0
	_used_auto = false
	_elapsed = 0.0

func WarningText() -> String:
	if ConsecutiveIdleTurns < 4:
		return ""
	return "Kamu idle %d giliran berturut-turut. Kemungkinan kamu akan kena penalti jika idle lebih dari 12 giliran. Ayo main lagi!" % ConsecutiveIdleTurns