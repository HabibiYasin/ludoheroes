class_name Piece
extends Node2D

const HeroCatalog = preload("res://Scripts/HeroCatalog.gd")
const HERO_DISPLAY_SCALE := 0.8
const FinishCelebration = preload("res://Scripts/FinishCelebration.gd")
var finish_marker: Node2D
var _finish_presented := false
signal StatsChanged

@export var HeroId: String = ""
var HeroClass: String = "Unknown"
var Faction: String = ""
var MaxHealth: int = 1
var Health: int = 1
var Attack: int = 0
enum DamageType { PHYSICAL, MAGICAL }
var PhysicalDefense: int = 0:
	set(value):
		PhysicalDefense = maxi(0, value)
		StatsChanged.emit()
var MagicalDefense: int = 0:
	set(value):
		MagicalDefense = maxi(0, value)
		StatsChanged.emit()

func InitializeStats() -> void:
	if not HeroCatalog.HEROES.has(HeroId):
		return
	var stats: Array = HeroCatalog.HEROES[HeroId]
	HeroClass = stats[0]
	Faction = stats[1]
	Attack = stats[2]
	MaxHealth = stats[3]
	PhysicalDefense = stats[4]
	MagicalDefense = stats[5]
	Health = MaxHealth
	StatsChanged.emit()

func HasClass(class_value: String) -> bool:
	for value in HeroClass.to_lower().split("-"):
		if value.strip_edges() == class_value.to_lower():
			return true
	return false

func GetIncomingDamage(amount: int, direct: bool = true, damage_type: DamageType = DamageType.PHYSICAL) -> int:
	var defense := MagicalDefense if damage_type == DamageType.MAGICAL else PhysicalDefense
	return maxi(0, amount - defense - (1 if HasClass("Tank") and not direct else 0))

func Heal(amount: int) -> void:
	if Health <= 0 or amount <= 0 or Health >= MaxHealth:
		return
	Health = mini(MaxHealth, Health + amount)
	StatsChanged.emit()

func GetMoveDistance(dice_value: int) -> int:
	if not HasClass("Runner") or IsInLobby() or IsInHome or dice_value not in [1, 2, 3] or wayPointManager == null:
		return dice_value
	# The entire boosted move must stay on the shared track.
	for index in range(CurrentPosition, CurrentPosition + dice_value + 2):
		var cell := wayPointManager.GetWayPoint(index, CurrentPlayerColor)
		if cell == null or cell.get_parent() != wayPointManager.main_path:
			return dice_value
	return dice_value + 1

func TakeDamage(amount: int, direct: bool = true, damage_type: DamageType = DamageType.PHYSICAL) -> bool:
	amount = GetIncomingDamage(amount, direct, damage_type)
	if Health <= 0 or amount <= 0:
		return false
	Health = maxi(0, Health - amount)
	StatsChanged.emit()
	return Health == 0

# -1 means the piece is still in the lobby/base.
var CurrentPosition: int = -1
var CurrentState: GameManager.PieceStateEnum = GameManager.PieceStateEnum.InLobby
var StartingPosition: int = 0
var wayPointManager: WayPointsManager
var CurrentWayPoint: WayPoint
var IsInHome: bool = false
var LobbyPosition: Vector2
var _normal_scale := Vector2.ONE
var _normal_sprite_position := Vector2.ZERO

@export var CurrentPlayerColor: GameManager.PlayerColor
@export var PieceSprite: Sprite2D
@export var animation_PieceSelect: AnimationPlayer
@export var PieceTexture: Texture2D

func _ready() -> void:
	InitializeStats()
	LobbyPosition = position
	if PieceTexture != null and PieceSprite != null:
		# Fit replacement artwork into the original piece's footprint.
		# Scale the root so the sprite's selection animation stays relative.
		if PieceSprite.texture != null:
			var original_size := PieceSprite.texture.get_size()
			var replacement_size := PieceTexture.get_size()
			if replacement_size.x > 0.0 and replacement_size.y > 0.0:
				var fit_scale := minf(original_size.x / replacement_size.x, original_size.y / replacement_size.y)
				scale *= fit_scale
		PieceSprite.texture = PieceTexture
	_normal_scale = scale
	scale *= HERO_DISPLAY_SCALE
	if PieceSprite != null:
		_normal_sprite_position = PieceSprite.position
	wayPointManager = get_tree().get_first_node_in_group("WayPointManagerGroup")

# Offset only the artwork: logical movement stays at the waypoint center.
# Root scaling remains independent of the sprite's selection animation.
func SetSharedCellLayout(offset: Vector2, slot_size: Vector2 = Vector2.ZERO) -> void:
	if PieceSprite == null or PieceSprite.texture == null:
		return
	var fit := 1.0
	if slot_size != Vector2.ZERO:
		var normal_size := PieceSprite.texture.get_size() * _normal_scale.abs()
		fit = 2.0 * minf(1.0, minf(slot_size.x / normal_size.x, slot_size.y / normal_size.y))
	scale = _normal_scale * fit * HERO_DISPLAY_SCALE
	PieceSprite.position = _normal_sprite_position + offset / scale

func SetStartPosition(index: int) -> void:
	_reset_finish_presentation()
	StartingPosition = index
	CurrentPosition = -1
	CurrentState = GameManager.PieceStateEnum.InLobby
	IsInHome = false
	CurrentWayPoint = null

func SetCurrentPositionAndCheckKill(index: int) -> void:
	if IsInHome:
		return

	if IsInLobby() and Health == 0:
		Health = MaxHealth
		StatsChanged.emit()
	CurrentPosition = index
	CurrentState = GameManager.PieceStateEnum.InWayPoint

	if wayPointManager != null:
		wayPointManager.SetPieceToThisWayPoint(index, self)

func SendBackToLobby() -> void:
	_reset_finish_presentation()
	if CurrentWayPoint != null:
		CurrentWayPoint.RemoveMyRef(self)

	CurrentWayPoint = null
	CurrentPosition = -1
	CurrentState = GameManager.PieceStateEnum.InLobby
	IsInHome = false
	position = LobbyPosition
	SetSharedCellLayout(Vector2.ZERO)

func GetCurrentPosition() -> int:
	return CurrentPosition

func IsInLobby() -> bool:
	return CurrentState == GameManager.PieceStateEnum.InLobby

func HasThisPlayerUnlockedPiece() -> bool:
	return CurrentState != GameManager.PieceStateEnum.InLobby

func CanMoveWithDice(dice_value: int, path_count: int) -> bool:
	if IsInHome:
		return false

	# Standard Ludo rule: a piece can leave the base only with a 6.
	if IsInLobby():
		return dice_value == 6

	var target_position := CurrentPosition + GetMoveDistance(dice_value)
	return target_position < path_count

func _unhandled_input(event: InputEvent) -> void:
	if IsInHome or not is_visible_in_tree():
		return
	# Let board clicks reach Dice while a human player is waiting to roll.
	var input_board: BoardManager = get_tree().get_first_node_in_group("BoardManager")
	if input_board != null and input_board.IsHumanTurn() and GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice:
		return
	if not event.is_action_pressed("PlayerClick"):
		return

	if PieceSprite == null:
		return

	var local_mouse_position := PieceSprite.get_local_mouse_position()
	if PieceSprite.is_pixel_opaque(local_mouse_position):
		GameManager.HeroInspected.emit(self)
		var board: BoardManager = get_tree().get_first_node_in_group("BoardManager")
		if board != null and board.IsHumanTurn() and GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerSelectPiece:
			board._on_player_select_piece(self, true)
		get_viewport().set_input_as_handled()

func AIInput() -> void:
	if IsInHome:
		return

	# Do not remove the waypoint reference here.
	# BoardManager validates the move first, then removes it when movement starts.
	GameManager.OnPlayerSelectPiece.emit(self)

func PlayAnimation() -> void:
	if CurrentState != GameManager.PieceStateEnum.InHouse and not IsInHome:
		if animation_PieceSelect != null:
			animation_PieceSelect.play("PieceAnimation_Select")

func StopAnimation() -> void:
	if animation_PieceSelect != null:
		animation_PieceSelect.stop()

func CelebrateFinish() -> void:
	if not IsInHome or _finish_presented:
		return
	_finish_presented = true
	StopAnimation()
	if CurrentWayPoint != null:
		CurrentWayPoint.RemoveMyRef(self)
		CurrentWayPoint = null
	var fireworks := FinishCelebration.new()
	match CurrentPlayerColor:
		GameManager.PlayerColor.Blue: fireworks.team_color = Color("44bcff")
		GameManager.PlayerColor.Red: fireworks.team_color = Color("ff6262")
		GameManager.PlayerColor.Yellow: fireworks.team_color = Color("ffdf38")
		GameManager.PlayerColor.Green: fireworks.team_color = Color("46ef91")
	get_parent().add_child(fireworks)
	fireworks.position = position
	fireworks.z_index = 20
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.35)
	await fade.finished
	hide()
	finish_marker = FinishCelebration.new()
	finish_marker.marker = true
	get_parent().add_child(finish_marker)
	finish_marker.position = LobbyPosition
	finish_marker.scale = Vector2.ONE * 1.85
	finish_marker.global_rotation = 0.0
	finish_marker.z_index = 10
	await get_tree().create_timer(0.75, false).timeout

func _reset_finish_presentation() -> void:
	if is_instance_valid(finish_marker):
		finish_marker.queue_free()
	finish_marker = null
	_finish_presented = false
	modulate.a = 1.0
	show()
