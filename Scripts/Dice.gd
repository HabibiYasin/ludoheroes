class_name Dice
extends Node2D

@export var SecondDice: Sprite2D
@export var StatusLabel: Label
@export var Maindice: Sprite2D
@export var DicesSpriteArray: Array[Texture2D]
@export var IsTestRun: bool = false
@export var IsAutoDiceRoll: bool = false

signal OnDiceRolled(values: Array[int])
signal OnDiceAniamtionComplate_Local
signal OnDiceRollBegin

var _rng := RandomNumberGenerator.new()
var _is_rolling := false
var _board: BoardManager

func _ready() -> void:
	_rng.randomize()
	_board = get_tree().get_first_node_in_group("BoardManager")
	if _board != null:
		_board.DiceSelectionChanged.connect(_on_selection_changed)
	GameManager.OnGameCurrentStateChange.connect(_update_status)
	_update_status(GameManager.GameCurrentState)

	if IsAutoDiceRoll:
		GameManager.OnGameCurrentStateChange.connect(_on_game_current_state_change)

func _on_game_current_state_change(updatedState: GameManager.GameStateEnum) -> void:
	if not IsAutoDiceRoll:
		return

	if updatedState == GameManager.GameStateEnum.PlayerCanRollDice:
		await get_tree().create_timer(0.8).timeout
		RollDice()

func SetSpriteByIndex(index: int) -> void:
	if Maindice == null:
		return
	if index < 0 or index >= DicesSpriteArray.size():
		return

	Maindice.texture = DicesSpriteArray[index]

func RollDice() -> void:
	if _is_rolling:
		return

	if GameManager.GameCurrentState != GameManager.GameStateEnum.PlayerCanRollDice:
		return

	_is_rolling = true
	Maindice.modulate = Color.WHITE
	SecondDice.modulate = Color.WHITE
	OnDiceRollBegin.emit()
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)

	await AnimateDice()

	var random_number: int = 6 if IsTestRun else _rng.randi_range(1, 6)
	SetSpriteByIndex(random_number - 1)

	var second_number: int = 6 if IsTestRun else _rng.randi_range(1, 6)
	SecondDice.texture = DicesSpriteArray[second_number - 1]
	var values: Array[int] = [random_number, second_number]
	_is_rolling = false
	OnDiceRolled.emit(values)

func _unhandled_input(event: InputEvent) -> void:
	if _board != null and not _board.IsHumanTurn():
		return
	if not event.is_action_pressed("DiceClick"):
		return

	var sprites: Array[Sprite2D] = [Maindice, SecondDice]
	for index in range(sprites.size()):
		var sprite := sprites[index]
		if sprite != null and sprite.is_pixel_opaque(sprite.get_local_mouse_position()):
			if GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice:
				if _board != null:
					_board.ManualAction.emit()
				RollDice()
			elif _board != null:
				if index < _board.remainingDice.size() and _board.remainingDice[index] > 0:
					_board.ManualAction.emit()
				_board.SelectDie(index)
			return

func _on_selection_changed(values: Array[int], selected_index: int) -> void:
	var sprites: Array[Sprite2D] = [Maindice, SecondDice]
	for index in range(sprites.size()):
		if values.is_empty() or values[index] == 0:
			sprites[index].modulate = Color(0.4, 0.4, 0.4, 0.6)
		elif index == selected_index:
			sprites[index].modulate = Color(1.0, 0.85, 0.4)
		else:
			sprites[index].modulate = Color.WHITE

func _update_status(state: GameManager.GameStateEnum) -> void:
	if StatusLabel == null:
		return
	if _board != null and not _board.IsHumanTurn() and state != GameManager.GameStateEnum.GameOver:
		var color_name: String = ["Hijau", "Kuning", "Biru", "Merah"][_board.currentPlayerColor]
		StatusLabel.text = "Bot %s sedang bermain..." % color_name
		return
	match state:
		GameManager.GameStateEnum.PlayerCanRollDice:
			StatusLabel.text = "Ketuk dadu untuk mengocok keduanya"
			Maindice.modulate = Color.WHITE
			SecondDice.modulate = Color.WHITE
		GameManager.GameStateEnum.PlayerSelectPiece:
			StatusLabel.text = "Pilih dadu, lalu pion (boleh pion yang sama)"
			if _board != null and _board.CanSummonWithPair():
				StatusLabel.text = "Total 6: summon di base (2 dadu), atau gerak biasa."
		GameManager.GameStateEnum.GameOver:
			StatusLabel.text = "Permainan selesai"
		_:
			StatusLabel.text = "Tunggu..."

func AnimateDice() -> void:
	for i in range(6):
		await get_tree().create_timer(0.08, false).timeout
		SetSpriteByIndex(_rng.randi_range(0, max(DicesSpriteArray.size() - 1, 0)))
		SecondDice.texture = DicesSpriteArray[_rng.randi_range(0, DicesSpriteArray.size() - 1)]

	OnDiceAniamtionComplate_Local.emit()
