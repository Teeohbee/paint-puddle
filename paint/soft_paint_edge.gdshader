shader_type canvas_item;
// The paint picture is tiny and stretched with smoothing. Each pixel's alpha
// is how much of it is painted, so the halfway line is the stroke's edge:
// sharpen it there for a crisp round edge instead of a blur.
//
// Just inside the edge the paint is a little darker, like the rim a real
// brush stroke dries with. White paint needs it to show on the paper.

uniform sampler2D paint : filter_linear, repeat_disable;
uniform float rim_darkness = 0.14;

void fragment() {
	vec4 colour = texture(paint, UV);
	float edge = smoothstep(0.42, 0.58, colour.a);
	// Colours are stored premultiplied by alpha, so undo that
	vec3 unpremultiplied = colour.rgb / max(colour.a, 0.001);
	float rim = 1.0 - smoothstep(0.5, 0.95, colour.a);
	COLOR = vec4(unpremultiplied * (1.0 - rim_darkness * rim), edge * COLOR.a);
}
