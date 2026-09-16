extends Node2D

const FACTION_MARKERS := {
	"Astherion": preload("res://Arts/Textures_Game/Board/Astherion Finish.png"),
	"Nekravia": preload("res://Arts/Textures_Game/Board/Nekravia Finish.png"),
	"Nerathis": preload("res://Arts/Textures_Game/Board/Nerathis Finish.png"),
	"Thornvale": preload("res://Arts/Textures_Game/Board/Thornvale Finish.png"),
}

const MARKER_SIZE := 80.0 # 25% larger than the original 64-unit marker.
# Circle centers within each 501.6 x 501.6 base crop of the 1254px board art.
const BASE_CIRCLE_CENTERS := {
	"Astherion": [Vector2(172, 181), Vector2(317, 181), Vector2(172, 315), Vector2(317, 315)],
	"Nekravia": [Vector2(184, 200), Vector2(329, 200), Vector2(182, 335), Vector2(328, 335)],
	"Nerathis": [Vector2(173, 200), Vector2(318, 200), Vector2(173, 335), Vector2(318, 335)],
	"Thornvale": [Vector2(182, 181), Vector2(328, 181), Vector2(182, 315), Vector2(328, 315)],
}

var elapsed := 0.0
var marker := false
var marker_texture: Texture2D
var team_color := Color.WHITE

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func align_to_base(base: Sprite2D, lobby_global: Vector2, faction: String) -> void:
	if not BASE_CIRCLE_CENTERS.has(faction) or base.texture == null:
		return
	var nearest := lobby_global
	var nearest_distance := INF
	for center: Vector2 in BASE_CIRCLE_CENTERS[faction]:
		var local_center := (center / 501.6 - Vector2.ONE * 0.5) * base.texture.get_size()
		var candidate := base.to_global(local_center)
		var distance := candidate.distance_squared_to(lobby_global)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	global_position = nearest
	global_rotation = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if not marker and elapsed >= 1.1:
		queue_free()

func _draw() -> void:
	if marker:
		var pulse := 1.0 + 0.15 * sin(minf(elapsed / 0.4, 1.0) * PI)
		if marker_texture != null:
			var size := marker_texture.get_size()
			size *= MARKER_SIZE * pulse / maxf(size.x, size.y)
			draw_texture_rect(marker_texture, Rect2(-size * 0.5, size), false)
		if elapsed >= 0.4:
			set_process(false)
		return
	for burst in range(3):
		var age := elapsed - burst * 0.16
		if age < 0.0:
			continue
		var origin := Vector2((burst - 1) * 42.0, -35.0 - (burst % 2) * 40.0)
		for spark in range(16):
			var direction := Vector2.from_angle(TAU * spark / 16.0 + burst * 0.3)
			var point := origin + direction * age * (110.0 + burst * 25.0) + Vector2(0, 65.0 * age * age)
			var tint := team_color if spark % 2 == 0 else Color("ffe28a")
			tint.a = clampf(1.0 - age / 0.8, 0.0, 1.0)
			draw_line(point - direction * 10.0, point, tint, 3.0, true)
			draw_circle(point, 2.5, tint)
