shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform sampler2D relic_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.58, 0.24, 0.85, 0.70);
uniform vec4 emission_tint : source_color = vec4(0.42, 0.08, 0.75, 1.0);
uniform vec3 enemy_point = vec3(0.0);
uniform vec3 hand_point = vec3(1.0, 0.0, 0.0);
uniform vec3 camera_axis = vec3(0.0, 0.0, 1.0);
uniform float extension : hint_range(0.0, 1.0) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.0;

vec3 curve(float t) {
	vec3 at = mix(enemy_point, hand_point, t);
	at.y -= sin(t * PI) * distance(enemy_point, hand_point) * 0.12;
	return at;
}

vec3 curve_tangent(float t) {
	vec3 direction = hand_point - enemy_point;
	direction.y -= cos(t * PI) * distance(enemy_point, hand_point) * 0.12 * PI;
	return normalize(direction + vec3(0.000001, 0.0, 0.0));
}

vec3 ring_normal(float t) {
	vec3 axis = cross(curve_tangent(t), camera_axis);
	return normalize(axis + vec3(0.0, 0.000001, 0.0));
}

vec3 tube_point(float t, float angle) {
	vec3 normal = ring_normal(t);
	vec3 binormal = normalize(cross(curve_tangent(t), normal));
	float pulse = (t - progress) / 0.085;
	float radius = 0.024 + 0.073 * energy * exp(-pulse * pulse);
	return curve(t) + (normal * cos(angle) + binormal * sin(angle)) * radius;
}

void vertex() {
	float t = UV.x * extension;
	float angle = UV.y * TAU;
	VERTEX = tube_point(t, angle);
	vec3 normal = ring_normal(t);
	vec3 binormal = normalize(cross(curve_tangent(t), normal));
	vec3 angular = -normal * sin(angle) + binormal * cos(angle);
	vec3 along = tube_point(min(1.0, t + 0.002), angle) - tube_point(max(0.0, t - 0.002), angle);
	NORMAL = normalize(cross(angular, along));
	UV = (mix(vec2(470.0, 460.0), vec2(839.0, 800.0), t) + vec2(-0.67, 0.74) * 34.0 * cos(angle)) / 1280.0;
}

void fragment() {
	vec4 artwork = texture(relic_texture, UV);
	ALBEDO = artwork.rgb * tint.rgb;
	ALPHA = artwork.a * tint.a * opacity;
	METALLIC = 0.25;
	ROUGHNESS = 0.3;
	EMISSION = (artwork.rgb + emission_tint.rgb) * 0.35;
}
