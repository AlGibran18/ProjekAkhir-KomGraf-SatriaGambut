shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled, cull_disabled;
#include "particle_card.gdshaderinc"
#include "plume_noise.gdshaderinc"

void vertex() {
	age = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0);
	seed = fract(float(INSTANCE_ID) * 0.618034);
	face_camera(VERTEX, MODEL_MATRIX, VIEW_MATRIX, MODELVIEW_MATRIX);
	VERTEX.xy *= mix(0.62, 1.85, age);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	vec2 p = uv * 2.9 + vec2(seed * 23.0, age * 1.6);
	float n = turbulence(p + turbulence(p * 0.65)) * 0.72 + turbulence(p * 2.1) * 0.28;
	float density = 1.0 - length(uv) + (n - 0.55) * 0.75;
	ALBEDO = COLOR.rgb * mix(0.47, 1.12, clamp(n + age * 0.30 - uv.y * 0.14, 0.0, 1.0));
	NORMAL = normalize(vec3(uv.x * 0.65, -uv.y * 0.65, 0.55 + density));
	ROUGHNESS = 1.0;
	BACKLIGHT = ALBEDO * 0.34;
	ALPHA = COLOR.a * smoothstep(0.09,0.70,density) * smoothstep(0.0,0.14,age)
		* (1.0 - smoothstep(0.4,1.0,age));
}
