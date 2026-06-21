shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.35;
uniform float smoothness : hint_range(0.0, 0.5) = 0.08;

void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float diff = distance(sample_color.rgb, key_color);
	float alpha = smoothstep(threshold, threshold + smoothness, diff);
	COLOR = vec4(sample_color.rgb, sample_color.a * alpha);
}
