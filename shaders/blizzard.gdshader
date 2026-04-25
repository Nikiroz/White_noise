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

highp vec2 hash22(highp vec2 p) {
	p = vec2(
		dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3))
	);

	return -1.0 + 2.0 * fract(p * 0.3183099 + vec2(0.1, 0.7));
}

highp float noise(highp vec2 p) {
	highp vec2 i = floor(p);
	highp vec2 f = fract(p);

	highp vec2 u = f * f * (3.0 - 2.0 * f);

	highp float a = dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
	highp float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	highp float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	highp float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 0.5 + 0.5;
}

highp float fbm(highp vec2 p) {
	highp float value = 0.0;
	highp float amplitude = 0.5;
	highp float frequency = 1.0;

	for (int i = 0; i < 8; i++) {
		if (i >= octaves) {
			break;
		}

		value += noise(p * frequency) * amplitude;
		frequency *= 2.0;
		amplitude *= 0.5;
	}

	return clamp(value, 0.0, 1.0);
}

void fragment() {
	highp vec2 dir = normalize(direction);
	highp vec2 moving_uv = UV * noise_scale - dir * TIME * speed;

	highp float n = fbm(moving_uv);

	vec4 noise_color = mix(noise_dark_color, noise_bright_color, n);
	vec4 final_color = mix(base_color, noise_color, noise_strength);

	float alpha = mix(alpha_min, alpha_max, n);

	COLOR = vec4(final_color.rgb, alpha * base_color.a);
}