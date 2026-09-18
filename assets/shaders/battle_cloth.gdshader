shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color : source_color = vec4(0.025,0.06,0.085,1);
uniform float motion = 1.0;
void vertex() {
    float weight=UV.y*UV.y;
    VERTEX.z += sin(TIME*1.9+UV.x*7.0+UV.y*3.0)*0.025*weight*motion;
    VERTEX.x += sin(TIME*1.1+UV.y*5.0)*0.012*weight*motion;
}
void fragment() {
    float weave=sin(UV.x*1100.0)*sin(UV.y*1700.0)*0.035;
    float hem=step(UV.x,0.035)+step(0.965,UV.x)+step(0.97,UV.y);
    ALBEDO=mix(cloth_color.rgb*(0.85+weave),vec3(0.32,0.21,0.09),clamp(hem,0.0,1.0));
    ROUGHNESS=0.91;
}
