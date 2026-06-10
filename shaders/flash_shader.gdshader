shader_type canvas_item;

uniform vec4 flash_color : source_color;
uniform vec4 bounds = vec4(0.0);
uniform float flash_percent: hint_range(0.0,1.0) = 0;

void fragment() {
	vec2 uv = UV;
	if (uv.x < bounds.x || uv.x > bounds.y || uv.y < bounds.z || uv.y > bounds.w) {
		vec4 original_color = texture(TEXTURE, UV);
		vec4 mixed = mix(original_color, flash_color, flash_percent / 2.0);
		mixed.a = original_color.a;
		COLOR = mixed;
	} 
}