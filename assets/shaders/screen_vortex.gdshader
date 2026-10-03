shader_type canvas_item;

uniform float progress : hint_range(-0.1, 1.5) = -0.1;
uniform float spin = 0.0;
uniform vec4 ink : source_color = vec4(0.012, 0.020, 0.030, 1.0);
uniform vec4 rim : source_color = vec4(0.18, 0.43, 0.48, 1.0);

void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float radius = length(centered) * 1.42;
	float angle = atan(centered.y, centered.x);
	float edge = 1.0 - smoothstep(progress - 0.055, progress + 0.035, radius);
	float spiral = sin(angle * 5.0 - radius * 24.0 + spin) * 0.5 + 0.5;
	float filaments = smoothstep(0.62, 1.0, spiral) * (1.0 - smoothstep(progress - 0.16, progress + 0.02, radius));
	float rim_band = 1.0 - smoothstep(0.0, 0.055, abs(radius - progress));
	vec3 color = mix(ink.rgb, rim.rgb * 0.42, filaments * 0.34 + rim_band * 0.28);
	COLOR = vec4(color, clamp(edge + filaments * 0.22 + rim_band * 0.16, 0.0, 1.0));
}
