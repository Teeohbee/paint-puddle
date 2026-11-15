# PROTOTYPE - throwaway. Answers "which tricky clock faces are there?" for
# the Clock mode map (Tricky clock faces, issue #89). Not production code.
# Face only, no house: the house was settled in #92.
#
# Q/E or shoulder buttons: switch face. Left/right: wind by the rung's step.
# Up/down: change rung. Pause/Start: quit.
extends Node2D

const RUNG_STEP_MINUTES := [60, 30, 30, 15, 15, 5, 5, 1]
const RUNG_HIDES_MINUTE_HAND := [true, true, false, false, false, false, false, false]

const FACE_NAMES := [
	"0  Home face (the chosen face E, for comparison)",
	"1  Four numbers: only 12, 3, 6 and 9, bold marks for the rest",
	"2  Marks only: no numbers, twelve bold marks",
	"3  Bare: no numbers, no minute marks, one dot at 12",
	"4  Twin hands: thin hands, the hour hand nearly as long as the minute hand",
	"5  Kitchen clock: small plain numbers, a ticking red seconds hand",
	"6  Wristwatch: a little face on a strap, batons, a date window, seconds hand",
	"7  Square face: the numbers sit on a square, not a circle",
	"8  Puddle face: a wobbly puddle shape, the numbers drift in and out",
]

const CENTRE := Vector2(960, 560)
const RADIUS := 380.0
const INK := Color(0.17, 0.13, 0.25)
const CREAM := Color(1.0, 0.97, 0.9)
const BLOB_RED := Color(1.0, 0.36, 0.43)
const SECONDS_RED := Color(0.9, 0.2, 0.2)

var face_index := 0
var rung_index := 5
var wound_minutes := 14 * 60 + 50
var displayed_minutes := float(14 * 60 + 50)
var seconds := 0.0
var font: Font
var thin_font: Font


func _ready() -> void:
	var chunky := FontVariation.new()
	chunky.base_font = ThemeDB.fallback_font
	chunky.variation_embolden = 0.9
	font = chunky
	thin_font = ThemeDB.fallback_font


## For the capture script.
func show_state(new_face: int, new_rung: int, minutes_of_day: int) -> void:
	face_index = new_face
	rung_index = new_rung
	wound_minutes = minutes_of_day
	displayed_minutes = minutes_of_day
	seconds = 20.0
	queue_redraw()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().quit()
	if Input.is_action_just_pressed("move_right"):
		wound_minutes += RUNG_STEP_MINUTES[rung_index]
	if Input.is_action_just_pressed("move_left"):
		wound_minutes -= RUNG_STEP_MINUTES[rung_index]
	if Input.is_action_just_pressed("move_up"):
		rung_index = mini(rung_index + 1, 7)
		snap_to_rung()
	if Input.is_action_just_pressed("move_down"):
		rung_index = maxi(rung_index - 1, 0)
		snap_to_rung()
	displayed_minutes = lerpf(displayed_minutes, float(wound_minutes), 1.0 - exp(-14.0 * delta))
	seconds = fposmod(seconds + delta, 60.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var step := 0
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER: step = -1
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER: step = 1
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q: step = -1
		if event.keycode == KEY_E: step = 1
	if step != 0:
		face_index = posmod(face_index + step, FACE_NAMES.size())


func snap_to_rung() -> void:
	var step: int = RUNG_STEP_MINUTES[rung_index]
	wound_minutes = int(round(float(wound_minutes) / step)) * step


# ---------------------------------------------------------------- helpers

func hour_angle() -> float:
	return TAU * fposmod(displayed_minutes, 720.0) / 720.0 - PI / 2.0


func minute_angle() -> float:
	return TAU * fposmod(displayed_minutes, 60.0) / 60.0 - PI / 2.0


func seconds_angle() -> float:
	return TAU * floorf(seconds) / 60.0 - PI / 2.0


func number_angle(number: int) -> float:
	return TAU * number / 12.0 - PI / 2.0


func shows_minute_hand() -> bool:
	return not RUNG_HIDES_MINUTE_HAND[rung_index]


func at(centre: Vector2, angle: float, distance: float) -> Vector2:
	return centre + Vector2.from_angle(angle) * distance


func number_colour(number: int) -> Color:
	return Color.from_hsv(fposmod(number / 12.0 - 0.02, 1.0), 0.6, 1.0)


func draw_centred_text(text: String, centre: Vector2, size: int, colour: Color, use_font: Font = null) -> void:
	var chosen := use_font if use_font else font
	var text_size := chosen.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	draw_string(chosen, centre + Vector2(-text_size.x / 2.0, size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)


func draw_rounded_hand(centre: Vector2, angle: float, length: float, width: float, colour: Color) -> void:
	var tip := at(centre, angle, length)
	var tail := at(centre, angle + PI, length * 0.12)
	draw_line(tail, tip, colour, width)
	draw_circle(tip, width / 2.0, colour)
	draw_circle(tail, width / 2.0, colour)


func draw_ink_hands(centre: Vector2, radius: float, hour_length: float, hour_width: float, minute_length: float, minute_width: float) -> void:
	draw_rounded_hand(centre, hour_angle(), radius * hour_length, hour_width, INK)
	if shows_minute_hand():
		draw_rounded_hand(centre, minute_angle(), radius * minute_length, minute_width, INK)


func draw_minute_marks(centre: Vector2, radius: float, minute_width: float, five_width: float, five_length: float, skip_fives := false) -> void:
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		var is_five := minute % 5 == 0
		if is_five and skip_fives:
			continue
		var length := five_length if is_five else five_length * 0.45
		draw_line(at(centre, angle, radius - length), at(centre, angle, radius), INK, five_width if is_five else minute_width)


func draw_round_face(centre: Vector2, radius: float, rim: Color, rim_width: float, face: Color) -> void:
	draw_circle(centre + Vector2(0, 14), radius + rim_width, Color(0, 0, 0, 0.12))
	draw_circle(centre, radius + rim_width, rim)
	draw_circle(centre, radius, face)


func draw_rainbow_numbers(centre: Vector2, distance: float, size: int, numbers: Array) -> void:
	for number in numbers:
		var spot := at(centre, number_angle(number), distance)
		draw_centred_text(str(number), spot + Vector2(3, 3), size, number_colour(number).darkened(0.45))
		draw_centred_text(str(number), spot, size, number_colour(number).darkened(0.15))


func wobbly_points(centre: Vector2, radius: float, seed_value: float, wobble_size: float, count := 64) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * index / count
		points.append(centre + Vector2.from_angle(angle) * radius * (1.0 + wobble(angle, seed_value, wobble_size)))
	return points


func wobble(angle: float, seed_value: float, wobble_size: float) -> float:
	return wobble_size * (0.6 * sin(3.0 * angle + seed_value) + 0.4 * sin(5.0 * angle - seed_value * 1.7))


func draw_middle_blob(centre: Vector2) -> void:
	var look := Vector2.from_angle(minute_angle() if shows_minute_hand() else hour_angle())
	draw_colored_polygon(wobbly_points(centre, 50, 2.0, 0.08, 32), BLOB_RED.darkened(0.35))
	draw_colored_polygon(wobbly_points(centre, 45, 2.0, 0.08, 32), BLOB_RED)
	draw_circle(centre + Vector2(-18, -20), 7, Color(1, 1, 1, 0.55))
	for eye_side in [-1, 1]:
		var eye := centre + Vector2(eye_side * 14, -6)
		draw_circle(eye, 11, Color.WHITE)
		draw_circle(eye + look * 4, 6, INK)
	draw_arc(centre + Vector2(0, 12), 10, 0.3, PI - 0.3, 12, INK, 3.0)


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), CREAM)
	match face_index:
		0: draw_home_face()
		1: draw_four_numbers_face()
		2: draw_marks_only_face()
		3: draw_bare_face()
		4: draw_twin_hands_face()
		5: draw_kitchen_clock()
		6: draw_wristwatch()
		7: draw_square_face()
		8: draw_puddle_face()
	draw_prototype_bar()


# 0: the chosen home face.
func draw_home_face() -> void:
	draw_round_face(CENTRE, RADIUS, INK, 22, Color.WHITE)
	draw_minute_marks(CENTRE, RADIUS - 10, 3, 8, 30)
	draw_rainbow_numbers(CENTRE, RADIUS - 100, 80, range(1, 13))
	draw_ink_hands(CENTRE, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(CENTRE)


# 1: the quarter numbers stay as signposts, the rest become bold marks.
func draw_four_numbers_face() -> void:
	draw_round_face(CENTRE, RADIUS, INK, 22, Color.WHITE)
	draw_minute_marks(CENTRE, RADIUS - 10, 3, 8, 30)
	for number in range(1, 13):
		if number % 3 != 0:
			var angle := number_angle(number)
			draw_line(at(CENTRE, angle, RADIUS - 130), at(CENTRE, angle, RADIUS - 70), number_colour(number).darkened(0.15), 18)
	draw_rainbow_numbers(CENTRE, RADIUS - 100, 80, [12, 3, 6, 9])
	draw_ink_hands(CENTRE, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(CENTRE)


# 2: twelve bold marks, no numbers at all. 12 gets a double mark.
func draw_marks_only_face() -> void:
	draw_round_face(CENTRE, RADIUS, INK, 22, Color.WHITE)
	draw_minute_marks(CENTRE, RADIUS - 10, 3, 8, 30, true)
	for number in range(1, 13):
		var angle := number_angle(number)
		if number == 12:
			for offset in [-0.035, 0.035]:
				draw_line(at(CENTRE, angle + offset, RADIUS - 100), at(CENTRE, angle + offset, RADIUS - 12), INK, 16)
		else:
			draw_line(at(CENTRE, angle, RADIUS - 90), at(CENTRE, angle, RADIUS - 12), INK, 16)
	draw_ink_hands(CENTRE, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(CENTRE)


# 3: a designer clock. Nothing but a dot at 12.
func draw_bare_face() -> void:
	draw_round_face(CENTRE, RADIUS, INK, 22, Color(0.98, 0.94, 0.86))
	draw_circle(at(CENTRE, -PI / 2.0, RADIUS - 50), 16, INK)
	draw_ink_hands(CENTRE, RADIUS, 0.55, 26, 0.82, 14)
	draw_circle(CENTRE, 24, INK)


# 4: the home face, but hands like a fancy clock: both thin, hour hand
# nearly as long as the minute hand. Tells them apart by length alone.
func draw_twin_hands_face() -> void:
	draw_round_face(CENTRE, RADIUS, INK, 22, Color.WHITE)
	draw_minute_marks(CENTRE, RADIUS - 10, 3, 8, 30)
	draw_rainbow_numbers(CENTRE, RADIUS - 100, 80, range(1, 13))
	draw_ink_hands(CENTRE, RADIUS, 0.68, 12, 0.82, 10)
	draw_middle_blob(CENTRE)


# 5: a shop-bought kitchen clock. Coloured plastic rim, small plain
# numbers, a red seconds hand that ticks while the player thinks.
func draw_kitchen_clock() -> void:
	var rim := Color(0.35, 0.68, 0.62)
	draw_round_face(CENTRE, RADIUS, rim, 40, Color(0.99, 0.99, 0.97))
	draw_arc(CENTRE, RADIUS + 40, 0, TAU, 128, rim.darkened(0.3), 6)
	draw_minute_marks(CENTRE, RADIUS - 14, 2, 6, 22)
	for number in range(1, 13):
		draw_centred_text(str(number), at(CENTRE, number_angle(number), RADIUS - 80), 54, INK, thin_font)
	draw_centred_text("QUARTZ", CENTRE + Vector2(0, 130), 22, Color(INK, 0.5), thin_font)
	draw_rounded_hand(CENTRE, hour_angle(), RADIUS * 0.52, 18, INK)
	if shows_minute_hand():
		draw_rounded_hand(CENTRE, minute_angle(), RADIUS * 0.82, 11, INK)
	var second_angle := seconds_angle()
	draw_line(at(CENTRE, second_angle + PI, RADIUS * 0.2), at(CENTRE, second_angle, RADIUS * 0.88), SECONDS_RED, 4)
	draw_circle(CENTRE, 14, SECONDS_RED)


# 6: a grown-up's wristwatch, filling the same space so it stays readable.
func draw_wristwatch() -> void:
	var strap := Color(0.45, 0.3, 0.22)
	var radius := 300.0
	draw_rect(Rect2(CENTRE.x - 170, 0, 340, 1080), strap.darkened(0.25))
	draw_rect(Rect2(CENTRE.x - 160, 0, 320, 1080), strap)
	for y in [80, 160, 960, 1040]:
		draw_circle(Vector2(CENTRE.x, y), 14, strap.darkened(0.4))
	draw_rect(Rect2(CENTRE.x + radius + 20, CENTRE.y - 40, 50, 80), Color(0.7, 0.72, 0.78))
	draw_round_face(CENTRE, radius, Color(0.78, 0.8, 0.86), 40, Color(0.16, 0.24, 0.42))
	draw_arc(CENTRE, radius + 40, 0, TAU, 128, Color(0.5, 0.52, 0.58), 6)
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		draw_line(at(CENTRE, angle, radius - 12), at(CENTRE, angle, radius - 2), Color(1, 1, 1, 0.6), 2)
	for number in range(1, 13):
		var angle := number_angle(number)
		if number == 3:
			var window := Rect2(at(CENTRE, angle, radius - 70) - Vector2(32, 24), Vector2(64, 48))
			draw_rect(window, Color.WHITE)
			draw_centred_text("15", window.get_center(), 32, INK, thin_font)
		elif number % 3 == 0:
			draw_centred_text(str(number), at(CENTRE, angle, radius - 60), 64, Color.WHITE)
		else:
			draw_line(at(CENTRE, angle, radius - 70), at(CENTRE, angle, radius - 22), Color.WHITE, 12)
	var hand_colour := Color(0.92, 0.94, 1.0)
	draw_rounded_hand(CENTRE, hour_angle(), radius * 0.5, 20, hand_colour)
	if shows_minute_hand():
		draw_rounded_hand(CENTRE, minute_angle(), radius * 0.8, 12, hand_colour)
	var second_angle := seconds_angle()
	draw_line(at(CENTRE, second_angle + PI, radius * 0.2), at(CENTRE, second_angle, radius * 0.9), Color(1.0, 0.55, 0.2), 3)
	draw_circle(CENTRE, 12, Color(1.0, 0.55, 0.2))


# 7: a square face. Angles are right, but the numbers sit at different
# distances, so 1, 2, 4, 5... aren't evenly spaced along the edge.
func square_point(angle: float, half_size: float) -> Vector2:
	var direction := Vector2.from_angle(angle)
	var scale_to_edge := half_size / maxf(absf(direction.x), absf(direction.y))
	return CENTRE + direction * scale_to_edge


func draw_square_face() -> void:
	var half := RADIUS
	var box := Rect2(CENTRE - Vector2(half, half), Vector2(half * 2, half * 2))
	draw_rect(Rect2(box.position + Vector2(0, 14), box.size).grow(22), Color(0, 0, 0, 0.12))
	draw_rect(box.grow(22), INK)
	draw_rect(box, Color.WHITE)
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		var is_five := minute % 5 == 0
		var outer := square_point(angle, half - 10)
		var inner := square_point(angle, half - (40 if is_five else 24))
		draw_line(inner, outer, INK, 8 if is_five else 3)
	for number in range(1, 13):
		var spot := square_point(number_angle(number), half - 95)
		draw_centred_text(str(number), spot + Vector2(3, 3), 80, number_colour(number).darkened(0.45))
		draw_centred_text(str(number), spot, 80, number_colour(number).darkened(0.15))
	draw_ink_hands(CENTRE, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(CENTRE)


# 8: Paint Puddle's own odd shape. The face is a wobbly puddle and the
# numbers follow its edge, so they drift in and out.
func draw_puddle_face() -> void:
	var wobble_size := 0.12
	var seed_value := 0.7
	draw_colored_polygon(wobbly_points(CENTRE + Vector2(0, 14), RADIUS + 22, seed_value, wobble_size), Color(0, 0, 0, 0.12))
	draw_colored_polygon(wobbly_points(CENTRE, RADIUS + 22, seed_value, wobble_size), Color(0.3, 0.55, 1.0).darkened(0.3))
	draw_colored_polygon(wobbly_points(CENTRE, RADIUS, seed_value, wobble_size), Color(0.86, 0.93, 1.0))
	draw_circle(CENTRE + Vector2(-210, -230), 26, Color(1, 1, 1, 0.7))
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		var edge := (RADIUS - 10) * (1.0 + wobble(angle, seed_value, wobble_size))
		var length := 30.0 if minute % 5 == 0 else 14.0
		draw_line(at(CENTRE, angle, edge - length), at(CENTRE, angle, edge), INK, 8 if minute % 5 == 0 else 3)
	for number in range(1, 13):
		var angle := number_angle(number)
		var spot := at(CENTRE, angle, (RADIUS - 100) * (1.0 + wobble(angle, seed_value, wobble_size)))
		draw_centred_text(str(number), spot + Vector2(3, 3), 80, number_colour(number).darkened(0.45))
		draw_centred_text(str(number), spot, 80, number_colour(number).darkened(0.15))
	draw_ink_hands(CENTRE, RADIUS, 0.5, 30, 0.8, 16)
	draw_middle_blob(CENTRE)


func draw_prototype_bar() -> void:
	var minutes := posmod(wound_minutes, 720)
	var hour := int(minutes / 60.0)
	var label := "PROTOTYPE   %s   |   rung %d   |   %d:%02d" % [FACE_NAMES[face_index], rung_index + 1, 12 if hour == 0 else hour, minutes % 60]
	draw_rect(Rect2(0, 1030, 1920, 50), Color(INK, 0.9))
	draw_string(thin_font, Vector2(24, 1064), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	draw_string(thin_font, Vector2(1500, 1064), "Q/E face   left/right wind   up/down rung", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.6))
