shader_type canvas_item;
uniform vec4 accent : source_color = vec4(0.4, 0.6, 0.7, 1.0);
void fragment() {
	vec2 p = UV - vec2(0.5);
	float radius = length(p);
	float outer = 1.0 - smoothstep(0.47, 0.5, radius);
	float bezel = smoothstep(0.405, 0.43, radius);
	float light = clamp(0.6 - p.y * 0.9 - p.x * 0.3, 0.1, 1.0);
	vec3 metal = mix(vec3(0.10, 0.13, 0.15), accent.rgb * light, 0.65);
	vec3 well = mix(vec3(0.017, 0.03, 0.04), vec3(0.06, 0.085, 0.1), clamp(radius * 1.8, 0.0, 1.0));
	vec3 result = mix(well, metal, bezel);
	float lip = smoothstep(0.425, 0.438, radius) * (1.0 - smoothstep(0.445, 0.457, radius));
	result += accent.rgb * lip * 0.35;
	COLOR = vec4(result, outer * COLOR.a);
}
