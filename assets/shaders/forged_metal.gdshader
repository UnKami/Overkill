shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 steel_color : source_color = vec4(0.16, 0.21, 0.24, 1.0);
uniform float metalness = 0.88;
uniform float wear = 0.4;
uniform sampler2D surface_detail : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
varying vec3 local_normal;
varying vec3 local_pos;

void vertex() { local_pos=VERTEX; local_normal=NORMAL; }
void fragment() {
    vec3 weights = pow(abs(local_normal), vec3(4.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    vec3 scanned = texture(surface_detail, local_pos.yz * 1.3).rgb * weights.x
        + texture(surface_detail, local_pos.xz * 1.3).rgb * weights.y
        + texture(surface_detail, local_pos.xy * 1.3).rgb * weights.z;
    float detail = clamp(dot(scanned, vec3(0.333)) * 2.2, 0.0, 1.0);
    float patina = detail;
    float wear_mask = smoothstep(0.55,0.82,detail) * wear * 0.06;
    ALBEDO = steel_color.rgb * (0.67 + patina * 0.22 + detail * 0.45) + vec3(wear_mask);
    METALLIC = metalness * mix(0.72, 1.0, detail);
    ROUGHNESS = clamp(0.54 + (1.0 - detail) * 0.25 - wear_mask, 0.48, 0.82);
}
