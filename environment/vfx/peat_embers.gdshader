shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
#include "plume_noise.gdshaderinc"

uniform bool thermal = false;
varying vec2 location;

void vertex() {
	location = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float fade = 1.0 - smoothstep(0.36, 0.99, length(p));
	float crust = turbulence(location * 4.3 + turbulence(location * 1.9));
	float seam = 1.0 - smoothstep(0.018, 0.105, abs(crust - 0.51));
	float breath = 0.84 + 0.16 * sin(TIME * 1.9 + crust * 8.0);
	float hot = thermal ? 0.45 + seam * 0.55 : seam;
	ALBEDO = mix(vec3(0.48,0.044,0.008), vec3(1.0,0.54,0.09), hot * breath);
	ALPHA = fade * hot * (thermal ? 0.92 : 0.69);
}
