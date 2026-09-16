extends Node2D

# Board-local base rectangles, independent of the optional Places sprites.
const BASE_ORIGINS := [Vector2(-902, 180.4), Vector2(-902, -902), Vector2(180.4, -902), Vector2(180.4, 180.4)]
const COLORS := [Color("8fef8b"), Color("ffd16b"), Color("7fcbff"), Color("ff8c83")]
var faction: int = 0
var phase := 0.0

func _ready() -> void:
	name = "TurnIndicator"
	z_index = 2
	GameManager.OnGameCurrentStateChange.connect(_on_state_changed)
	_on_state_changed(GameManager.GameCurrentState)

func set_faction(color: int) -> void:
	faction = color
	phase = 0.0
	modulate.a = 1.0
	queue_redraw()
	_on_state_changed(GameManager.GameCurrentState)

func _on_state_changed(state: GameManager.GameStateEnum) -> void:
	visible = state == GameManager.GameStateEnum.PlayerCanRollDice

func _process(delta: float) -> void:
	if not visible:
		return
	phase += delta
	modulate.a = 0.75 + 0.25 * cos(phase * TAU / 1.15)

func _draw() -> void:
	var bounds := Rect2(BASE_ORIGINS[faction] + Vector2.ONE * 20.0, Vector2.ONE * 681.6)
	var color: Color = COLORS[faction]
	draw_rect(bounds, Color(color, 0.14), true)
	draw_rect(bounds, Color(color, 0.20), false, 40.0)
	draw_rect(bounds, Color(color, 0.50), false, 28.0)
	draw_rect(bounds, color, false, 16.0)
	draw_rect(bounds, color.lerp(Color.WHITE, 0.75), false, 5.0)
