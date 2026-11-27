shader_type sky;

void sky() {
	float height = max(EYEDIR.y, 0.0);
	vec3 horizon = vec3(0.83, 0.76, 0.61);
	vec3 zenith = vec3(0.27, 0.56, 0.76);
	vec3 atmosphere = mix(horizon, zenith, smoothstep(0.0, 0.85, height));
	if (LIGHT0_ENABLED) {
		float facing = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		atmosphere += LIGHT0_COLOR * (0.22 * pow(facing, 18.0) + 0.70 * smoothstep(0.9994, 0.99992, facing));
	}
	COLOR = atmosphere;
}
