shader_type spatial;
// Quiet matte limestone: preserve material relief without bright distracting seams.
uniform sampler2D stone_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform vec2 tile_scale = vec2(18.0);
void fragment() {
    vec2 uv = UV * tile_scale;
    vec3 stone = texture(stone_color, uv).rgb;
    ALBEDO = mix(vec3(0.14, 0.15, 0.16), stone * vec3(0.35, 0.37, 0.39), 0.75);
    NORMAL_MAP = texture(stone_normal, uv).rgb;
    NORMAL_MAP_DEPTH = 0.10;
    ROUGHNESS = 0.88;
    SPECULAR = 0.25;
}
