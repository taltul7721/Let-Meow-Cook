shader_type canvas_item;
uniform float r_multiplier = 0.2126;
uniform float g_multiplier = 0.7152;
uniform float b_multiplier = 0.0722;
uniform float easing_threshold = 0.0031308;
uniform float pre_threshold_multiplier = 12.92;
uniform float post_threshold_multiplier = 1.055;
uniform float ease = 1;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 original = texture(screen_texture, UV);
	float linear = r_multiplier * original.r + g_multiplier * original.g + b_multiplier * original.b;
	if (linear <= easing_threshold) {
		COLOR = mix(original, vec4(pre_threshold_multiplier * linear), ease);
	}
	else {
		COLOR = mix(original, vec4(post_threshold_multiplier * pow(linear, 1.0/2.4) - 0.055), ease);
	}
}
