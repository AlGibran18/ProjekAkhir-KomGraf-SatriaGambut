// Keep the emitter's scale while turning the particle toward the camera.
varying float age;
varying float seed;

void face_camera(inout vec3 vertex, mat4 model, mat4 view, inout mat4 modelview) {
	vertex *= vec3(length(model[0].xyz), length(model[1].xyz), length(model[2].xyz));
	modelview = mat4(vec4(1,0,0,0), vec4(0,1,0,0), vec4(0,0,1,0), view * model[3]);
}
