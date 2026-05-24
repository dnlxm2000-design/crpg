shader_type spatial;

uniform vec3 color_grass : source_color = vec3(0.35, 0.55, 0.20);
uniform vec3 color_rock  : source_color = vec3(0.55, 0.50, 0.42);
uniform vec3 color_sand  : source_color = vec3(0.72, 0.65, 0.48);

uniform float lineThickness = 0.02;
uniform float lineVisibility = 0.3;

void vertex() {
}

void fragment() {
	float lines = 1.;
	float upperLineThreshold = (1. - lineThickness);
	if (UV.x < lineThickness || UV.x > upperLineThreshold || UV.y < lineThickness || UV.y > upperLineThreshold) {
		lines = 1. - lineVisibility;
	}

	// Vertex color selects terrain type: R=rock, G=sand, default=grass
	vec3 col = color_grass * (1.0 - COLOR.r - COLOR.g - COLOR.b)
	         + color_rock  * COLOR.r
	         + color_sand  * COLOR.g;

	ALBEDO = col * lines;
}
