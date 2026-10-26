shader_type canvas_item;
// Blurs and lightens whatever is behind it, for the pause screen.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform vec4 wash_colour : source_color = vec4(1.0, 0.97, 0.9, 1.0);

void fragment() {
	vec4 blurred = textureLod(screen_texture, SCREEN_UV, 3.0 * amount);
	COLOR = vec4(mix(blurred.rgb, wash_colour.rgb, 0.35 * amount), 1.0);
}
