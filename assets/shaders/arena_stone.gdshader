shader_type spatial;
uniform vec4 stone_color : source_color = vec4(0.04,0.055,0.065,1.0);
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 tile=world_pos.xz*1.2;
    tile.x+=mod(floor(tile.y),2.0)*0.5;
    vec2 f=fract(tile);
    float edge=min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
    float grout=smoothstep(0.008,0.025,edge);
    float variation=hash(floor(tile));
    float grain=hash(floor(world_pos.xz*600.0));
    ALBEDO=stone_color.rgb*(0.85+variation*0.2+grain*0.1)*mix(0.6,1.0,grout);
    ROUGHNESS=0.53+variation*0.22;
    METALLIC=0.15;
}
