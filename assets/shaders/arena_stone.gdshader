shader_type spatial;
// Quiet matte limestone: preserve material relief without bright distracting seams.
uniform sampler2D stone_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D stone_roughness : filter_linear_mipmap_anisotropic;
uniform vec2 tile_scale = vec2(18.0);
uniform float surface_detail : hint_range(0.0, 1.0) = 1.0;
void fragment() {
    vec2 uv = UV * tile_scale;
    vec3 stone = texture(stone_color, uv).rgb;
    ALBEDO = mix(vec3(0.14, 0.15, 0.16), stone * vec3(0.35, 0.37, 0.39), 0.75);
    float wear = texture(stone_roughness, uv).r;
    // Rough mortar stays quiet; smoother stone catches the grazing key light.
    ALBEDO *= mix(1.0, 0.68, smoothstep(0.70, 0.90, wear) * surface_detail);
    NORMAL_MAP = texture(stone_normal, uv).rgb;
    NORMAL_MAP_DEPTH = mix(0.10, 0.32, surface_detail);
    ROUGHNESS = mix(0.88, mix(0.62, 0.96, wear), surface_detail);
    SPECULAR = 0.25;
}
