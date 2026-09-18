shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 steel_color : source_color = vec4(0.16, 0.21, 0.24, 1.0);
uniform float metalness = 0.88;
uniform float wear = 0.4;
varying vec3 local_pos;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
float noise(vec3 p) {
    vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { local_pos=VERTEX; }
void fragment() {
    float patina=noise(local_pos*15.0);
    float grain=noise(local_pos*390.0);
    float scratches=pow(noise(local_pos*vec3(200.0,8.0,200.0)),12.0);
    ALBEDO=steel_color.rgb*(0.7+patina*0.5+grain*0.14)+vec3(scratches*wear);
    METALLIC=metalness;
    ROUGHNESS=clamp(0.29+patina*0.22-grain*0.08,0.19,0.65);
}
