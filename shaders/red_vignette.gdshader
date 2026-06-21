shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.78, 0.04, 0.08, 1.0);

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered * vec2(1.12, 1.0));
	float edge = smoothstep(0.28, 0.92, dist);
	COLOR = vec4(vignette_color.rgb, edge * intensity * vignette_color.a);
}
