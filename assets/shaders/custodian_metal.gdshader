shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 plate_color : source_color = vec4(0.20, 0.26, 0.29, 1.0);
uniform vec4 exposed_color : source_color = vec4(0.42, 0.46, 0.47, 1.0);
uniform vec4 oxide_color : source_color = vec4(0.13, 0.16, 0.16, 1.0);
uniform float metalness : hint_range(0.0, 1.0) = 0.87;
uniform float face_roughness : hint_range(0.0, 1.0) = 0.48;
uniform float oxide_amount : hint_range(0.0, 1.0) = 0.35;
uniform sampler2D surface_detail : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
varying vec3 rest_position;
varying vec3 rest_normal;

void vertex() {
    rest_position = VERTEX;
    rest_normal = NORMAL;
}

float grain_at(vec3 point, vec3 weights) {
    vec3 sample_color = texture(surface_detail, point.yz).rgb * weights.x
        + texture(surface_detail, point.xz).rgb * weights.y
        + texture(surface_detail, point.xy).rgb * weights.z;
    return dot(sample_color, vec3(0.333333));
}

void fragment() {
    vec3 weights = pow(abs(rest_normal), vec3(4.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    // Model-space triplanar detail; mip filtering suppresses distant grain.
    float detail = grain_at(rest_position * 1.8, weights);
    float broad = grain_at(rest_position * 0.65 + vec3(0.31, 0.57, 0.19), weights);
    float grain = smoothstep(0.025, 0.23, detail);
    float weather = 1.0 - smoothstep(0.035, 0.16, broad);
    float bevel = clamp(COLOR.r, 0.0, 1.0);
    // Keep actual bevel masks, but interrupt the polished edge with tarnish.
    float exposed = bevel * mix(0.40, 0.76, grain) * (1.0 - weather * 0.32);
    float oxide = weather * oxide_amount * (1.0 - exposed);
    float part_variation = mix(0.82, 1.08, COLOR.g);
    vec3 base = plate_color.rgb * part_variation * mix(0.94, 1.04, grain);
    ALBEDO = mix(mix(base, oxide_color.rgb, oxide), exposed_color.rgb, exposed);
    METALLIC = mix(metalness, 0.48, oxide);
    ROUGHNESS = clamp(mix(face_roughness + (1.0 - grain) * 0.06 + oxide * 0.22, 0.28, exposed), 0.24, 0.86);
    AO = mix(0.45, 1.0, COLOR.b);
}
