shader_type spatial;
render_mode specular_schlick_ggx;

// Rest-space detail remains attached to the skinned surface. Broad authored
// vertex staining stays authoritative; fine wear fades below pixel resolution.
varying vec3 rest_position;

float hash31(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

float grain(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash31(cell), hash31(cell + vec3(1,0,0)), f.x),
                   mix(hash31(cell + vec3(0,1,0)), hash31(cell + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash31(cell + vec3(0,0,1)), hash31(cell + vec3(1,0,1)), f.x),
                   mix(hash31(cell + vec3(0,1,1)), hash31(cell + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
    rest_position = VERTEX;
}

void fragment() {
    float stains = grain(rest_position * 22.0);
    vec3 fine_position = rest_position * 170.0;
    float footprint = max(length(dFdx(fine_position)), length(dFdy(fine_position)));
    float resolved = 1.0 - smoothstep(0.35, 1.1, footprint);
    float pores = smoothstep(0.61, 0.86, grain(fine_position));
    float worn = grain(rest_position * vec3(95.0, 95.0, 18.0));
    float relief = (worn - pores * 0.45) * resolved * 0.00014;
    ALBEDO = COLOR.rgb * mix(vec3(0.90,0.90,0.87), vec3(1.18,1.19,1.20), stains);
    ALBEDO *= 1.0 - pores * resolved * 0.07;
    ROUGHNESS = clamp(0.84 + stains * 0.10 + pores * resolved * 0.06 - worn * resolved * 0.12, 0.72, 0.98);
    METALLIC = 0.0;
    SPECULAR = 0.32;
    // Surface-gradient bump works without UVs or imported tangent seams.
    vec3 dx = dFdx(VERTEX);
    vec3 dy = dFdy(VERTEX);
    vec3 r1 = cross(dy, NORMAL);
    vec3 r2 = cross(NORMAL, dx);
    float determinant = dot(dx, r1);
    vec3 gradient = (dFdx(relief) * r1 + dFdy(relief) * r2) / max(abs(determinant), 0.00000001);
    NORMAL = normalize(NORMAL - sign(determinant) * gradient);
}
