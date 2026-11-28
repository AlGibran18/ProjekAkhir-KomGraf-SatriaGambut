shader_type sky;

uniform sampler2D panorama : filter_linear_mipmap, repeat_enable;
uniform float overcast : hint_range(0.0, 1.0);

void sky() {
	vec3 sky_color = texture(panorama, SKY_COORDS).rgb;
	// Compress the photographed sun so the scene light controls its direction.
	sky_color = sky_color / (0.84 + sky_color);
	float luma = dot(sky_color, vec3(0.2126, 0.7152, 0.0722));
	vec3 clouds = vec3(0.57, 0.64, 0.69) * (0.35 + 0.67 * luma);
	COLOR = mix(sky_color, clouds, overcast * 0.86);
	if (LIGHT0_ENABLED) {
		float mu = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		COLOR += LIGHT0_COLOR * (pow(mu, 36.0) * 0.14 + smoothstep(0.9997, 0.99997, mu)) * (1.0 - overcast);
	}
}
