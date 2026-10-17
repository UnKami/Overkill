shader_type canvas_item;
uniform vec4 status_color : source_color = vec4(0.718,0.424,1.0,1.0);
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float brightness = max(dot(source.rgb, vec3(0.299,0.587,0.114)),0.4);
    COLOR = vec4(status_color.rgb * brightness, source.a) * vertex_tint;
}
