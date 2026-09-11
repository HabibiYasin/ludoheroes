extends Node2D

var elapsed := 0.0
var marker := false
var team_color := Color.WHITE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if not marker and elapsed >= 1.1:
		queue_free()

func _draw() -> void:
	if marker:
		var pulse := 1.0 + 0.15 * sin(minf(elapsed / 0.4, 1.0) * PI)
		draw_circle(Vector2.ZERO, 32.0 * pulse, Color("164c32"))
		draw_circle(Vector2.ZERO, 27.0 * pulse, Color("36d878"))
		draw_arc(Vector2.ZERO, 28.0 * pulse, 0, TAU, 48, Color("dcffe7"), 2.5, true)
		draw_polyline(PackedVector2Array([Vector2(-13, 0), Vector2(-4, 10), Vector2(15, -12)]), Color.WHITE, 5.0, true)
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
