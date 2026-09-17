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
var roll_layer: CanvasLayer
var roll_stage: Control
var roll_sprites: Array[TextureRect] = []
var roll_tween: Tween

func _ready() -> void:
	_rng.randomize()
	_build_roll_presentation()
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
	GameAudio.play_dice_roll()
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
	_sync_roll_faces()
	# Leave the result readable before returning control to the board.
	await get_tree().create_timer(0.35, false).timeout
	var fade := create_tween()
	fade.tween_property(roll_stage, "modulate:a", 0.0, 0.18)
	await fade.finished
	roll_stage.hide()
	_is_rolling = false
	OnDiceRolled.emit(values)

func TryRollFromBoard(world_position: Vector2) -> bool:
	if get_tree().paused or _is_rolling or _board == null or not _board.IsHumanTurn():
		return false
	if GameManager.GameCurrentState != GameManager.GameStateEnum.PlayerCanRollDice:
		return false
	var artwork: Sprite2D = _board.get_node("Sprite2D_Board/Artwork")
	if not artwork.get_rect().has_point(artwork.to_local(world_position)):
		return false
	_board.ManualAction.emit()
	RollDice()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if _board != null and not _board.IsHumanTurn():
		return
	if not event.is_action_pressed("DiceClick"):
		return

	if event is InputEventMouseButton:
		var world_position: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		if TryRollFromBoard(world_position):
			get_viewport().set_input_as_handled()
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
		StatusLabel.text = "Bot %s\nsedang bermain..." % color_name
		return
	match state:
		GameManager.GameStateEnum.PlayerCanRollDice:
			StatusLabel.text = "Ketuk papan / hero untuk kocok"
			Maindice.modulate = Color.WHITE
			SecondDice.modulate = Color.WHITE
		GameManager.GameStateEnum.PlayerSelectPiece:
			StatusLabel.text = "Pilih dadu, lalu hero"
			if _board != null and _board.CanSummonWithPair():
				StatusLabel.text = "Total 6: summon / gerakkan hero"
		GameManager.GameStateEnum.GameOver:
			StatusLabel.text = "Permainan selesai"
		_:
			StatusLabel.text = "Tunggu..."

func AnimateDice() -> void:
	roll_stage.modulate.a = 1.0
	roll_stage.show()
	_sync_roll_faces()
	roll_tween = create_tween().set_parallel(true)
	for index in range(2):
		var face := roll_sprites[index]
		var direction := -1.0 if index == 0 else 1.0
		face.position = Vector2(827.5 + index * 140, 492.5)
		face.rotation = direction * 0.65
		face.scale = Vector2.ONE * 0.72
		roll_tween.tween_property(face, "position:y", 532.5, 0.48).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		roll_tween.tween_property(face, "rotation", 0.0, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		roll_tween.tween_property(face, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in range(6):
		await get_tree().create_timer(0.08, false).timeout
		SetSpriteByIndex(_rng.randi_range(0, max(DicesSpriteArray.size() - 1, 0)))
		SecondDice.texture = DicesSpriteArray[_rng.randi_range(0, DicesSpriteArray.size() - 1)]
		_sync_roll_faces()

	OnDiceAniamtionComplate_Local.emit()

func _build_roll_presentation() -> void:
	roll_layer = CanvasLayer.new()
	roll_layer.layer = 1
	add_child(roll_layer)
	roll_stage = Control.new()
	roll_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll_layer.add_child(roll_stage)
	for index in range(2):
		var face := TextureRect.new()
		face.size = Vector2(125, 125)
		face.pivot_offset = face.size * 0.5
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		roll_stage.add_child(face)
		roll_sprites.append(face)
	roll_stage.hide()
	get_viewport().size_changed.connect(_resize_roll)
	_resize_roll()

func _resize_roll() -> void:
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	roll_stage.scale = Vector2.ONE * fit
	roll_stage.position = (viewport_size - Vector2(1920, 1080) * fit) * 0.5

func _sync_roll_faces() -> void:
	roll_sprites[0].texture = Maindice.texture
	roll_sprites[1].texture = SecondDice.texture
