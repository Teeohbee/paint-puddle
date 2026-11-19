class_name TrickyFaces
extends RefCounted
## The eight tricky clock faces, ported from prototype/tricky-clock-faces.
## Each rung cleared unlocks the next one. They draw on a ClockFace, round
## its middle, at the prototype's size (radius 380) inside a transform that
## scales them to the home face's size.
##
## The puddle blob in the middle stays on the game's own faces and is left
## off the real-life ones: the kitchen clock, the wristwatch and the bare
## designer clock.

const RADIUS: float = 380.0
const INK: Color = PaintColours.INK
const BLOB_RED: Color = PaintColours.RED
const SECONDS_RED: Color = Color(0.9, 0.2, 0.2)


static func draw(canvas: ClockFace, face_name: String) -> void:
	var to_home_size: float = ClockFace.RADIUS / RADIUS
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(to_home_size, to_home_size))
	match face_name:
		"four numbers": draw_four_numbers_face(canvas)
		"kitchen": draw_kitchen_clock(canvas)
		"square": draw_square_face(canvas)
		"puddle": draw_puddle_face(canvas)
		"marks only": draw_marks_only_face(canvas)
		"twin hands": draw_twin_hands_face(canvas)
		"wristwatch": draw_wristwatch(canvas)
		"bare": draw_bare_face(canvas)
	canvas.draw_set_transform(Vector2.ZERO)


static func hour_angle(canvas: ClockFace) -> float:
	return ClockFace.angle_of_turns(ClockTime.hour_hand_turns(canvas.shown_minutes))


static func minute_angle(canvas: ClockFace) -> float:
	return ClockFace.angle_of_turns(ClockTime.minute_hand_turns(canvas.shown_minutes))


static func seconds_angle(canvas: ClockFace) -> float:
	return TAU * floorf(canvas.seconds) / 60.0 - PI / 2.0


static func number_angle(canvas: ClockFace, number: int) -> float:
	return TAU * number / 12.0 - PI / 2.0


static func shows_minute_hand(canvas: ClockFace) -> bool:
	return canvas.shows_minute_hand and canvas.minute_hand_reach > 0.0


static func at(canvas: ClockFace, centre: Vector2, angle: float, distance: float) -> Vector2:
	return centre + Vector2.from_angle(angle) * distance


static func number_colour(canvas: ClockFace, number: int) -> Color:
	return Color.from_hsv(fposmod(number / 12.0 - 0.02, 1.0), 0.6, 1.0)


static func draw_centred_text(canvas: ClockFace, text: String, centre: Vector2, size: int, colour: Color, use_font: Font = null) -> void:
	var chosen: Font = use_font if use_font else canvas.game_font()
	var text_size := chosen.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	canvas.draw_string(chosen, centre + Vector2(-text_size.x / 2.0, size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)


static func draw_rounded_hand(canvas: ClockFace, centre: Vector2, angle: float, length: float, width: float, colour: Color) -> void:
	var tip := at(canvas, centre, angle, length)
	var tail := at(canvas, centre, angle + PI, length * 0.12)
	canvas.draw_line(tail, tip, colour, width)
	canvas.draw_circle(tip, width / 2.0, colour)
	canvas.draw_circle(tail, width / 2.0, colour)


static func draw_ink_hands(canvas: ClockFace, centre: Vector2, radius: float, hour_length: float, hour_width: float, minute_length: float, minute_width: float) -> void:
	draw_rounded_hand(canvas, centre, hour_angle(canvas), radius * hour_length, hour_width, INK)
	if shows_minute_hand(canvas):
		draw_rounded_hand(canvas, centre, minute_angle(canvas), radius * minute_length, minute_width, INK)


static func draw_minute_marks(canvas: ClockFace, centre: Vector2, radius: float, minute_width: float, five_width: float, five_length: float, skip_fives := false) -> void:
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		var is_five := minute % 5 == 0
		if is_five and skip_fives:
			continue
		var length := five_length if is_five else five_length * 0.45
		canvas.draw_line(at(canvas, centre, angle, radius - length), at(canvas, centre, angle, radius), INK, five_width if is_five else minute_width)


static func draw_round_face(canvas: ClockFace, centre: Vector2, radius: float, rim: Color, rim_width: float, face: Color) -> void:
	canvas.draw_circle(centre + Vector2(0, 14), radius + rim_width, Color(0, 0, 0, 0.12))
	canvas.draw_circle(centre, radius + rim_width, rim)
	canvas.draw_circle(centre, radius, face)


static func draw_rainbow_numbers(canvas: ClockFace, centre: Vector2, distance: float, size: int, numbers: Array) -> void:
	for number in numbers:
		var spot := at(canvas, centre, number_angle(canvas, number), distance)
		draw_centred_text(canvas, str(number), spot + Vector2(3, 3), size, number_colour(canvas, number).darkened(0.45))
		draw_centred_text(canvas, str(number), spot, size, number_colour(canvas, number).darkened(0.15))


static func wobbly_points(canvas: ClockFace, centre: Vector2, radius: float, seed_value: float, wobble_size: float, count := 64) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * index / count
		points.append(centre + Vector2.from_angle(angle) * radius * (1.0 + wobble(canvas, angle, seed_value, wobble_size)))
	return points


static func wobble(canvas: ClockFace, angle: float, seed_value: float, wobble_size: float) -> float:
	return wobble_size * (0.6 * sin(3.0 * angle + seed_value) + 0.4 * sin(5.0 * angle - seed_value * 1.7))


static func draw_middle_blob(canvas: ClockFace, centre: Vector2) -> void:
	var look := Vector2.from_angle(minute_angle(canvas) if shows_minute_hand(canvas) else hour_angle(canvas))
	canvas.draw_colored_polygon(wobbly_points(canvas, centre, 50, 2.0, 0.08, 32), BLOB_RED.darkened(0.35))
	canvas.draw_colored_polygon(wobbly_points(canvas, centre, 45, 2.0, 0.08, 32), BLOB_RED)
	canvas.draw_circle(centre + Vector2(-18, -20), 7, Color(1, 1, 1, 0.55))
	for eye_side in [-1, 1]:
		var eye := centre + Vector2(eye_side * 14, -6)
		canvas.draw_circle(eye, 11, Color.WHITE)
		canvas.draw_circle(eye + look * 4, 6, INK)
	canvas.draw_arc(centre + Vector2(0, 12), 10, 0.3, PI - 0.3, 12, INK, 3.0)


# 1: the quarter numbers stay as signposts, the rest become bold marks.
static func draw_four_numbers_face(canvas: ClockFace) -> void:
	draw_round_face(canvas, Vector2.ZERO, RADIUS, INK, 22, Color.WHITE)
	draw_minute_marks(canvas, Vector2.ZERO, RADIUS - 10, 3, 8, 30)
	for number in range(1, 13):
		if number % 3 != 0:
			var angle := number_angle(canvas, number)
			canvas.draw_line(at(canvas, Vector2.ZERO, angle, RADIUS - 130), at(canvas, Vector2.ZERO, angle, RADIUS - 70), number_colour(canvas, number).darkened(0.15), 18)
	draw_rainbow_numbers(canvas, Vector2.ZERO, RADIUS - 100, 80, [12, 3, 6, 9])
	draw_ink_hands(canvas, Vector2.ZERO, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(canvas, Vector2.ZERO)


# 2: twelve bold marks, no numbers at all. 12 gets a double mark.
static func draw_marks_only_face(canvas: ClockFace) -> void:
	draw_round_face(canvas, Vector2.ZERO, RADIUS, INK, 22, Color.WHITE)
	draw_minute_marks(canvas, Vector2.ZERO, RADIUS - 10, 3, 8, 30, true)
	for number in range(1, 13):
		var angle := number_angle(canvas, number)
		if number == 12:
			for offset in [-0.035, 0.035]:
				canvas.draw_line(at(canvas, Vector2.ZERO, angle + offset, RADIUS - 100), at(canvas, Vector2.ZERO, angle + offset, RADIUS - 12), INK, 16)
		else:
			canvas.draw_line(at(canvas, Vector2.ZERO, angle, RADIUS - 90), at(canvas, Vector2.ZERO, angle, RADIUS - 12), INK, 16)
	draw_ink_hands(canvas, Vector2.ZERO, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(canvas, Vector2.ZERO)


# 3: a designer clock. Nothing but a dot at 12.
static func draw_bare_face(canvas: ClockFace) -> void:
	draw_round_face(canvas, Vector2.ZERO, RADIUS, INK, 22, Color(0.98, 0.94, 0.86))
	canvas.draw_circle(at(canvas, Vector2.ZERO, -PI / 2.0, RADIUS - 50), 16, INK)
	draw_ink_hands(canvas, Vector2.ZERO, RADIUS, 0.55, 26, 0.82, 14)
	canvas.draw_circle(Vector2.ZERO, 24, INK)


# 4: the home face, but hands like a fancy clock: both thin, hour hand
# nearly as long as the minute hand. Tells them apart by length alone.
static func draw_twin_hands_face(canvas: ClockFace) -> void:
	draw_round_face(canvas, Vector2.ZERO, RADIUS, INK, 22, Color.WHITE)
	draw_minute_marks(canvas, Vector2.ZERO, RADIUS - 10, 3, 8, 30)
	draw_rainbow_numbers(canvas, Vector2.ZERO, RADIUS - 100, 80, range(1, 13))
	draw_ink_hands(canvas, Vector2.ZERO, RADIUS, 0.68, 12, 0.82, 10)
	draw_middle_blob(canvas, Vector2.ZERO)


# 5: a shop-bought kitchen clock. Coloured plastic rim, small plain
# numbers, a red seconds hand that ticks while the player thinks.
static func draw_kitchen_clock(canvas: ClockFace) -> void:
	var rim := Color(0.35, 0.68, 0.62)
	draw_round_face(canvas, Vector2.ZERO, RADIUS, rim, 40, Color(0.99, 0.99, 0.97))
	canvas.draw_arc(Vector2.ZERO, RADIUS + 40, 0, TAU, 128, rim.darkened(0.3), 6)
	draw_minute_marks(canvas, Vector2.ZERO, RADIUS - 14, 2, 6, 22)
	for number in range(1, 13):
		draw_centred_text(canvas, str(number), at(canvas, Vector2.ZERO, number_angle(canvas, number), RADIUS - 80), 54, INK, ThemeDB.fallback_font)
	draw_centred_text(canvas, "QUARTZ", Vector2.ZERO + Vector2(0, 130), 22, Color(INK, 0.5), ThemeDB.fallback_font)
	draw_rounded_hand(canvas, Vector2.ZERO, hour_angle(canvas), RADIUS * 0.52, 18, INK)
	if shows_minute_hand(canvas):
		draw_rounded_hand(canvas, Vector2.ZERO, minute_angle(canvas), RADIUS * 0.82, 11, INK)
	var second_angle := seconds_angle(canvas)
	canvas.draw_line(at(canvas, Vector2.ZERO, second_angle + PI, RADIUS * 0.2), at(canvas, Vector2.ZERO, second_angle, RADIUS * 0.88), SECONDS_RED, 4)
	canvas.draw_circle(Vector2.ZERO, 14, SECONDS_RED)


# 6: a grown-up's wristwatch, filling the same space so it stays readable.
static func draw_wristwatch(canvas: ClockFace) -> void:
	var strap := Color(0.45, 0.3, 0.22)
	var radius := 300.0
	canvas.draw_rect(Rect2(-170, -560, 340, 1120), strap.darkened(0.25))
	canvas.draw_rect(Rect2(-160, -560, 320, 1120), strap)
	for y in [-480, -400, 400, 480]:
		canvas.draw_circle(Vector2(0, y), 14, strap.darkened(0.4))
	canvas.draw_rect(Rect2(radius + 20, -40, 50, 80), Color(0.7, 0.72, 0.78))
	draw_round_face(canvas, Vector2.ZERO, radius, Color(0.78, 0.8, 0.86), 40, Color(0.16, 0.24, 0.42))
	canvas.draw_arc(Vector2.ZERO, radius + 40, 0, TAU, 128, Color(0.5, 0.52, 0.58), 6)
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		canvas.draw_line(at(canvas, Vector2.ZERO, angle, radius - 12), at(canvas, Vector2.ZERO, angle, radius - 2), Color(1, 1, 1, 0.6), 2)
	for number in range(1, 13):
		var angle := number_angle(canvas, number)
		if number == 3:
			var window := Rect2(at(canvas, Vector2.ZERO, angle, radius - 70) - Vector2(32, 24), Vector2(64, 48))
			canvas.draw_rect(window, Color.WHITE)
			draw_centred_text(canvas, "15", window.get_center(), 32, INK, ThemeDB.fallback_font)
		elif number % 3 == 0:
			draw_centred_text(canvas, str(number), at(canvas, Vector2.ZERO, angle, radius - 60), 64, Color.WHITE)
		else:
			canvas.draw_line(at(canvas, Vector2.ZERO, angle, radius - 70), at(canvas, Vector2.ZERO, angle, radius - 22), Color.WHITE, 12)
	var hand_colour := Color(0.92, 0.94, 1.0)
	draw_rounded_hand(canvas, Vector2.ZERO, hour_angle(canvas), radius * 0.5, 20, hand_colour)
	if shows_minute_hand(canvas):
		draw_rounded_hand(canvas, Vector2.ZERO, minute_angle(canvas), radius * 0.8, 12, hand_colour)
	var second_angle := seconds_angle(canvas)
	canvas.draw_line(at(canvas, Vector2.ZERO, second_angle + PI, radius * 0.2), at(canvas, Vector2.ZERO, second_angle, radius * 0.9), Color(1.0, 0.55, 0.2), 3)
	canvas.draw_circle(Vector2.ZERO, 12, Color(1.0, 0.55, 0.2))


# 7: a square face. Angles are right, but the numbers sit at different
# distances, so 1, 2, 4, 5... aren't evenly spaced along the edge.
static func square_point(canvas: ClockFace, angle: float, half_size: float) -> Vector2:
	var direction := Vector2.from_angle(angle)
	var scale_to_edge := half_size / maxf(absf(direction.x), absf(direction.y))
	return Vector2.ZERO + direction * scale_to_edge


static func draw_square_face(canvas: ClockFace) -> void:
	var half := RADIUS
	var box := Rect2(Vector2.ZERO - Vector2(half, half), Vector2(half * 2, half * 2))
	canvas.draw_rect(Rect2(box.position + Vector2(0, 14), box.size).grow(22), Color(0, 0, 0, 0.12))
	canvas.draw_rect(box.grow(22), INK)
	canvas.draw_rect(box, Color.WHITE)
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		var is_five := minute % 5 == 0
		var outer := square_point(canvas, angle, half - 10)
		var inner := square_point(canvas, angle, half - (40 if is_five else 24))
		canvas.draw_line(inner, outer, INK, 8 if is_five else 3)
	for number in range(1, 13):
		var spot := square_point(canvas, number_angle(canvas, number), half - 95)
		draw_centred_text(canvas, str(number), spot + Vector2(3, 3), 80, number_colour(canvas, number).darkened(0.45))
		draw_centred_text(canvas, str(number), spot, 80, number_colour(canvas, number).darkened(0.15))
	draw_ink_hands(canvas, Vector2.ZERO, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(canvas, Vector2.ZERO)


# 8: Paint Puddle's own odd shape. The face is a wobbly puddle and the
# numbers follow its edge, so they drift in and out.
static func draw_puddle_face(canvas: ClockFace) -> void:
	var wobble_size := 0.12
	var seed_value := 0.7
	canvas.draw_colored_polygon(wobbly_points(canvas, Vector2.ZERO + Vector2(0, 14), RADIUS + 22, seed_value, wobble_size), Color(0, 0, 0, 0.12))
	canvas.draw_colored_polygon(wobbly_points(canvas, Vector2.ZERO, RADIUS + 22, seed_value, wobble_size), Color(0.3, 0.55, 1.0).darkened(0.3))
	canvas.draw_colored_polygon(wobbly_points(canvas, Vector2.ZERO, RADIUS, seed_value, wobble_size), Color(0.86, 0.93, 1.0))
	canvas.draw_circle(Vector2.ZERO + Vector2(-210, -230), 26, Color(1, 1, 1, 0.7))
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		var edge := (RADIUS - 10) * (1.0 + wobble(canvas, angle, seed_value, wobble_size))
		var length := 30.0 if minute % 5 == 0 else 14.0
		canvas.draw_line(at(canvas, Vector2.ZERO, angle, edge - length), at(canvas, Vector2.ZERO, angle, edge), INK, 8 if minute % 5 == 0 else 3)
	for number in range(1, 13):
		var angle := number_angle(canvas, number)
		var spot := at(canvas, Vector2.ZERO, angle, (RADIUS - 100) * (1.0 + wobble(canvas, angle, seed_value, wobble_size)))
		draw_centred_text(canvas, str(number), spot + Vector2(3, 3), 80, number_colour(canvas, number).darkened(0.45))
		draw_centred_text(canvas, str(number), spot, 80, number_colour(canvas, number).darkened(0.15))
	draw_ink_hands(canvas, Vector2.ZERO, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(canvas, Vector2.ZERO)
