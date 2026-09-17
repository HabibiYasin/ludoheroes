extends Button

## Circular artwork shared by faction, player and hero controls.
const CIRCLE_SHADER = preload("res://Shaders/hud_circle.gdshader")
var portrait: TextureRect
var background: TextureRect
var shade: ColorRect
var ring_color := Color.WHITE:
	set(value):
		if ring_color == value:
			return
		ring_color = value
		queue_redraw()
var backing_color := Color(1, 1, 1, 0.5)
var ring_width := 5.0

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	background = _texture(7)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait = _texture(10)
	shade = ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.material = _mask()
	shade.color = Color.TRANSPARENT
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.offset_left = 7
	shade.offset_top = 7
	shade.offset_right = -7
	shade.offset_bottom = -7
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _mask() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = CIRCLE_SHADER
	return result

func _texture(inset: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.material = _mask()
	add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = inset
	picture.offset_top = inset
	picture.offset_right = -inset
	picture.offset_bottom = -inset
	return picture

func _draw() -> void:
	var radius := minf(size.x, size.y) * 0.5
	draw_circle(size * 0.5, radius - ring_width, backing_color)
	if ring_width > 0:
		draw_arc(size * 0.5, radius - ring_width * 0.5, 0, TAU, 128, ring_color, ring_width, true)
	if is_hovered() or has_focus():
		draw_arc(size * 0.5, radius - 2, 0, TAU, 128, Color.WHITE, 2, true)
