shader_type canvas_item;

uniform sampler2D from_tex : source_color;
uniform sampler2D to_tex : source_color;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float density = 36.0;
uniform float boundary_size : hint_range(0.01, 1.0) = 0.6;
uniform float antialiasing_intensity : hint_range(0.1, 8.0) = 2.0;

float modulus(float a, float b) {
	return a - b * floor(a / b);
}

vec2 axial_round(vec2 fractional_axial) {
	float fractional_q = fractional_axial.x;
	float fractional_r = fractional_axial.y;
	float fractional_s = -fractional_q - fractional_r;

	float whole_q = round(fractional_q);
	float whole_r = round(fractional_r);
	float whole_s = round(fractional_s);

	float q_diff = abs(fractional_q - whole_q);
	float r_diff = abs(fractional_r - whole_r);
	float s_diff = abs(fractional_s - whole_s);

	float q = whole_q;
	float r = whole_r;

	if (q_diff > r_diff && q_diff > s_diff) {
		q = -whole_r - whole_s;
	} else if (r_diff > s_diff) {
		r = -whole_q - whole_s;
	}

	return vec2(q, r);
}

vec2 axial_to_cartesian(vec2 axial, float grid_scale) {
	float x = (sqrt(3.0) * axial.x + sqrt(3.0) * 0.5 * axial.y) / grid_scale;
	float y = (1.5 * axial.y) / grid_scale;
	return vec2(x, y);
}

vec2 cartesian_to_fractional_axial(vec2 cartesian, float grid_scale) {
	float q = ((cartesian.x / sqrt(3.0)) - (cartesian.y / 3.0)) * grid_scale;
	float r = (2.0 * cartesian.y / 3.0) * grid_scale;
	return vec2(q, r);
}

vec2 cartesian_to_whole_axial(vec2 cartesian, float grid_scale) {
	return axial_round(cartesian_to_fractional_axial(cartesian, grid_scale));
}

void fragment() {
	vec2 uv = UV;

	vec2 centered_uv = uv - vec2(0.5);
	centered_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	centered_uv += vec2(0.5);

	vec2 cell_center_axial = cartesian_to_whole_axial(centered_uv, density);
	vec2 cell_center = axial_to_cartesian(cell_center_axial, density);

	float cell_radius = 1.0 / density;
	float dist_from_cell_center = distance(cell_center, centered_uv);

	float timer = progress * PI * 2.0;
	float flip = step(sin(timer + centered_uv.x), 0.0);

	float oscillator = cos(timer + centered_uv.x) * (1.0 / boundary_size);
	float distance_threshold = mix(0.0, cell_radius, oscillator);

	float proximity = (distance_threshold - dist_from_cell_center) * density;
	float flipped_proximity = ((-distance_threshold) - dist_from_cell_center) * density;
	proximity = mix(proximity, flipped_proximity, flip);

	float pixel_scale = 1.0 / SCREEN_PIXEL_SIZE.x;
	float scaled_proximity = proximity * pixel_scale / density / antialiasing_intensity;

	float mask_a = smoothstep(0.0, 1.0, scaled_proximity);
	float mask = mix(mask_a, 1.0 - mask_a, flip);

	vec4 from_col = texture(from_tex, uv);
	vec4 to_col = texture(to_tex, uv);

	COLOR = mix(from_col, to_col, mask);
}