shader_type spatial;

//Water Parameters
uniform float speed = 0.05;
uniform float height_scale = .5;
uniform vec2 wave1_dir = vec2(1.0, 0.0);
uniform vec2 wave2_dir = vec2(0.0, 2.0);

//Colors
uniform vec3 water_color_shallow : source_color;
uniform vec3 water_color_deep : source_color;
uniform vec3 foam_color : source_color;

//Settings to adjust water
uniform float wave_mix_factor = 0.75;
uniform float height_mix_factor = 0.75;
uniform float metallic = 0.0;
uniform float roughness = 0.2;
uniform float noise_scale = 10.0;
uniform float deep = 100.0;
uniform float shallow = 0.1;



//Textures for the water
uniform sampler2D water_texture1;
uniform sampler2D water_texture2;

//Textures for height of water
uniform sampler2D height_texture1;
uniform sampler2D height_texture2;

//Texture for foam
uniform sampler2D foam_texture;
uniform sampler2D foam_texture2;

//Texture for depth
uniform sampler2D depth_texture : hint_depth_texture;

//Varying height variable and world position
varying float wave_height;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 height_blend = mix(texture(height_texture1, world_pos.xz / noise_scale + TIME / speed), texture(height_texture2, world_pos.xz / noise_scale + TIME / speed), height_mix_factor);
	VERTEX.y += height_blend.y * height_scale;
	wave_height = height_blend.y;
}

void fragment() {
	vec3 normal_blend = mix(texture(water_texture1, world_pos.xz / noise_scale + (TIME * wave1_dir) / speed).rgb, texture(water_texture2, world_pos.xz + TIME / speed * wave2_dir).rgb, wave_mix_factor);


	vec3 foam_text = mix(texture(foam_texture, world_pos.xz / noise_scale).rgb, texture(foam_texture2, world_pos.xz / noise_scale).rgb, 0.5);

	float foam = smoothstep(0.8, 0.99, wave_height);

	vec2 uv = SCREEN_UV;
	float screen_depth = texture(depth_texture, uv).r;
	float real_depth = FRAGCOORD.z / FRAGCOORD.w;
	float depth_diff = clamp((screen_depth - real_depth) * 10.0, 0.0, 1.0);

	vec3 new_water_color = mix(water_color_shallow, water_color_deep, .25);

	//ALBEDO = mix(water_color_shallow, foam_color, foam);
	ALBEDO = mix(new_water_color, foam_color, smoothstep(0.6, 0.9, wave_height));
	//ALBEDO = mix(water_color_shallow, step(wave_height + 0.2, foam_text), 0.25);

	float newDepth = SCREEN_UV.g;
	ALPHA = 1.0;
	NORMAL = normal_blend;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}