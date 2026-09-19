shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 plate_color : source_color = vec4(0.12, 0.15, 0.17, 1.0);
uniform vec4 exposed_color : source_color = vec4(0.29, 0.32, 0.34, 1.0);
uniform float metalness = 0.85;
uniform sampler2D surface_detail : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
varying vec3 local_normal;
varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
    local_normal = NORMAL;
}

void fragment() {
    vec3 weights = pow(abs(local_normal), vec3(4.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    vec3 scanned = texture(surface_detail, local_pos.yz * 1.3).rgb * weights.x
        + texture(surface_detail, local_pos.xz * 1.3).rgb * weights.y
        + texture(surface_detail, local_pos.xy * 1.3).rgb * weights.z;
    float grain = clamp(dot(scanned, vec3(0.333)) * 2.2, 0.0, 1.0);
    float edge = clamp(COLOR.r, 0.0, 1.0);
    float patina = mix(0.88, 1.04, COLOR.g);
    // Geometry-authored edge exposure supplies the wear, not random bright speckle.
    ALBEDO = mix(plate_color.rgb * patina * (0.94 + grain * 0.10), exposed_color.rgb, edge * (0.50 + grain * 0.15));
    AO = mix(0.45, 1.0, COLOR.b);
    METALLIC = mix(metalness * 0.87, metalness, edge);
    ROUGHNESS = mix(0.62 + (1.0 - grain) * 0.12, 0.36 + (1.0 - grain) * 0.08, edge);
}
