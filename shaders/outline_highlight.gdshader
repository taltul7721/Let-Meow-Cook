shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.92, 0.2, 1.0);
uniform float outline_width : hint_range(0.0, 12.0) = 2.5;
uniform bool enabled = false;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = tex;

	if (!enabled || tex.a < 0.01) {
		return;
	}

	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
	float neighbor_alpha = tex.a;
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);

	if (tex.a < 0.45 && neighbor_alpha > 0.45) {
		COLOR = outline_color;
		COLOR.a = outline_color.a;
	}
}
