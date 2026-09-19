shader_type spatial;
render_mode cull_disabled, world_vertex_coords;
uniform vec4 cloth_color : source_color = vec4(0.025,0.06,0.085,1);
uniform float motion = 1.0;

// Parametric surface matches RiggedCombatant._build_cloak; its mesh supplies UVs and bounds.
vec3 cloth_position(vec2 uv, mat4 model) {
    float width = mix(0.26,0.44,uv.y);
    vec3 point = vec3((uv.x-0.5)*2.0*width,1.67-uv.y*1.29,
        0.16+uv.y*0.20+sin(uv.x*25.132741)*0.027*uv.y);
    float weight = uv.y*uv.y;
    point.z += sin(TIME*1.9+uv.x*7.0+uv.y*3.0)*0.018*weight*motion;
    point.x += sin(TIME*1.1+uv.y*5.0)*0.009*weight*motion;
    vec3 world_point = (model*vec4(point,1.0)).xyz;
    // Keep the shoulder seam attached, progressively directing the drop toward gravity.
    vec3 rigid_drop = (model*vec4(0.0,-uv.y*1.29,0.0,0.0)).xyz;
    vec3 gravity_drop = vec3(0.0,-length(rigid_drop),0.0);
    world_point += (gravity_drop-rigid_drop)*smoothstep(0.03,0.72,uv.y)*0.90;
    // A quiet ground constraint lets a kneeling actor's hem pool behind its feet.
    vec3 back = (model*vec4(0.0,0.0,1.0,0.0)).xyz;
    back.y = 0.0;
    back = normalize(back+vec3(0.0,0.0,0.0001));
    world_point += back*max(0.0,0.035-world_point.y)*0.85;
    world_point.y = max(world_point.y,0.035);
    return world_point;
}
void vertex() {
    vec3 point = cloth_position(UV,MODEL_MATRIX);
    vec3 across = cloth_position(UV+vec2(0.002,0.0),MODEL_MATRIX)-point;
    vec3 down = cloth_position(UV+vec2(0.0,0.002),MODEL_MATRIX)-point;
    VERTEX = point;
    NORMAL = normalize(cross(down,across));
}
void fragment() {
    // Filter fine weave at distance instead of letting subpixel threads shimmer.
    vec2 frequency = vec2(1100.0,1700.0);
    vec2 footprint = fwidth(UV*frequency);
    float filtered = 1.0-smoothstep(0.5,1.5,max(footprint.x,footprint.y));
    float weave = sin(UV.x*frequency.x)*sin(UV.y*frequency.y)*0.035*filtered;
    // Narrow woven binding replaces the broad, flat gold border. Filter at distance.
    float edge_distance = min(min(UV.x,1.0-UV.x),1.0-UV.y);
    float aa = max(fwidth(edge_distance),0.0001);
    float hem = 1.0-smoothstep(0.012-aa,0.012+aa,edge_distance);
    ALBEDO = mix(cloth_color.rgb*(0.85+weave),vec3(0.095,0.067,0.039)*(0.95+weave),hem);
    ROUGHNESS = 0.94;
}
