class_name MenuIcons
extends RefCounted
## Little pictures for menu tiles, drawn in code. Each fits in a square of
## the given size around the centre.

static func draw_icon(canvas: CanvasItem, kind: String, centre: Vector2, size: float, colour: Color) -> void:
	if kind.begins_with("text:"):
		draw_big_text(canvas, kind.trim_prefix("text:"), centre, size, colour)
		return
	if kind.begins_with("colour_set:"):
		draw_three_paints(canvas, kind.trim_prefix("colour_set:"), centre, size, colour)
		return
	match kind:
		"play", "resume": draw_play(canvas, centre, size, colour)
		"options": draw_cog(canvas, centre, size, colour)
		"quit": draw_door(canvas, centre, size, colour)
		"meadow": draw_flower(canvas, centre, size, colour)
		"paint": draw_brush(canvas, centre, size, colour)
		"splat": draw_splat(canvas, centre, size, colour)
		"hills": draw_hills(canvas, centre, size, colour)
		"map": draw_globe(canvas, centre, size, colour)
		"restart": draw_restart(canvas, centre, size, colour)
		"home": draw_house(canvas, centre, size, colour)
		"back": draw_back_arrow(canvas, centre, size, colour)
		"book": draw_book(canvas, centre, size, colour)
		"more": draw_more_arrow(canvas, centre, size, colour)
		"music": draw_music_note(canvas, centre, size, colour)
		"sound": draw_speaker(canvas, centre, size, colour)
		"speed": draw_snail(canvas, centre, size, colour)
		"gap": draw_gap(canvas, centre, size, colour)
		"jump": draw_jump_arc(canvas, centre, size, colour)
		"reset": draw_bin(canvas, centre, size, colour)
		"controller": draw_controller(canvas, centre, size, colour)
		"players":
			draw_controller(canvas, centre + Vector2(-size * 0.2, -size * 0.12), size * 0.7, colour)
			draw_controller(canvas, centre + Vector2(size * 0.2, size * 0.14), size * 0.7, colour.lightened(0.25))


## Big chunky text in place of a picture, e.g. a level number.
static func draw_big_text(canvas: CanvasItem, text: String, centre: Vector2, size: float, colour: Color) -> void:
	var font: Font = canvas.get_tree().root.theme.default_font
	var font_size: int = int(size * 1.3)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, centre + Vector2(-width / 2.0, font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


## A colour set's three primaries as overlapping blobs, ringed in the icon colour.
static func draw_three_paints(canvas: CanvasItem, colour_set: String, centre: Vector2, size: float, colour: Color) -> void:
	var primaries: Array = PaintMixing.puddles_for(colour_set).slice(0, 3)
	for primary_index in primaries.size():
		var blob_centre: Vector2 = centre + Vector2.from_angle(TAU * primary_index / 3.0 - PI / 2.0) * size * 0.2
		canvas.draw_circle(blob_centre, size * 0.27, colour)
		canvas.draw_circle(blob_centre, size * 0.22, PaintMixing.colour_of(primaries[primary_index]))


static func draw_play(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	var half: float = size * 0.42
	var points: PackedVector2Array = PackedVector2Array([
		centre + Vector2(-half * 0.7, -half), centre + Vector2(half, 0), centre + Vector2(-half * 0.7, half)])
	canvas.draw_colored_polygon(points, colour)
	canvas.draw_polyline(points + PackedVector2Array([points[0]]), colour, size * 0.12, true)


static func draw_cog(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	for tooth_index in 8:
		var direction: Vector2 = Vector2.from_angle(TAU * tooth_index / 8.0)
		canvas.draw_line(centre + direction * size * 0.2, centre + direction * size * 0.46, colour, size * 0.17, true)
	canvas.draw_circle(centre, size * 0.33, colour)
	canvas.draw_circle(centre, size * 0.13, colour.darkened(0.45))


static func draw_door(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	var door: Rect2 = Rect2(centre - Vector2(size * 0.28, size * 0.45), Vector2(size * 0.56, size * 0.9))
	canvas.draw_rect(door, colour)
	canvas.draw_circle(centre + Vector2(size * 0.14, size * 0.05), size * 0.06, colour.darkened(0.45))
	canvas.draw_line(centre + Vector2(-size * 0.28, size * 0.45), centre + Vector2(size * 0.4, size * 0.45),
		colour, size * 0.06, true)


static func draw_flower(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_line(centre, centre + Vector2(0, size * 0.48), colour, size * 0.08, true)
	for petal_index in 5:
		var petal_centre: Vector2 = centre + Vector2.from_angle(TAU * petal_index / 5.0 - PI / 2.0) * size * 0.22 \
			- Vector2(0, size * 0.08)
		canvas.draw_circle(petal_centre, size * 0.16, colour)
	canvas.draw_circle(centre - Vector2(0, size * 0.08), size * 0.12, PaintColours.YELLOW)


## A globe: a ringed ball with a meridian, an equator and two land patches.
static func draw_globe(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	var radius: float = size * 0.4
	canvas.draw_circle(centre, radius, colour)
	canvas.draw_circle(centre, radius - size * 0.07, colour.lightened(0.55))
	canvas.draw_colored_polygon(PackedVector2Array([
		centre + Vector2(-0.26, -0.22) * size, centre + Vector2(-0.02, -0.3) * size, centre + Vector2(0.04, -0.12) * size,
		centre + Vector2(-0.1, 0.02) * size, centre + Vector2(-0.24, -0.04) * size]), colour)
	canvas.draw_colored_polygon(PackedVector2Array([
		centre + Vector2(0.1, 0.0) * size, centre + Vector2(0.28, -0.06) * size, centre + Vector2(0.26, 0.16) * size,
		centre + Vector2(0.12, 0.28) * size, centre + Vector2(0.04, 0.14) * size]), colour)


static func draw_brush(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	var along: Vector2 = Vector2(1, -1).normalized()
	var across: Vector2 = along.orthogonal()
	var tip: Vector2 = centre + Vector2(-size * 0.3, size * 0.3)
	var neck: Vector2 = tip + along * size * 0.28
	canvas.draw_line(neck, centre + Vector2(size * 0.42, -size * 0.42), colour, size * 0.12, true)
	canvas.draw_line(neck - along * size * 0.02, neck + along * size * 0.12, colour.darkened(0.3), size * 0.17, true)
	canvas.draw_colored_polygon(PackedVector2Array([
		neck + across * size * 0.1, neck - across * size * 0.1, tip - across * size * 0.03 - along * size * 0.04,
		tip + across * size * 0.03 - along * size * 0.04]), colour)
	canvas.draw_circle(tip + Vector2(-size * 0.04, size * 0.12), size * 0.06, colour)


## A splat: a big blob with droplets flung round it.
static func draw_splat(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_circle(centre, size * 0.26, colour)
	for droplet_index in 6:
		var direction: Vector2 = Vector2.from_angle(TAU * droplet_index / 6.0 + 0.4)
		var reach: float = size * (0.34 if droplet_index % 2 == 0 else 0.26)
		canvas.draw_circle(centre + direction * reach, size * (0.1 if droplet_index % 2 == 0 else 0.07), colour)
		canvas.draw_line(centre + direction * size * 0.2, centre + direction * (reach - size * 0.04), colour, size * 0.09, true)
	canvas.draw_circle(centre + Vector2(size * 0.02, -size * 0.04), size * 0.07, Color(1, 1, 1, 0.45))


static func draw_hills(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	draw_hill_top(canvas, centre + Vector2(-size * 0.18, size * 0.46), size * 0.34, colour)
	draw_hill_top(canvas, centre + Vector2(size * 0.24, size * 0.46), size * 0.26, colour)
	var pole_bottom: Vector2 = centre + Vector2(size * 0.22, size * 0.22)
	var pole_top: Vector2 = pole_bottom - Vector2(0, size * 0.62)
	canvas.draw_line(pole_bottom, pole_top, colour, size * 0.05, true)
	canvas.draw_colored_polygon(PackedVector2Array([pole_top, pole_top + Vector2(size * 0.3, size * 0.1),
		pole_top + Vector2(0, size * 0.2)]), colour)


static func draw_hill_top(canvas: CanvasItem, base_centre: Vector2, radius: float, colour: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in 17:
		points.append(base_centre + Vector2.from_angle(PI + PI * point_index / 16.0) * Vector2(radius, radius * 0.9))
	canvas.draw_colored_polygon(points, colour)


static func draw_restart(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_arc(centre, size * 0.32, -PI * 0.3, PI * 1.45, 32, colour, size * 0.12, true)
	var arrow_tip: Vector2 = centre + Vector2.from_angle(-PI * 0.3) * size * 0.32
	canvas.draw_colored_polygon(PackedVector2Array([arrow_tip + Vector2(-size * 0.2, -size * 0.06),
		arrow_tip + Vector2(size * 0.12, -size * 0.16), arrow_tip + Vector2(size * 0.06, size * 0.16)]), colour)


static func draw_house(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([centre + Vector2(-size * 0.46, -size * 0.02),
		centre + Vector2(0, -size * 0.44), centre + Vector2(size * 0.46, -size * 0.02)]), colour)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.32, -size * 0.04), Vector2(size * 0.64, size * 0.46)), colour)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.09, size * 0.14), Vector2(size * 0.18, size * 0.28)),
		colour.darkened(0.45))


static func draw_back_arrow(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_line(centre + Vector2(size * 0.38, 0), centre + Vector2(-size * 0.2, 0), colour, size * 0.16, true)
	canvas.draw_colored_polygon(PackedVector2Array([centre + Vector2(-size * 0.44, 0),
		centre + Vector2(-size * 0.08, -size * 0.32), centre + Vector2(-size * 0.08, size * 0.32)]), colour)


static func draw_more_arrow(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_line(centre + Vector2(-size * 0.38, 0), centre + Vector2(size * 0.2, 0), colour, size * 0.16, true)
	canvas.draw_colored_polygon(PackedVector2Array([centre + Vector2(size * 0.44, 0),
		centre + Vector2(size * 0.08, size * 0.32), centre + Vector2(size * 0.08, -size * 0.32)]), colour)


static func draw_music_note(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_circle(centre + Vector2(-size * 0.2, size * 0.28), size * 0.15, colour)
	canvas.draw_circle(centre + Vector2(size * 0.24, size * 0.18), size * 0.15, colour)
	canvas.draw_line(centre + Vector2(-size * 0.07, size * 0.28), centre + Vector2(-size * 0.07, -size * 0.36), colour, size * 0.07)
	canvas.draw_line(centre + Vector2(size * 0.37, size * 0.18), centre + Vector2(size * 0.37, -size * 0.46), colour, size * 0.07)
	canvas.draw_line(centre + Vector2(-size * 0.07, -size * 0.36), centre + Vector2(size * 0.37, -size * 0.46), colour, size * 0.14)


static func draw_speaker(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([centre + Vector2(-size * 0.42, -size * 0.12),
		centre + Vector2(-size * 0.22, -size * 0.12), centre + Vector2(0, -size * 0.34),
		centre + Vector2(0, size * 0.34), centre + Vector2(-size * 0.22, size * 0.12),
		centre + Vector2(-size * 0.42, size * 0.12)]), colour)
	canvas.draw_arc(centre + Vector2(size * 0.04, 0), size * 0.2, -0.8, 0.8, 12, colour, size * 0.07, true)
	canvas.draw_arc(centre + Vector2(size * 0.04, 0), size * 0.36, -0.8, 0.8, 16, colour, size * 0.07, true)


static func draw_snail(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.45, size * 0.2), Vector2(size * 0.9, size * 0.14)), colour)
	canvas.draw_circle(centre + Vector2(size * 0.05, -size * 0.02), size * 0.28, colour)
	canvas.draw_arc(centre + Vector2(size * 0.05, -size * 0.02), size * 0.14, 0, TAU * 0.8, 16, colour.darkened(0.45), size * 0.05, true)
	canvas.draw_line(centre + Vector2(-size * 0.38, size * 0.22), centre + Vector2(-size * 0.42, -size * 0.18), colour, size * 0.06, true)
	canvas.draw_circle(centre + Vector2(-size * 0.42, -size * 0.2), size * 0.06, colour)


static func draw_gap(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.48, 0), Vector2(size * 0.32, size * 0.4)), colour)
	canvas.draw_rect(Rect2(centre + Vector2(size * 0.16, 0), Vector2(size * 0.32, size * 0.4)), colour)
	canvas.draw_line(centre + Vector2(-size * 0.12, -size * 0.18), centre + Vector2(size * 0.12, -size * 0.18), colour, size * 0.06)
	canvas.draw_colored_polygon(PackedVector2Array([centre + Vector2(-size * 0.16, -size * 0.18),
		centre + Vector2(-size * 0.06, -size * 0.27), centre + Vector2(-size * 0.06, -size * 0.09)]), colour)
	canvas.draw_colored_polygon(PackedVector2Array([centre + Vector2(size * 0.16, -size * 0.18),
		centre + Vector2(size * 0.06, -size * 0.27), centre + Vector2(size * 0.06, -size * 0.09)]), colour)


static func draw_jump_arc(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_arc(centre + Vector2(0, size * 0.3), size * 0.4, PI, TAU, 24, colour, size * 0.06, true)
	canvas.draw_circle(centre + Vector2(0, -size * 0.1), size * 0.15, colour)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.48, size * 0.3), Vector2(size * 0.96, size * 0.1)), colour)


static func draw_bin(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.26, -size * 0.22), Vector2(size * 0.52, size * 0.64)), colour)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.34, -size * 0.36), Vector2(size * 0.68, size * 0.1)), colour)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.1, -size * 0.44), Vector2(size * 0.2, size * 0.1)), colour)


static func draw_controller(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_circle(centre + Vector2(-size * 0.28, 0), size * 0.22, colour)
	canvas.draw_circle(centre + Vector2(size * 0.28, 0), size * 0.22, colour)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.3, -size * 0.22), Vector2(size * 0.6, size * 0.3)), colour)
	var detail: Color = colour.darkened(0.45)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.36, -size * 0.03), Vector2(size * 0.16, size * 0.05)), detail)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.305, -size * 0.085), Vector2(size * 0.05, size * 0.16)), detail)
	canvas.draw_circle(centre + Vector2(size * 0.3, -size * 0.06), size * 0.04, detail)
	canvas.draw_circle(centre + Vector2(size * 0.24, size * 0.02), size * 0.04, detail)
	canvas.draw_circle(centre + Vector2(size * 0.36, size * 0.02), size * 0.04, detail)
	canvas.draw_circle(centre + Vector2(size * 0.3, size * 0.08), size * 0.04, detail)


static func draw_padlock(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	canvas.draw_arc(centre - Vector2(0, size * 0.05), size * 0.22, PI, TAU, 16, colour, size * 0.09, true)
	canvas.draw_line(centre + Vector2(-size * 0.22, -size * 0.05), centre + Vector2(-size * 0.22, size * 0.05), colour, size * 0.09)
	canvas.draw_line(centre + Vector2(size * 0.22, -size * 0.05), centre + Vector2(size * 0.22, size * 0.05), colour, size * 0.09)
	canvas.draw_rect(Rect2(centre + Vector2(-size * 0.32, size * 0.02), Vector2(size * 0.64, size * 0.44)), colour)
	canvas.draw_circle(centre + Vector2(0, size * 0.2), size * 0.07, colour.darkened(0.5))


## A five-pointed gold star with a darker rim, for something finished.
static func draw_gold_star(canvas: CanvasItem, centre: Vector2, size: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index in 10:
		var radius: float = size * (0.5 if point_index % 2 == 0 else 0.22)
		var angle: float = -PI / 2.0 + point_index * PI / 5.0
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	var rim: PackedVector2Array = points.duplicate()
	rim.append(points[0])
	canvas.draw_colored_polygon(points, Color(1.0, 0.8, 0.15))
	canvas.draw_polyline(rim, Color(0.8, 0.5, 0.05), size * 0.06, true)


static func draw_book(canvas: CanvasItem, centre: Vector2, size: float, colour: Color) -> void:
	for side in [-1.0, 1.0]:
		canvas.draw_colored_polygon(PackedVector2Array([
			centre + Vector2(side * size * 0.03, -size * 0.26), centre + Vector2(side * size * 0.46, -size * 0.34),
			centre + Vector2(side * size * 0.46, size * 0.3), centre + Vector2(side * size * 0.03, size * 0.38),
		]), colour)
		for line_index in 3:
			var line_y: float = -size * 0.14 + line_index * size * 0.14
			canvas.draw_line(centre + Vector2(side * size * 0.12, line_y), centre + Vector2(side * size * 0.37, line_y - size * 0.03),
				colour.darkened(0.3), size * 0.04, true)


## A full-colour picture for a tile, instead of a white icon: "thing:dog"
## or "friend:plum".
static func draw_picture(canvas: CanvasItem, picture: String, centre: Vector2, size: float) -> void:
	if picture.begins_with("friend:"):
		var time: float = Time.get_ticks_msec() / 1000.0
		PuddleFriend.draw_friend(canvas, picture.trim_prefix("friend:"), centre + Vector2(0, size * 0.08), size / 95.0, time)
		return
	if picture.begins_with("thing:"):
		var scale: float = size / 110.0
		canvas.draw_set_transform(centre + Vector2(0, -ThingDrawings.GROUND_Y * 0.3 * scale), 0.0, Vector2(scale, scale))
		ThingDrawings.draw(canvas, picture.trim_prefix("thing:"))
		canvas.draw_set_transform(Vector2.ZERO)
