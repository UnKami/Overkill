shader_type canvas_item;
render_mode unshaded;
void fragment() {
    vec4 scene = texture(TEXTURE, UV);
    float luminance = dot(scene.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 color = mix(vec3(luminance), scene.rgb, 0.90);
    color *= mix(vec3(0.92, 0.98, 1.04), vec3(1.04, 1.00, 0.94), smoothstep(0.08, 0.75, luminance));
    vec2 centered = UV - vec2(0.5, 0.45);
    float vignette = smoothstep(0.22, 0.70, length(centered * vec2(1.0, 0.8)));
    COLOR = vec4(color * (1.0 - vignette * 0.25), scene.a);
}
