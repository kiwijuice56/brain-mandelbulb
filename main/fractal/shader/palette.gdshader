shader_type canvas_item;
// https://godotshaders.com/shader/palette-shader-lospec-compatible/

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D palette: source_color, filter_nearest; // Insert a palette from lospec for instance
uniform int palette_size = 13;
uniform float x = 0.0;

void fragment() { 
	vec4 color = texture(screen_texture, SCREEN_UV);
	vec4 original_color = color;
	color *= COLOR.a;
	
	float index = max(1.0, round(color.r * 255.0 / 19.0));
	float width = 1.0 / float(palette_size);
	
	COLOR = texture(palette, vec2(width * index + width / 2.0, 0.5));
	COLOR.a = floor(original_color.a);
}