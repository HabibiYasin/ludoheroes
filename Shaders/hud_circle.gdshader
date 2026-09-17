shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float edge = length(UV - vec2(0.5));
	tex.a *= 1.0 - smoothstep(0.488, 0.5, edge);
	COLOR = tex;
}
