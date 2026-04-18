shader_type canvas_item;

uniform float fade : hint_range(0.0, 1.0) = 1.0; // 1 = видно, 0 = прозрачно

void fragment() {
    vec4 c = texture(TEXTURE, UV);

    // учитываем tint/modulate TextureRect
    c *= COLOR;

    c.a *= fade;
    COLOR = c;
}