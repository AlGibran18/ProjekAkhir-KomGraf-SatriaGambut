shader_type spatial;
render_mode cull_disabled, shadows_disabled;

varying float age;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	VERTEX.xz *= mix(0.18,1.0,age);
}

void fragment() {
	vec2 xy = UV * 2.0 - 1.0;
	float r = length(xy);
	float ring = 1.0 - smoothstep(0.02,0.13,abs(r - 0.84));
	float slope = sin((r - 0.84) * 30.0) * (1.0 - age);
	NORMAL_MAP = normalize(vec3(xy * slope, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.11;
	SPECULAR = 0.90;
	ALBEDO = vec3(0.46,0.57,0.59);
	ALPHA = ring * COLOR.a * (1.0 - age);
}
