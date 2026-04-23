shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);

uniform vec4 noise_dark_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 noise_bright_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float noise_scale = 8.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.5;

uniform float alpha_min : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_max : hint_range(0.0, 1.0) = 1.0;

uniform float speed = 0.25;
uniform vec2 direction = vec2(1.0, 0.0);

uniform int octaves = 4;

// pseudo-random
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// smooth value noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		(c - a) * u.y * (1.0 - u.x) +
		(d - b) * u.x * u.y;
}

// fractal noise, похож на Perlin/fBm
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int i = 0; i < 8; i++) {
		if (i >= octaves) {
			break;
		}

		value += noise(p * frequency) * amplitude;
		frequency *= 2.0;
		amplitude *= 0.5;
	}

	return value;
}

void fragment() {
	vec2 dir = normalize(direction);
	vec2 moving_uv = UV * noise_scale - dir * TIME * speed;

	float n = fbm(moving_uv);

	vec4 noise_color = mix(noise_dark_color, noise_bright_color, n);
	vec4 final_color = mix(base_color, noise_color, noise_strength);

	float alpha = mix(alpha_min, alpha_max, n);

	COLOR = vec4(final_color.rgb, alpha * base_color.a);
}