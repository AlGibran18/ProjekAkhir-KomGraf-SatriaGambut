shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

varying float age;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	VERTEX.xz *= mix(0.18,1.0,age);
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float ring = 1.0 - smoothstep(0.02,0.13,abs(r - 0.84));
	ALBEDO = vec3(0.70,0.80,0.85);
	ALPHA = ring * COLOR.a * (1.0 - age);
}
