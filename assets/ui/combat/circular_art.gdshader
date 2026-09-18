shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float mask = 1.0 - smoothstep(0.475, 0.495, length(UV - vec2(0.5)));
	COLOR = vec4(tex.rgb * tint.rgb, tex.a * mask * tint.a) * vertex_tint;
}
