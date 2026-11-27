shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec2 ground;
varying float moisture;
varying float field_view;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(27.17, 91.71))) * 4375.17);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), u.x), u.y);
}

void vertex() {
	ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	moisture = INSTANCE_CUSTOM.r;
	field_view = INSTANCE_CUSTOM.g;
}

void fragment() {
	float hummocks = noise2(ground * 1.4);
	float fibers = noise2(ground * vec2(19.0, 7.0));
	float pools = smoothstep(0.27, 0.64, moisture - hummocks * 0.32) * field_view;
	float shade = 0.76 + 0.28 * hummocks + 0.16 * fibers;
	ALBEDO = COLOR.rgb * mix(1.0, shade, field_view);
	ROUGHNESS = mix(0.95, 0.19, pools);
	SPECULAR = mix(0.18, 0.78, pools);
}
