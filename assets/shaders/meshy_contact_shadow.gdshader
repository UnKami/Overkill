shader_type canvas_item;
render_mode unshaded;
varying vec2 contact_vertex;
void vertex() { contact_vertex = VERTEX; }
void fragment() {
	float radius = length(contact_vertex / vec2(82.0, 11.0));
	float fade = 1.0 - smoothstep(0.55, 1.0, radius);
	float opacity = (0.32 * exp(-3.0 * radius * radius) + 0.30 * exp(-16.0 * radius * radius)) * fade;
	COLOR = vec4(0.005, 0.012, 0.018, opacity * COLOR.a);
}
