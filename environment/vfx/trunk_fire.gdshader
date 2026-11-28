shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
#include "plume_noise.gdshaderinc"

varying vec3 cylinder_position;
varying float phase;

void vertex() {
	cylinder_position = VERTEX;
	phase = dot(MODEL_MATRIX[3].xz, vec2(0.53, 0.37));
	float sway = sin(TIME * 3.0 + phase + VERTEX.y * 3.3);
	VERTEX.x += sway * pow(1.0 - UV.y, 2.0) * 0.18;
}

void fragment() {
	float h = 1.0 - UV.y;
	vec2 circle = normalize(cylinder_position.xz);
	vec2 drift = vec2(phase, h * 4.1 - TIME * 2.4);
	float curl = turbulence(circle * 2.2 + drift);
	float wisps = turbulence(circle * 6.5 + drift * 2.4);
	float frontier = 0.24 + 0.59 * curl + 0.17 * wisps;
	float body = frontier - h;
	float heat = smoothstep(0.0, 0.55, body) * (0.55 + wisps * 0.45);
	ALBEDO = mix(vec3(0.86,0.14,0.018), vec3(1.0,0.78,0.28), heat);
	ALPHA = smoothstep(0.0,0.16,body) * smoothstep(0.02,0.14,h)
		* smoothstep(0.24,0.65,curl * 0.72 + wisps * 0.28);
}
