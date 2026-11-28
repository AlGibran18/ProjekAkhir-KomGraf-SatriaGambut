shader_type spatial;
render_mode cull_disabled, shadows_disabled;
#include "particle_card.gdshaderinc"

void vertex() {
	age = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0);
	vec2 travel = (VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xy;
	face_camera(VERTEX, MODEL_MATRIX, VIEW_MATRIX, MODELVIEW_MATRIX);
	float projected = length(travel);
	vec2 up = projected > 0.001 ? travel / projected : vec2(0.0, 1.0);
	VERTEX.y *= clamp(projected, 0.24, 1.0);
	VERTEX.xy = vec2(up.y, -up.x) * VERTEX.x + up * VERTEX.y;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x *= 1.0 + p.y * 0.27;
	float r2 = dot(p,p);
	float rim = smoothstep(0.30,0.94,r2);
	float glint = exp(-16.0 * dot(p + vec2(0.28,0.32),p + vec2(0.28,0.32)));
	ALBEDO = mix(vec3(0.38,0.59,0.65), vec3(0.91,0.98,1.0), rim * 0.53 + glint * 0.44);
	NORMAL = normalize(vec3(p.x, -p.y, sqrt(max(0.02,1.0-r2))));
	ROUGHNESS = mix(0.07, 0.24, age);
	SPECULAR = 0.92;
	ALPHA = COLOR.a * (0.35 + rim * 0.38 + glint * 0.26) * (1.0 - smoothstep(0.68,1.0,r2))
		* (1.0 - smoothstep(0.70,1.0,age)) * mix(0.70, 1.0, rim);
}
