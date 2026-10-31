shader_type canvas_item;
// The paint picture is tiny and stretched with smoothing. Each pixel's alpha
// is how much of it is painted, so the halfway line is the stroke's edge:
// sharpen it there for a crisp round edge instead of a blur.

uniform sampler2D paint : filter_linear, repeat_disable;

void fragment() {
	vec4 colour = texture(paint, UV);
	float edge = smoothstep(0.42, 0.58, colour.a);
	// Colours are stored premultiplied by alpha, so undo that
	COLOR = vec4(colour.rgb / max(colour.a, 0.001), edge * COLOR.a);
}
