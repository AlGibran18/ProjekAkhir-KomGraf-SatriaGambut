shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D litter : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grain : filter_linear_mipmap, repeat_enable;
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
	vec2 uv = ground * 0.45;
	vec3 forest = texture(litter, uv).rgb;
	vec3 moisture_tint = mix(vec3(1.14,1.06,0.93), vec3(0.57,0.67,0.64), moisture);
	float shade = 0.85 + hummocks * 0.25 + fibers * 0.08;
	ALBEDO = mix(COLOR.rgb, forest * moisture_tint * shade * (0.77 + COLOR.rgb), field_view);
	NORMAL_MAP = mix(vec3(0.5,0.5,1.0), texture(relief, uv).rgb, field_view);
	NORMAL_MAP_DEPTH = mix(0.82, 0.22, pools);
	ROUGHNESS = mix(0.96, mix(texture(grain, uv).r, 0.13, pools), field_view);
	SPECULAR = mix(0.18, 0.84, pools);
}
