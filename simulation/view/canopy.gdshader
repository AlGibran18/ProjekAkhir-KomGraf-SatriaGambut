shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform sampler2D leaves : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 wind = vec2(0.5, 0.0);

void vertex() {
	float crown = smoothstep(0.6, 4.0, VERTEX.y - MODEL_MATRIX[3].y);
	float gust = sin(dot(VERTEX.xz, vec2(0.48, 0.27)) + TIME * 1.7);
	float flutter = sin(VERTEX.y * 4.6 + TIME * 3.5 + VERTEX.x);
	VERTEX.xz += wind * crown * (0.085 * gust + 0.021 * flutter);
}

void fragment() {
	vec4 leaf = texture(leaves, UV);
	ALBEDO = leaf.rgb * COLOR.rgb;
	ALPHA = leaf.a;
	ALPHA_SCISSOR_THRESHOLD = 0.2;
	ROUGHNESS = 0.83;
	BACKLIGHT = leaf.rgb * 0.24;
}
