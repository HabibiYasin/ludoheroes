class_name BoardManager
extends Node2D

@export var way_points: WayPointsManager
@export var piecesManager: PiecesManager
@export var animation_PlayerForPlaces: AnimationPlayer
@export var BotsEnabled: bool = true
@export var HumanPlayerColor: GameManager.PlayerColor = GameManager.PlayerColor.Green

var currentPlayerTurnIndex: int = -1
var currentDiceValue: int = -1
var currentAnimationPlaceName: String = ""
var hasKill: bool = false
var currentPlayerColor: GameManager.PlayerColor

var remainingDice: Array[int] = []
var selectedDiceIndex: int = -1
var attack_presentation: CanvasLayer
var item_choice: CanvasLayer
var move_preview: Node2D
signal ItemHeroInspected(hero: Piece)
var currentRound: int = 1
var _round_finished_players: Array[int] = []

signal RoundChanged(value: int)

signal DiceSelectionChanged(values: Array[int], selected_index: int)
signal OnHasKill
signal ManualAction
signal TurnFinished(color: GameManager.PlayerColor)

func _ready() -> void:
	attack_presentation = preload("res://Scripts/AttackPresentation.gd").new()
	add_child(attack_presentation)
	item_choice = preload("res://Scripts/ItemChoice.gd").new()
	add_child(item_choice)
	HumanPlayerColor = GameManager.LocalPlayerColor
	currentPlayerTurnIndex = int(HumanPlayerColor) - 1
	GameManager.OnPlayerSelectPiece.connect(_on_player_select_piece)
	UpdatePlayerTurn()
	move_preview = preload("res://Scripts/MovePreview.gd").new()
	add_child(move_preview)

func GetPathCount(player_color: GameManager.PlayerColor) -> int:
	if way_points == null:
		return 0
	return way_points.GetCount(player_color)

func _on_player_select_piece(value: Piece, manual: bool = false) -> void:
	if GameManager.GameCurrentState != GameManager.GameStateEnum.PlayerSelectPiece:
		return

	if value == null:
		return

	if not IsThisPlayerTurn(value.CurrentPlayerColor):
		return

	var path_count := GetPathCount(value.CurrentPlayerColor)
	var use_pair := value.IsInLobby() and not value.IsInHome and CanSummonWithPair()
	if not use_pair and not value.CanMoveWithDice(currentDiceValue, path_count):
		push_warning("Illegal Ludo move ignored.")
		return

	StopPieceAnimation()
	if manual:
		ManualAction.emit()
	await MovePieces(currentDiceValue, value, use_pair)

func CanSummonWithPair() -> bool:
	return remainingDice.size() == 2 and remainingDice[0] > 0 and remainingDice[1] > 0 and remainingDice[0] + remainingDice[1] == 6

func IsThisPlayerTurn(playerType: GameManager.PlayerColor) -> bool:
	return playerType == currentPlayerColor

func IsHumanTurn() -> bool:
	return not BotsEnabled or currentPlayerColor == HumanPlayerColor

func _on_dice_root_on_dice_roll_begin() -> void:
	if animation_PlayerForPlaces != null:
		animation_PlayerForPlaces.stop()

func _on_dice_root_on_dice_rolled(values: Array[int]) -> void:
	remainingDice.assign(values)
	_prepare_next_die()

func SelectDie(index: int) -> void:
	if GameManager.GameCurrentState != GameManager.GameStateEnum.PlayerSelectPiece:
		return
	if index < 0 or index >= remainingDice.size() or remainingDice[index] <= 0:
		return
	selectedDiceIndex = index
	currentDiceValue = remainingDice[index]
	DiceSelectionChanged.emit(remainingDice, selectedDiceIndex)
	PlayPieceAnimation()

func _prepare_next_die() -> void:
	var path_count := GetPathCount(currentPlayerColor)
	for index in range(remainingDice.size()):
		if remainingDice[index] > 0 and piecesManager.HasLegalMove(currentPlayerColor, remainingDice[index], path_count):
			selectedDiceIndex = index
			currentDiceValue = remainingDice[index]
			DiceSelectionChanged.emit(remainingDice, selectedDiceIndex)
			GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerSelectPiece)
			PlayPieceAnimation()
			return
	FinishTurn()

func _complete_die() -> void:
	remainingDice[selectedDiceIndex] = 0
	_prepare_next_die()

func MovePieces(dice_value: int, moveThisPiece: Piece, use_pair: bool = false) -> void:
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
	hasKill = false

	var path_count := GetPathCount(moveThisPiece.CurrentPlayerColor)
	if path_count <= 0:
		FinishTurn()
		return

	# Summon with a single 6 or both unused dice totaling 6.
	# It enters the first square; it does not jump six squares.
	if moveThisPiece.IsInLobby():
		moveThisPiece.position = way_points.GetPositionOfThisPoint(
			0,
			moveThisPiece.CurrentPlayerColor
		)
		moveThisPiece.SetCurrentPositionAndCheckKill(0)
		await _wait_for_kill_if_needed()
		if use_pair:
			remainingDice.fill(0)
		_complete_die()
		return

	var target_position := moveThisPiece.CurrentPosition + moveThisPiece.GetMoveDistance(dice_value)

	# Exact roll is required to reach the last/home waypoint.
	if target_position >= path_count:
		GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerSelectPiece)
		PlayPieceAnimation()
		return

	if moveThisPiece.CurrentWayPoint != null:
		moveThisPiece.CurrentWayPoint.RemoveMyRef(moveThisPiece)
		moveThisPiece.CurrentWayPoint = null

	for step in range(moveThisPiece.CurrentPosition + 1, target_position + 1):
		moveThisPiece.position = way_points.GetPositionOfThisPoint(
			step,
			moveThisPiece.CurrentPlayerColor
		)
		# The destination heals through SetPiece; intermediate tiles heal here.
		if step < target_position:
			way_points.GetWayPoint(step, moveThisPiece.CurrentPlayerColor).HealFriends(moveThisPiece)
		await get_tree().create_timer(0.12, false).timeout

	moveThisPiece.SetCurrentPositionAndCheckKill(target_position)
	await _wait_for_kill_if_needed()
	await AwardLandingItem(moveThisPiece)

	# WayPoint marks IsInHome when the final/home waypoint is reached.
	if moveThisPiece.IsInHome:
		moveThisPiece.CurrentState = GameManager.PieceStateEnum.InHouse
		await moveThisPiece.CelebrateFinish()
	else:
		moveThisPiece.CurrentState = GameManager.PieceStateEnum.InWayPoint

	var winner := piecesManager.GetWinner()
	if winner != null:
		TurnFinished.emit(currentPlayerColor)
		GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.GameOver)
		StopPieceAnimation()
		if animation_PlayerForPlaces != null:
			animation_PlayerForPlaces.stop()
		print("GAME OVER - winner: ", winner.name)
		return

	# Each player gets exactly one pair of dice per turn.
	_complete_die()

func _wait_for_kill_if_needed() -> void:
	if hasKill:
		await OnHasKill
	await attack_presentation.play_pending()

func AwardLandingItem(hero: Piece) -> void:
	if hero.Health <= 0 or hero.IsInHome or not way_points.IsItemTile(hero.CurrentWayPoint):
		return
	if hero.Items.size() >= 2:
		hero.StackRandomItem()
		return
	var choices := preload("res://Scripts/ItemCatalog.gd").choices()
	if not IsHumanTurn():
		hero.EquipItem(choices.pick_random())
		return
	ItemHeroInspected.emit(hero)
	var selected: int = await item_choice.choose(hero, choices)
	hero.EquipItem(selected)

func FinishTurn() -> void:
	TurnFinished.emit(currentPlayerColor)
	_record_round_turn()
	remainingDice.clear()
	selectedDiceIndex = -1
	DiceSelectionChanged.emit(remainingDice, selectedDiceIndex)
	currentDiceValue = -1
	StopPieceAnimation()

	UpdatePlayerTurn()

	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)

func _record_round_turn() -> void:
	if not _round_finished_players.has(int(currentPlayerColor)):
		_round_finished_players.append(int(currentPlayerColor))
	for index in range(4):
		var color := _color_from_turn_index(index)
		var group := piecesManager.GetPieceGroupBasedOnType(color)
		if group != null and not group.HasThisPlayerCompleted() and not _round_finished_players.has(int(color)):
			return
	_round_finished_players.clear()
	currentRound += 1
	RoundChanged.emit(currentRound)

func MovePiecesToHome(_value: int, moveThisPiece: Piece) -> void:
	if moveThisPiece == null:
		OnHasKill.emit()
		return

	# Send the captured piece directly back to its original lobby slot.
	# This avoids the old reverse-path desync.
	await get_tree().create_timer(0.2, false).timeout
	moveThisPiece.SendBackToLobby()
	OnHasKill.emit()

func UpdatePlayerTurn() -> void:
	var attempts := 0

	while attempts < 4:
		currentPlayerTurnIndex = (currentPlayerTurnIndex + 1) % 4
		currentPlayerColor = _color_from_turn_index(currentPlayerTurnIndex)

		var piece_group := piecesManager.GetPieceGroupBasedOnType(currentPlayerColor)
		if piece_group != null and not piece_group.HasThisPlayerCompleted():
			PlayPlaceAnimation()
			return

		attempts += 1

	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.GameOver)

func _color_from_turn_index(index: int) -> GameManager.PlayerColor:
	match index:
		0:
			return GameManager.PlayerColor.Green
		1:
			return GameManager.PlayerColor.Yellow
		2:
			return GameManager.PlayerColor.Blue
		3:
			return GameManager.PlayerColor.Red
		_:
			return GameManager.PlayerColor.Green

func PlayPlaceAnimation() -> void:
	match currentPlayerTurnIndex:
		0:
			currentAnimationPlaceName = "GreenPlaceAnimation"
		1:
			currentAnimationPlaceName = "YellowPlaceAnimation"
		2:
			currentAnimationPlaceName = "BluePlaceAnimation"
		3:
			currentAnimationPlaceName = "RedPlaceAnimation"

	if animation_PlayerForPlaces != null:
		animation_PlayerForPlaces.stop()
		animation_PlayerForPlaces.play(currentAnimationPlaceName)

func PlayPieceAnimation() -> void:
	piecesManager.PlayAnimationByPlayerIndex(currentPlayerColor)

func StopPieceAnimation() -> void:
	piecesManager.StopAnimation()

func DetectKill(pieceToBeGoHome: Piece) -> void:
	if pieceToBeGoHome == null:
		hasKill = false
		return

	hasKill = true
	MovePiecesToHome(0, pieceToBeGoHome)
