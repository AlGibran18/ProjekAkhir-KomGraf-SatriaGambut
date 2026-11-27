float lattice(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float turbulence(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 w = f * f * (3.0 - 2.0 * f);
	return mix(mix(lattice(i), lattice(i + vec2(1,0)), w.x),
		mix(lattice(i + vec2(0,1)), lattice(i + vec2(1)), w.x), w.y);
}
