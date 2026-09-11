extends Control
## Resolution-independent night landscape and arcane ornaments for the main menu.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var scale_factor := size / Vector2(1920, 1080)
	draw_set_transform(Vector2.ZERO, 0.0, scale_factor)
	draw_rect(Rect2(0, 0, 1920, 1080), Color("080e20"))
	# Layered translucent halos create a soft moonlit sky.
	for step in range(24, 0, -1):
		var radius := float(step) * 38.0
		draw_circle(Vector2(960, 330), radius, Color(0.13, 0.23, 0.36, 0.018))
		draw_circle(Vector2(160, 710), radius * 0.65, Color(0.12, 0.26, 0.23, 0.012))
	var random := RandomNumberGenerator.new()
	random.seed = 72419
	for star in range(150):
		var point := Vector2(random.randf_range(25, 1895), random.randf_range(20, 850))
		var opacity := random.randf_range(0.15, 0.65)
		draw_circle(point, random.randf_range(0.7, 1.8), Color(0.86, 0.82, 0.63, opacity))
	# A pair of gilded celestial rings surrounds the selection panel.
	var center := Vector2(960, 530)
	for radius in [475.0, 494.0, 710.0]:
		draw_arc(center, radius, 0, TAU, 160, Color(0.74, 0.57, 0.28, 0.19), 1.5, true)
	for mark in range(32):
		var direction := Vector2.from_angle(TAU * float(mark) / 32.0)
		draw_line(center + direction * 494, center + direction * 508, Color(0.85, 0.67, 0.36, 0.32), 2, true)
	# Distant mountain silhouettes, with a ruined tower on either side.
	for layer in range(3):
		var ridge := PackedVector2Array([Vector2(0, 1080)])
		for point in range(17):
			ridge.append(Vector2(float(point) * 120, 730 + layer * 95 - random.randf_range(0, 160)))
		ridge.append(Vector2(1920, 1080))
		draw_colored_polygon(ridge, [Color("101c2b"), Color("0b1523"), Color("070e19")][layer])
	for tower_x in [95.0, 1765.0]:
		draw_rect(Rect2(tower_x, 630, 60, 320), Color("080f1c"))
		draw_colored_polygon(PackedVector2Array([Vector2(tower_x - 12, 630), Vector2(tower_x + 30, 555), Vector2(tower_x + 72, 630)]), Color("080f1c"))
		for window_y in [665.0, 735.0]:
			draw_rect(Rect2(tower_x + 25, window_y, 10, 22), Color(0.90, 0.64, 0.26, 0.55))
	# Corner flourishes frame the landscape without obscuring the buttons.
	for corner in [Vector2(36, 36), Vector2(1884, 36), Vector2(36, 1044), Vector2(1884, 1044)]:
		var inward := Vector2(1 if corner.x < 960 else -1, 1 if corner.y < 540 else -1)
		var gold := Color(0.81, 0.64, 0.35, 0.65)
		draw_line(corner, corner + Vector2(inward.x * 180, 0), gold, 2, true)
		draw_line(corner, corner + Vector2(0, inward.y * 110), gold, 2, true)
		var jewel: Vector2 = corner + inward * 16
		draw_colored_polygon(PackedVector2Array([jewel + Vector2(0, -5), jewel + Vector2(4, 0), jewel + Vector2(0, 5), jewel + Vector2(-4, 0)]), gold)