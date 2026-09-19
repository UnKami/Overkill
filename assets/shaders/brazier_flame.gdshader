shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float phase = 0.0;
uniform float motion : hint_range(0.0,1.0) = 1.0;

float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
    // Small world-positioned billboard; depth testing still allows basket occlusion.
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment() {
    float t=TIME*motion+phase;
    float h=1.0-UV.y;
    float turbulence=noise2(vec2(UV.x*8.0,h*7.0-t*1.8));
    float x=UV.x-0.5+(turbulence-0.5)*h*0.19;
    float flame=0.0;
    for(int i=0;i<3;i++) {
        float k=float(i)-1.0;
        float peak=0.62+0.20*sin(t*1.7+float(i)*2.1);
        if(i==1) peak+=0.12;
        float taper=max(0.0,1.0-h/peak);
        float center=k*0.19*taper+0.025*sin(t*2.3+float(i)*3.0+h*9.0)*h;
        float tongue=1.0-smoothstep(0.045*taper,0.19*taper+0.004,abs(x-center));
        tongue*=1.0-smoothstep(peak-0.16,peak,h);
        flame=max(flame,tongue);
    }
    float core=clamp(flame*(1.0-h)*1.4,0.0,1.0);
    ALBEDO=mix(vec3(0.72,0.11,0.008),vec3(1.0,0.72,0.23),core);
    ALPHA=flame*smoothstep(0.0,0.06,h)*0.88;
}
