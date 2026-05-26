shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 albedo : source_color = vec3(0.02, 0.38, 0.52);
uniform vec3 albedo2 : source_color = vec3(0.11, 0.27, 0.39);
uniform vec3 color_deep : source_color = vec3(0.0, 0.18, 0.30);
uniform vec3 color_shallow : source_color = vec3(0.0, 0.42, 0.56);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float water_alpha : hint_range(0.0, 1.0) = 0.85;

uniform float wave_height : hint_range(0.0, 0.5) = 0.12;
uniform float wave_freq : hint_range(0.5, 5.0) = 2.0;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float wave = sin(v_world_pos.x * wave_freq + TIME * 2.0) * 0.5
		       + cos(v_world_pos.z * wave_freq * 0.8 + TIME * 1.5) * 0.5
		       + sin((v_world_pos.x + v_world_pos.z) * wave_freq * 0.6 + TIME * 1.0) * 0.3;
	wave /= 1.3;
	VERTEX.y += wave * wave_height;
}

void fragment() {
	// Fresnel reflection
	float fn = pow((1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0)), 5.0);
	vec3 surface_color = mix(albedo, albedo2, fn);

	// Height-based depth proxy
	float h = abs(sin(v_world_pos.x * 0.02 + v_world_pos.z * 0.015)) * 0.5 + 0.5;
	vec3 depth_color = mix(color_shallow, color_deep, h);

	// Sparkle
	float sparkle = max(0.0, sin(v_world_pos.x * 3.0 + v_world_pos.z * 2.0 + TIME * 3.0)) * 0.1;

	vec3 col = surface_color + depth_color * 0.5 + sparkle;
	col = clamp(col, vec3(0.0), vec3(1.0));

	ALBEDO = col;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	ALPHA = water_alpha;
}
