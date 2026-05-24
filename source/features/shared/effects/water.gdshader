shader_type spatial;
render_mode cull_back;

uniform vec3 color_shallow : source_color = vec3(0.25, 0.55, 0.75);
uniform vec3 color_deep : source_color = vec3(0.05, 0.15, 0.35);
uniform float wave_speed : hint_range(0.0, 0.2) = 0.03;
uniform float wave_height : hint_range(0.0, 0.5) = 0.08;
uniform float wave_freq : hint_range(0.5, 5.0) = 2.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.15;

varying float v_height;
varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Simple noise-like wave using sin combination
	float wave = sin(v_world_pos.x * wave_freq + TIME * 2.0) * 0.5
		       + cos(v_world_pos.z * wave_freq * 0.8 + TIME * 1.5) * 0.5
		       + sin((v_world_pos.x + v_world_pos.z) * wave_freq * 0.6 + TIME * 1.0) * 0.3;
	wave /= 1.3;
	v_height = wave;
	VERTEX.y += wave * wave_height;
}

void fragment() {
	// Fresnel: more reflection at glancing angles
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);

	// Depth blend: shore vs deep water
	float depth = 1.0 - abs(v_height);
	depth = clamp(depth * 2.0, 0.0, 1.0);
	vec3 water_col = mix(color_deep, color_shallow, depth);

	// Wave sparkle
	float sparkle = max(0.0, sin(v_world_pos.x * 3.0 + v_world_pos.z * 2.0 + TIME * 3.0)) * 0.15;

	// Combine
	vec3 col = water_col + sparkle;
	col = mix(col, vec3(1.0), fresnel * 0.15);

	ALBEDO = col;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
