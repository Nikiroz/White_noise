shader_type canvas_item;

uniform bool enabled = true;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int type : hint_range(0, 2) = 2;
uniform float thickness = 1.0;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

const vec2[8] DIRECTIONS = {
	vec2(1.0, 0.0),
	vec2(0.0, 1.0),
	vec2(-1.0, 0.0),
	vec2(0.0, -1.0),
	vec2(1.0, 1.0),
	vec2(-1.0, 1.0),
	vec2(-1.0, -1.0),
	vec2(1.0, -1.0)
};

float gtz(float input) { return max(0.0, sign(input)); }

float check(sampler2D tex, vec2 from, vec2 size) {
	float result = 0.0;
	for (int i = 0; i < 4 * type; i++) {
		result += texture(tex, from + DIRECTIONS[i] * size * thickness).a;
	}
	return gtz(result);
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Базовый цвет: оригинальная текстура
	vec4 col = tex_color;

	// Обводка только по прозрачным пикселям рядом с непрозрачными
	float edge = check(TEXTURE, UV, TEXTURE_PIXEL_SIZE) * (1.0 - gtz(tex_color.a)) * intensity;
	col = mix(col, outline_color, edge);

	// Переключатель эффекта
	COLOR = mix(tex_color, col, enabled ? 1.0 : 0.0);
}