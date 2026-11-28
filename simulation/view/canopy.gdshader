shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform sampler2D leaves : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 wind = vec2(0.5, 0.0);

varying vec3 leaf_position;
uniform float wetness = 0.0;

void vertex() {
	leaf_position = VERTEX;
	float crown = smoothstep(0.6, 4.0, VERTEX.y - MODEL_MATRIX[3].y);
	float gust = sin(dot(VERTEX.xz, vec2(0.48, 0.27)) + TIME * 1.7);
	float flutter = sin(VERTEX.y * 4.6 + TIME * 3.5 + VERTEX.x);
	VERTEX.xz += wind * crown * (0.085 * gust + 0.021 * flutter);
}

void fragment() {
	vec4 leaf = texture(leaves, UV);
	float shade = sin(dot(leaf_position.xz, vec2(1.31, 0.77)) + sin(leaf_position.y * 1.75));
	ALBEDO = leaf.rgb * COLOR.rgb * mix(vec3(0.78,0.89,0.73), vec3(1.05,1.02,0.87), shade * 0.5 + 0.5);
	ALBEDO *= 1.0 - 0.13 * wetness;
	ALPHA = leaf.a;
	ALPHA_SCISSOR_THRESHOLD = 0.2;
	ROUGHNESS = mix(0.81, 0.30, wetness);
	SPECULAR = mix(0.26, 0.59, wetness);
	BACKLIGHT = leaf.rgb * 0.24;
}
