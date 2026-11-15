# PROTOTYPE - throwaway. Answers "what do the clock face and the house look
# like in Paint Puddle's style?" for the Clock mode map (Clock face and house
# look, issue #87). Not production code.
#
# Q/E or shoulder buttons: switch clock face variant.
# Left/right: wind the clock by the rung's step. Up/down: change rung.
# A (act): confirm, so the blobs go and do that moment. Pause/Start: quit.
extends Node2D

const MINUTES_PER_DAY := 1440
const RUNG_STEP_MINUTES := [60, 30, 30, 15, 15, 5, 5, 1]
const RUNG_HIDES_MINUTE_HAND := [true, true, false, false, false, false, false, false]

const VARIANT_NAMES := [
	"A  Schoolroom: plain face, numbers and minute marks",
	"B  Teaching clock: past and to halves, minute ring, coloured hands",
	"C  Paint pots: a puddle per number, the brush paints the minutes",
]

const CLOCK_CENTRE := Vector2(500, 600)
const CLOCK_RADIUS := 380.0
const HOUSE_RECT := Rect2(980, 190, 880, 840)
const GROUND_TOP := 820.0

const INK := Color(0.17, 0.13, 0.25)
const CREAM := Color(1.0, 0.97, 0.9)
const HOUR_HAND_RED := Color(1.0, 0.36, 0.43)
const MINUTE_HAND_BLUE := Color(0.3, 0.55, 1.0)
const PAST_TINT := Color(0.86, 0.93, 1.0)
const TO_TINT := Color(1.0, 0.9, 0.86)

# hour of day -> [moment, where the household is]
const MOMENTS := {
	0: ["Shooting stars", "beds"], 1: ["Fast asleep", "beds"], 2: ["Little blob gets a drink", "beds"],
	3: ["Fast asleep", "beds"], 4: ["A hedgehog in the garden", "beds"], 5: ["Fast asleep", "beds"],
	6: ["The birds wake up", "beds"], 7: ["Wake up!", "upstairs"], 8: ["Breakfast", "table"],
	9: ["Off to the park", "garden"], 10: ["Playing outside", "garden"], 11: ["Playing outside", "garden"],
	12: ["Lunch", "table"], 13: ["Quiet time", "downstairs"], 14: ["Painting", "downstairs"],
	15: ["Watering the garden", "garden"], 16: ["Snack", "table"], 17: ["Tea", "table"],
	18: ["Bath time", "upstairs"], 19: ["Story", "upstairs"], 20: ["Bedtime", "beds"],
	21: ["An owl hoots", "beds"], 22: ["Fast asleep", "beds"], 23: ["A fox at the bins", "beds"],
}

# Sky colour keyframes through the day, in minutes.
const SKY_KEYS := [
	[0, Color(0.1, 0.12, 0.3)], [300, Color(0.12, 0.14, 0.34)], [390, Color(1.0, 0.7, 0.62)],
	[480, Color(0.62, 0.84, 1.0)], [1020, Color(0.6, 0.82, 1.0)], [1140, Color(1.0, 0.62, 0.45)],
	[1230, Color(0.3, 0.22, 0.48)], [1320, Color(0.1, 0.12, 0.3)], [1440, Color(0.1, 0.12, 0.3)],
]

var variant_index := 0
var rung_index := 5
var wound_minutes := 7 * 60
var displayed_minutes := float(7 * 60)
var confirmed_minutes_of_day := 7 * 60
var font: Font
var household: Array[PaintBlobLook] = []
var household_targets: Array[Vector2] = []


func _ready() -> void:
	var chunky := FontVariation.new()
	chunky.base_font = ThemeDB.fallback_font
	chunky.variation_embolden = 0.9
	font = chunky
	for colour in [Color(1.0, 0.36, 0.43), Color(0.3, 0.55, 1.0), Color(1.0, 0.85, 0.25)]:
		var blob := PaintBlobLook.new()
		blob.paint_colour = colour
		add_child(blob)
		household.append(blob)
		household_targets.append(Vector2.ZERO)
	household[2].scale = Vector2(0.7, 0.7)
	place_household(true)


## For the capture script.
func show_state(new_variant: int, new_rung: int, minutes_of_day: int) -> void:
	variant_index = new_variant
	rung_index = new_rung
	wound_minutes = minutes_of_day
	displayed_minutes = minutes_of_day
	confirmed_minutes_of_day = minutes_of_day
	place_household(true)


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
	if Input.is_action_just_pressed("act"):
		confirmed_minutes_of_day = minutes_of_day()
		place_household(false)
	displayed_minutes = lerpf(displayed_minutes, float(wound_minutes), 1.0 - exp(-14.0 * delta))
	for index in household.size():
		household[index].position = household[index].position.lerp(household_targets[index], 1.0 - exp(-4.0 * delta))
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
		variant_index = posmod(variant_index + step, VARIANT_NAMES.size())


func snap_to_rung() -> void:
	var step: int = RUNG_STEP_MINUTES[rung_index]
	wound_minutes = int(round(float(wound_minutes) / step)) * step


func minutes_of_day() -> int:
	return posmod(wound_minutes, MINUTES_PER_DAY)


func place_household(instantly: bool) -> void:
	var hour := int(confirmed_minutes_of_day / 60.0)
	var place: String = MOMENTS[hour][1]
	var spots: Array = spots_for(place)
	for index in household.size():
		household_targets[index] = spots[index]
		if instantly:
			household[index].position = spots[index]


func house_box() -> Rect2:
	return Rect2(HOUSE_RECT.position.x + 60, 380, 520, GROUND_TOP - 380)


func spots_for(place: String) -> Array:
	var box := house_box()
	var upstairs_floor := box.position.y + box.size.y * 0.5 - 30
	var downstairs_floor := box.end.y - 30
	match place:
		"beds":
			return [Vector2(box.position.x + 110, upstairs_floor - 10), Vector2(box.position.x + 230, upstairs_floor - 10), Vector2(box.position.x + 400, upstairs_floor - 4)]
		"upstairs":
			return [Vector2(box.position.x + 150, upstairs_floor), Vector2(box.position.x + 280, upstairs_floor), Vector2(box.position.x + 390, upstairs_floor + 6)]
		"table":
			return [Vector2(box.position.x + 140, downstairs_floor), Vector2(box.position.x + 380, downstairs_floor), Vector2(box.position.x + 260, downstairs_floor - 40)]
		"downstairs":
			return [Vector2(box.position.x + 120, downstairs_floor), Vector2(box.position.x + 260, downstairs_floor), Vector2(box.position.x + 400, downstairs_floor + 6)]
		_:
			return [Vector2(HOUSE_RECT.end.x - 220, GROUND_TOP + 90), Vector2(HOUSE_RECT.end.x - 100, GROUND_TOP + 120), Vector2(HOUSE_RECT.end.x - 160, GROUND_TOP + 150)]


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), CREAM)
	draw_house()
	match variant_index:
		0: draw_schoolroom_clock()
		1: draw_teaching_clock()
		2: draw_paint_pots_clock()
	draw_card()
	draw_prototype_bar()


func hour_angle() -> float:
	return TAU * fposmod(displayed_minutes, 720.0) / 720.0 - PI / 2.0


func minute_angle() -> float:
	return TAU * fposmod(displayed_minutes, 60.0) / 60.0 - PI / 2.0


func shows_minute_hand() -> bool:
	return not RUNG_HIDES_MINUTE_HAND[rung_index]


func angle_point(angle: float, distance: float) -> Vector2:
	return CLOCK_CENTRE + Vector2.from_angle(angle) * distance


func draw_rounded_hand(angle: float, length: float, width: float, colour: Color, outline: Color) -> void:
	var tip := angle_point(angle, length)
	var tail := angle_point(angle + PI, length * 0.12)
	draw_line(tail, tip, outline, width + 8)
	draw_circle(tip, (width + 8) / 2.0, outline)
	draw_circle(tail, (width + 8) / 2.0, outline)
	draw_line(tail, tip, colour, width)
	draw_circle(tip, width / 2.0, colour)
	draw_circle(tail, width / 2.0, colour)


func draw_centred_text(text: String, centre: Vector2, size: int, colour: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	draw_string(font, centre + Vector2(-text_size.x / 2.0, size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)


func wobbly_circle(centre: Vector2, radius: float, seed_value: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 32:
		var angle := TAU * index / 32.0
		var wobble := 0.06 * sin(3.0 * angle + seed_value) + 0.04 * sin(5.0 * angle - seed_value * 1.7)
		points.append(centre + Vector2.from_angle(angle) * radius * (1.0 + wobble))
	return points


func sector(from_angle: float, to_angle: float, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array([CLOCK_CENTRE])
	var segments := maxi(2, int(abs(to_angle - from_angle) / TAU * 96))
	for index in segments + 1:
		points.append(angle_point(lerpf(from_angle, to_angle, float(index) / segments), radius))
	return points


# A: a plain school clock in the game's ink and cream.
func draw_schoolroom_clock() -> void:
	draw_circle(CLOCK_CENTRE + Vector2(0, 14), CLOCK_RADIUS + 22, Color(0, 0, 0, 0.12))
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS + 22, INK)
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS, Color.WHITE)
	for minute in 60:
		var angle := TAU * minute / 60.0 - PI / 2.0
		var is_five := minute % 5 == 0
		var mark_length := 30.0 if is_five else 14.0
		draw_line(angle_point(angle, CLOCK_RADIUS - 10 - mark_length), angle_point(angle, CLOCK_RADIUS - 10), INK, 8.0 if is_five else 3.0)
	for number in range(1, 13):
		draw_centred_text(str(number), angle_point(TAU * number / 12.0 - PI / 2.0, CLOCK_RADIUS - 92), 76, INK)
	draw_rounded_hand(hour_angle(), CLOCK_RADIUS * 0.5, 30, INK, INK)
	if shows_minute_hand():
		draw_rounded_hand(minute_angle(), CLOCK_RADIUS * 0.8, 16, INK, INK)
	draw_circle(CLOCK_CENTRE, 22, INK)
	draw_circle(CLOCK_CENTRE, 9, CREAM)


# B: a classroom teaching clock. Past half and to half tinted, a small
# minute ring outside the hours, red hour hand and blue minute hand.
func draw_teaching_clock() -> void:
	draw_circle(CLOCK_CENTRE + Vector2(0, 14), CLOCK_RADIUS + 22, Color(0, 0, 0, 0.12))
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS + 22, INK)
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS, Color.WHITE)
	if shows_minute_hand():
		draw_colored_polygon(sector(-PI / 2.0, PI / 2.0, CLOCK_RADIUS - 70), PAST_TINT)
		draw_colored_polygon(sector(PI / 2.0, 3.0 * PI / 2.0, CLOCK_RADIUS - 70), TO_TINT)
		draw_centred_text("past", CLOCK_CENTRE + Vector2(115, 95), 40, MINUTE_HAND_BLUE.darkened(0.2))
		draw_centred_text("to", CLOCK_CENTRE + Vector2(-115, 95), 40, HOUR_HAND_RED.darkened(0.2))
		# minute ring
		draw_arc(CLOCK_CENTRE, CLOCK_RADIUS - 70, 0, TAU, 96, Color(INK, 0.25), 3.0)
		for minute in 60:
			var angle := TAU * minute / 60.0 - PI / 2.0
			draw_circle(angle_point(angle, CLOCK_RADIUS - 22), 7.0 if minute % 5 == 0 else 3.0, MINUTE_HAND_BLUE.darkened(0.15))
		for five in range(1, 12):
			var label := str(five * 5)
			if five == 3 or five == 9: label = "quarter"
			if five == 6: label = "half"
			draw_centred_text(label, angle_point(TAU * five / 12.0 - PI / 2.0, CLOCK_RADIUS - 48), 18 if label.length() > 2 else 28, MINUTE_HAND_BLUE.darkened(0.25))
	for number in range(1, 13):
		draw_centred_text(str(number), angle_point(TAU * number / 12.0 - PI / 2.0, CLOCK_RADIUS - 125), 80, HOUR_HAND_RED.darkened(0.3))
	draw_rounded_hand(hour_angle(), CLOCK_RADIUS * 0.48, 30, HOUR_HAND_RED, INK)
	if shows_minute_hand():
		draw_rounded_hand(minute_angle(), CLOCK_RADIUS * 0.84, 16, MINUTE_HAND_BLUE, INK)
	draw_circle(CLOCK_CENTRE, 22, INK)


# C: Paint Puddle's own clock. Each number sits in its own paint puddle,
# the minute hand is a paintbrush that paints the minutes gone so far, and
# the little hour hand is a stubby blob-coloured hand. A blob in the
# middle watches the brush.
func draw_paint_pots_clock() -> void:
	draw_circle(CLOCK_CENTRE + Vector2(0, 14), CLOCK_RADIUS + 24, Color(0, 0, 0, 0.12))
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS + 24, Color(0.55, 0.8, 0.4).darkened(0.3))
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS + 16, Color(0.55, 0.8, 0.4))
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS, CREAM)
	var minutes_into_hour := fposmod(displayed_minutes, 60.0)
	if shows_minute_hand() and minutes_into_hour > 0.5:
		var brush_colour := MINUTE_HAND_BLUE if minutes_into_hour <= 30.0 else Color(0.62, 0.4, 0.9)
		draw_colored_polygon(sector(-PI / 2.0, minute_angle(), CLOCK_RADIUS - 150), Color(brush_colour, 0.28))
	for minute in 60:
		if minute % 5 != 0:
			draw_circle(angle_point(TAU * minute / 60.0 - PI / 2.0, CLOCK_RADIUS - 24), 5, Color(INK, 0.35))
	for number in range(1, 13):
		var spot := angle_point(TAU * number / 12.0 - PI / 2.0, CLOCK_RADIUS - 78)
		var colour := Color.from_hsv(fposmod(number / 12.0 - 0.02, 1.0), 0.6, 1.0)
		draw_colored_polygon(wobbly_circle(spot, 62, number * 1.7), colour.darkened(0.25))
		draw_colored_polygon(wobbly_circle(spot, 56, number * 1.7), colour)
		draw_circle(spot + Vector2(-20, -22), 9, Color(1, 1, 1, 0.55))
		draw_centred_text(str(number), spot, 64, INK)
	# hour hand: a stubby paint-red hand with a round end
	var hour_tip := angle_point(hour_angle(), CLOCK_RADIUS * 0.46)
	draw_line(CLOCK_CENTRE, hour_tip, INK, 46)
	draw_line(CLOCK_CENTRE, hour_tip, HOUR_HAND_RED, 36)
	draw_circle(hour_tip, 30, INK)
	draw_circle(hour_tip, 25, HOUR_HAND_RED)
	if shows_minute_hand():
		# minute hand: a paintbrush, wooden handle, metal band, painty tip
		var angle := minute_angle()
		var handle_end := angle_point(angle, CLOCK_RADIUS * 0.55)
		var band_end := angle_point(angle, CLOCK_RADIUS * 0.62)
		var bristle_tip := angle_point(angle, CLOCK_RADIUS * 0.8)
		var brush_colour := MINUTE_HAND_BLUE if minutes_into_hour <= 30.0 else Color(0.62, 0.4, 0.9)
		draw_line(CLOCK_CENTRE, handle_end, INK, 26)
		draw_line(CLOCK_CENTRE, handle_end, Color(0.8, 0.58, 0.36), 18)
		draw_line(handle_end, band_end, INK, 30)
		draw_line(handle_end, band_end, Color(0.8, 0.82, 0.88), 22)
		var side := Vector2.from_angle(angle + PI / 2.0)
		var bristles := PackedVector2Array([band_end + side * 15, band_end - side * 15, bristle_tip])
		draw_colored_polygon(PackedVector2Array([band_end + side * 19, band_end - side * 19, bristle_tip + Vector2.from_angle(angle) * 8]), INK)
		draw_colored_polygon(bristles, brush_colour)
	# the blob in the middle, watching the brush (or the hour hand)
	var look := Vector2.from_angle(minute_angle() if shows_minute_hand() else hour_angle())
	draw_colored_polygon(wobbly_circle(CLOCK_CENTRE, 46, 2.0), Color(1.0, 0.36, 0.43).darkened(0.35))
	draw_colored_polygon(wobbly_circle(CLOCK_CENTRE, 42, 2.0), Color(1.0, 0.36, 0.43))
	for eye_side in [-1, 1]:
		var eye := CLOCK_CENTRE + Vector2(eye_side * 14, -8)
		draw_circle(eye, 11, Color.WHITE)
		draw_circle(eye + look * 4, 6, INK)
	draw_arc(CLOCK_CENTRE + Vector2(0, 10), 10, 0.3, PI - 0.3, 12, INK, 3.0)


# ---------------------------------------------------------------- house

func sky_colour(minutes: float) -> Color:
	for index in SKY_KEYS.size() - 1:
		var from: Array = SKY_KEYS[index]
		var to: Array = SKY_KEYS[index + 1]
		if minutes >= from[0] and minutes <= to[0]:
			return (from[1] as Color).lerp(to[1], (minutes - from[0]) / float(to[0] - from[0]))
	return SKY_KEYS[0][1]


func darkness(minutes: float) -> float:
	var sky := sky_colour(minutes)
	return clampf(1.0 - sky.get_luminance() * 1.4, 0.0, 0.7)


func draw_house() -> void:
	var minutes := fposmod(displayed_minutes, MINUTES_PER_DAY)
	var outer := HOUSE_RECT
	# card-style panel so the house reads as one picture
	draw_rect(Rect2(outer.position + Vector2(0, 12), outer.size), Color(0, 0, 0, 0.12))
	draw_rect(outer.grow(10), INK)
	var sky := sky_colour(minutes)
	draw_rect(Rect2(outer.position, Vector2(outer.size.x, GROUND_TOP - outer.position.y)), sky)
	var dark := darkness(minutes)
	if dark > 0.3:
		for star_index in 18:
			var star := outer.position + Vector2(fposmod(star_index * 197.0, outer.size.x - 40) + 20, fposmod(star_index * 83.0, 320) + 30)
			draw_circle(star, 3, Color(1, 1, 0.85, (dark - 0.3) * 2.0))
	# sun by day (6am-6pm), moon by night, both arcing over the house
	var is_day := minutes >= 360 and minutes < 1080
	var arc_progress := fposmod(minutes - 360.0, 720.0) / 720.0
	var body := Vector2(lerpf(outer.position.x + 60, outer.end.x - 60, arc_progress), GROUND_TOP - 120 - sin(arc_progress * PI) * 420)
	if is_day:
		draw_circle(body, 52, Color(1.0, 0.85, 0.25, 0.35))
		draw_circle(body, 40, Color(1.0, 0.85, 0.25))
	else:
		draw_circle(body, 36, Color(0.97, 0.95, 0.82))
		draw_circle(body + Vector2(14, -8), 30, sky)
	# garden
	draw_rect(Rect2(outer.position.x, GROUND_TOP, outer.size.x, outer.end.y - GROUND_TOP), Color(0.55, 0.8, 0.4).darkened(dark * 0.6))
	for flower_index in 7:
		var flower := Vector2(outer.end.x - 320 + flower_index * 42, GROUND_TOP + 30 + (flower_index % 3) * 18)
		draw_circle(flower, 9, Color.from_hsv(flower_index / 7.0, 0.5, 1.0).darkened(dark * 0.6))
	# tree
	var trunk := Rect2(outer.end.x - 150, GROUND_TOP - 170, 34, 170)
	draw_rect(trunk, Color(0.55, 0.38, 0.25).darkened(dark * 0.6))
	draw_colored_polygon(wobbly_circle(Vector2(trunk.get_center().x, GROUND_TOP - 220), 95, 0.7), Color(0.4, 0.72, 0.35).darkened(dark * 0.6))
	# the house cutaway: two floors
	var box := house_box()
	var lamp_on := minutes >= 1080 or minutes < 420
	var wall := Color(1.0, 0.92, 0.8)
	if lamp_on:
		wall = Color(1.0, 0.86, 0.6)
	else:
		wall = wall.darkened(dark * 0.5)
	draw_colored_polygon(PackedVector2Array([box.position + Vector2(-40, 0), Vector2(box.get_center().x, box.position.y - 170), Vector2(box.end.x + 40, box.position.y)]), INK)
	draw_colored_polygon(PackedVector2Array([box.position + Vector2(-26, -8), Vector2(box.get_center().x, box.position.y - 158), Vector2(box.end.x + 26, box.position.y - 8)]), Color(1.0, 0.45, 0.5).darkened(dark * 0.5))
	draw_rect(box.grow(10), INK)
	draw_rect(box, wall)
	var middle := box.position.y + box.size.y * 0.5
	draw_rect(Rect2(box.position.x, middle - 6, box.size.x, 12), INK)
	# beds upstairs
	for bed_x in [box.position.x + 70, box.position.x + 190, box.position.x + 360]:
		draw_rect(Rect2(bed_x, middle - 40, 100, 34), Color(0.3, 0.55, 1.0).lightened(0.3).darkened(dark * 0.4))
		draw_rect(Rect2(bed_x - 6, middle - 70, 14, 64), Color(0.55, 0.38, 0.25))
	# picture window upstairs
	var window := Rect2(box.end.x - 140, box.position.y + 30, 100, 80)
	draw_rect(window.grow(6), INK)
	draw_rect(window, sky)
	# table downstairs
	draw_rect(Rect2(box.position.x + 170, box.end.y - 90, 180, 18), Color(0.55, 0.38, 0.25))
	draw_rect(Rect2(box.position.x + 180, box.end.y - 72, 14, 72), Color(0.55, 0.38, 0.25))
	draw_rect(Rect2(box.position.x + 326, box.end.y - 72, 14, 72), Color(0.55, 0.38, 0.25))
	# moment caption, shown for the confirmed time only
	var hour := int(confirmed_minutes_of_day / 60.0)
	var caption_box := Rect2(outer.position.x + 20, outer.end.y - 90, outer.size.x - 40, 72)
	draw_rect(caption_box, Color(CREAM, 0.92))
	draw_centred_text(MOMENTS[hour][0], caption_box.get_center(), 46, INK)


# ---------------------------------------------------------------- card

func time_words(minutes_of_day: int) -> String:
	var hour_12 := (minutes_of_day / 60) % 12
	var minute := minutes_of_day % 60
	var this_hour := 12 if hour_12 == 0 else hour_12
	var next_hour := (hour_12 % 12) + 1
	if minute == 0: return "%d o'clock" % this_hour
	if minute == 30: return "half past %d" % this_hour
	if minute == 15: return "quarter past %d" % this_hour
	if minute == 45: return "quarter to %d" % next_hour
	if minute < 30: return "%d past %d" % [minute, this_hour]
	return "%d to %d" % [60 - minute, next_hour]


func part_of_day(minutes_of_day: int) -> String:
	if minutes_of_day < 720: return "in the morning"
	if minutes_of_day < 1020: return "in the afternoon"
	if minutes_of_day < 1200: return "in the evening"
	return "at night"


func draw_card() -> void:
	var card := Rect2(120, 30, 760, 130)
	draw_rect(Rect2(card.position + Vector2(0, 8), card.size), Color(0, 0, 0, 0.1))
	draw_rect(card.grow(6), INK)
	draw_rect(card, Color.WHITE)
	var shown := minutes_of_day()
	draw_centred_text(time_words(shown) + " " + part_of_day(shown), card.get_center() + Vector2(0, -16), 48, INK)
	draw_centred_text("am" if shown < 720 else "pm", card.get_center() + Vector2(0, 38), 28, Color(INK, 0.55))


func draw_prototype_bar() -> void:
	var bar := Rect2(260, 1044, 1400, 32)
	draw_rect(bar, Color(0, 0, 0, 0.75))
	draw_centred_text("PROTOTYPE  %s   |  rung %d  |  Q/E face, arrows wind/rung, A confirm" % [VARIANT_NAMES[variant_index], rung_index + 1], bar.get_center(), 18, Color.WHITE)
