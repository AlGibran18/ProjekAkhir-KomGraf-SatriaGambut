shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
#include "particle_card.gdshaderinc"
#include "plume_noise.gdshaderinc"

void vertex() {
	age = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0);
	seed = fract(float(INSTANCE_ID) * 0.618034);
	face_camera(VERTEX, MODEL_MATRIX, VIEW_MATRIX, MODELVIEW_MATRIX);
	VERTEX.xy *= mix(1.05, 0.62, age);
}

void fragment() {
	float h = 1.0 - UV.y;
	vec2 p = vec2(UV.x * 3.7 + seed * 19.0, h * 3.2 - TIME * 2.6);
	float eddy = turbulence(p) * 0.68 + turbulence(p * 2.3) * 0.32;
	float axis = (UV.x - 0.5) * 2.0 + (eddy - 0.5) * h * 0.85;
	float body = 1.0 - abs(axis) / max(0.08, 0.93 - 0.75 * h) - h * 0.94 + (eddy - 0.5) * 0.95;
	float heat = clamp(body * 1.6, 0.0, 1.0);
	ALBEDO = mix(mix(vec3(0.77,0.076,0.012), vec3(1.0,0.47,0.036), heat),
		vec3(1.0,0.90,0.49), smoothstep(0.60,1.0,heat));
	ALPHA = smoothstep(0.0,0.32,body) * smoothstep(0.0,0.14,h)
		* smoothstep(0.0,0.09,age) * (1.0 - smoothstep(0.62,1.0,age));
}
