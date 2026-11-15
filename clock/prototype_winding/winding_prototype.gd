# PROTOTYPE - throwaway. Answers "how should winding the clock feel on the D-pad?"
# for the Clock mode map (Winding the hands, issue #86). Not production code.
#
# Left/right: wind (one press = one step). Hold to keep winding.
# Up/down: change rung (step size, hour-hand-only on rungs 1-2).
# Shoulder buttons or Q/E: switch hold variant.
# A (act): confirm the time. Pause/Start: quit.
extends Node2D

const MINUTES_PER_DAY := 1440
const RUNG_STEP_MINUTES := [60, 30, 30, 15, 15, 5, 5, 1]
const RUNG_HIDES_MINUTE_HAND := [true, true, false, false, false, false, false, false]

const HOLD_VARIANT_NAMES := [
	"1 Steady repeat",
	"2 Exponential repeat (capped)",
	"3 Exponential, slows near target",
	"4 Gear up: hold long and steps become hours",
]

const FIRST_REPEAT_DELAY_SECONDS := 0.35
const STEADY_REPEAT_INTERVAL_SECONDS := 0.15
const EXPONENTIAL_START_INTERVAL_SECONDS := 0.18
const EXPONENTIAL_SHRINK_PER_REPEAT := 0.82
const EXPONENTIAL_FASTEST_INTERVAL_SECONDS := 0.025
const SLOW_NEAR_TARGET_STEPS := 3
const SLOW_NEAR_TARGET_INTERVAL_SECONDS := 0.3
const GEAR_UP_AFTER_REPEATS := 6

const CLOCK_CENTRE := Vector2(540, 500)
const CLOCK_RADIUS := 360.0
const HOUSE_RECT := Rect2(1040, 300, 800, 600)

const MOMENTS := [
	[0, "Shooting stars"], [1, "Asleep"], [2, "Little blob gets up for a drink"],
	[3, "Asleep"], [4, "Hedgehog in the garden"], [5, "Asleep"], [6, "Dawn birds"],
	[7, "Wake up"], [8, "Breakfast"], [9, "Off to the park"], [10, "Playing"], [11, "Playing"],
	[12, "Lunch"], [13, "Quiet time"], [14, "Painting"], [15, "Garden"], [16, "Snack"],
	[17, "Tea"], [18, "Bath"], [19, "Story"], [20, "Bed"], [21, "Owl"], [22, "Asleep"],
	[23, "Fox at the bins"],
]

var rung_index := 5
var hold_variant_index := 1

# Total minutes wound, unbounded so the hands can sweep smoothly across midnight.
var wound_minutes := 7 * 60
var displayed_minutes := float(7 * 60)
var target_minutes_of_day := 0

var held_direction := 0
var held_seconds := 0.0
var next_repeat_at_seconds := 0.0
var repeats_this_hold := 0
var last_repeat_interval_seconds := 0.0

var presses_this_card := 0
var overshoots_this_card := 0
var seconds_this_card := 0.0
var finished_card_log: Array[String] = []
var feedback_text := ""
var revealed_moment_text := "Wake up"
var waiting_for_next_card := false

var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	deal_new_target()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			change_hold_variant(-1)
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			change_hold_variant(1)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			change_hold_variant(-1)
		elif event.keycode == KEY_E:
			change_hold_variant(1)


func _process(delta: float) -> void:
	if not waiting_for_next_card:
		seconds_this_card += delta

	if Input.is_action_just_pressed("pause"):
		get_tree().quit()

	if Input.is_action_just_pressed("move_up"):
		change_rung(1)
	elif Input.is_action_just_pressed("move_down"):
		change_rung(-1)

	if Input.is_action_just_pressed("act") and not waiting_for_next_card:
		confirm_time()

	update_winding(delta)

	var smoothing := 1.0 - exp(-delta * 16.0)
	displayed_minutes += (wound_minutes - displayed_minutes) * smoothing
	queue_redraw()


func update_winding(delta: float) -> void:
	var direction := 0
	if Input.is_action_pressed("move_right"):
		direction += 1
	if Input.is_action_pressed("move_left"):
		direction -= 1

	if direction == 0 or waiting_for_next_card:
		held_direction = 0
		return

	if direction != held_direction:
		held_direction = direction
		held_seconds = 0.0
		repeats_this_hold = 0
		next_repeat_at_seconds = FIRST_REPEAT_DELAY_SECONDS
		last_repeat_interval_seconds = 0.0
		presses_this_card += 1
		wind_one_step(direction)
		return

	held_seconds += delta
	while held_seconds >= next_repeat_at_seconds:
		wind_one_step(direction)
		repeats_this_hold += 1
		last_repeat_interval_seconds = repeat_interval_for_current_hold(direction)
		next_repeat_at_seconds += last_repeat_interval_seconds


func repeat_interval_for_current_hold(direction: int) -> float:
	match hold_variant_index:
		0:
			return STEADY_REPEAT_INTERVAL_SECONDS
		1:
			return exponential_interval()
		2:
			if steps_to_target(direction) <= SLOW_NEAR_TARGET_STEPS:
				return SLOW_NEAR_TARGET_INTERVAL_SECONDS
			return exponential_interval()
		_:
			return STEADY_REPEAT_INTERVAL_SECONDS


func exponential_interval() -> float:
	var interval := EXPONENTIAL_START_INTERVAL_SECONDS * pow(EXPONENTIAL_SHRINK_PER_REPEAT, repeats_this_hold)
	return max(interval, EXPONENTIAL_FASTEST_INTERVAL_SECONDS)


func current_step_minutes() -> int:
	var rung_step: int = RUNG_STEP_MINUTES[rung_index]
	var gear_up_variant := hold_variant_index == 3
	if gear_up_variant and repeats_this_hold >= GEAR_UP_AFTER_REPEATS and rung_step < 60:
		return 60
	return rung_step


func wind_one_step(direction: int) -> void:
	var minutes_before := wound_minutes
	wound_minutes += direction * current_step_minutes()
	if passed_through_target(minutes_before, wound_minutes):
		overshoots_this_card += 1
	feedback_text = ""
	Sound.play("pick", 0.02, 1.0 + 0.15 * direction)


func passed_through_target(minutes_before: int, minutes_after: int) -> bool:
	# A held step that leaves the target or jumps past it, without stopping on it.
	if repeats_this_hold == 0:
		return false
	var direction := signi(minutes_after - minutes_before)
	var whole_minutes := minutes_before
	while whole_minutes != minutes_after:
		if posmod(whole_minutes, MINUTES_PER_DAY) == target_minutes_of_day:
			return true
		whole_minutes += direction
	return false


func steps_to_target(direction: int) -> int:
	var minutes_of_day := posmod(wound_minutes, MINUTES_PER_DAY)
	var distance := posmod((target_minutes_of_day - minutes_of_day) * direction, MINUTES_PER_DAY)
	return int(ceil(float(distance) / RUNG_STEP_MINUTES[rung_index]))


func change_rung(change: int) -> void:
	rung_index = clamp(rung_index + change, 0, RUNG_STEP_MINUTES.size() - 1)
	var step: int = RUNG_STEP_MINUTES[rung_index]
	wound_minutes = int(floor(float(wound_minutes) / step)) * step
	deal_new_target()


func change_hold_variant(change: int) -> void:
	hold_variant_index = posmod(hold_variant_index + change, HOLD_VARIANT_NAMES.size())


func deal_new_target() -> void:
	var step: int = RUNG_STEP_MINUTES[rung_index]
	var current_minutes_of_day := posmod(wound_minutes, MINUTES_PER_DAY)
	var candidate := current_minutes_of_day
	while candidate == current_minutes_of_day:
		candidate = randi_range(0, MINUTES_PER_DAY / step - 1) * step
	target_minutes_of_day = candidate
	presses_this_card = 0
	overshoots_this_card = 0
	seconds_this_card = 0.0
	waiting_for_next_card = false


func confirm_time() -> void:
	var minutes_of_day := posmod(wound_minutes, MINUTES_PER_DAY)
	revealed_moment_text = moment_name(minutes_of_day)
	if minutes_of_day == target_minutes_of_day:
		feedback_text = "Yes! " + spoken_time(minutes_of_day)
		Sound.play("bell")
		finished_card_log.push_front("%s  %d presses  %.1fs  %d overshoots" % [
			spoken_time(target_minutes_of_day), presses_this_card, seconds_this_card, overshoots_this_card])
		if finished_card_log.size() > 6:
			finished_card_log.pop_back()
		waiting_for_next_card = true
		await get_tree().create_timer(1.4).timeout
		feedback_text = ""
		deal_new_target()
	else:
		feedback_text = "That's " + spoken_time(minutes_of_day) + ". Try again!"
		Sound.play("plop")


func moment_name(minutes_of_day: int) -> String:
	return MOMENTS[minutes_of_day / 60][1]


func part_of_day(minutes_of_day: int) -> String:
	var hour := minutes_of_day / 60
	if hour < 12:
		return "in the morning"
	if hour < 17:
		return "in the afternoon"
	if hour < 20:
		return "in the evening"
	return "at night"


func am_or_pm(minutes_of_day: int) -> String:
	return "am" if minutes_of_day < 720 else "pm"


func spoken_clock_time(minutes_of_day: int) -> String:
	var hour_on_face := (minutes_of_day / 60) % 12
	if hour_on_face == 0:
		hour_on_face = 12
	var next_hour_on_face := hour_on_face % 12 + 1
	var minute := minutes_of_day % 60
	if minute == 0:
		return "%d o'clock" % hour_on_face
	if minute == 30:
		return "half past %d" % hour_on_face
	if minute == 15:
		return "quarter past %d" % hour_on_face
	if minute == 45:
		return "quarter to %d" % next_hour_on_face
	if minute < 30:
		return "%d past %d" % [minute, hour_on_face]
	return "%d to %d" % [60 - minute, next_hour_on_face]


func spoken_time(minutes_of_day: int) -> String:
	return spoken_clock_time(minutes_of_day) + " " + part_of_day(minutes_of_day)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("f6efe2"))
	draw_house()
	draw_clock()
	draw_card()
	draw_state_panel()


func sky_colour(minutes_of_day: float) -> Color:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.22, 0.28, 0.36, 0.72, 0.8, 0.88, 1.0])
	gradient.colors = PackedColorArray([
		Color("141a3a"), Color("1c2550"), Color("f2a65a"), Color("8fd3ff"),
		Color("8fd3ff"), Color("f08a5d"), Color("2a2f63"), Color("141a3a")])
	return gradient.sample(minutes_of_day / MINUTES_PER_DAY)


func draw_house() -> void:
	# Sky follows the hands live; the moment text only changes on confirm.
	var minutes_of_day := fposmod(displayed_minutes, MINUTES_PER_DAY)
	draw_rect(HOUSE_RECT, sky_colour(minutes_of_day))
	var hour := minutes_of_day / 60.0
	var sun_is_up := hour >= 6.0 and hour < 20.0
	var arc_progress := (hour - 6.0) / 14.0 if sun_is_up else fposmod(hour - 20.0, 24.0) / 10.0
	var arc_centre := HOUSE_RECT.position + Vector2(HOUSE_RECT.size.x / 2, 400)
	var arc_angle := PI + arc_progress * PI
	var body_position := arc_centre + Vector2(cos(arc_angle), sin(arc_angle)) * 300
	if sun_is_up:
		draw_circle(body_position, 44, Color("ffd34d"))
	else:
		draw_circle(body_position, 36, Color("f4f1d0"))
	var ground_top := HOUSE_RECT.position.y + 420
	draw_rect(Rect2(HOUSE_RECT.position.x, ground_top, HOUSE_RECT.size.x, HOUSE_RECT.end.y - ground_top), Color("6fbf5f"))
	var house_box := Rect2(HOUSE_RECT.position.x + 220, ground_top - 220, 360, 220)
	draw_rect(house_box, Color("e9c9a8"))
	var window_colour := Color("ffe59a") if not sun_is_up else Color("cfe9ff")
	draw_rect(Rect2(house_box.position + Vector2(50, 60), Vector2(90, 80)), window_colour)
	draw_rect(Rect2(house_box.position + Vector2(220, 60), Vector2(90, 80)), window_colour)
	draw_colored_polygon(PackedVector2Array([
		house_box.position + Vector2(-30, 0), house_box.position + Vector2(180, -130),
		house_box.position + Vector2(390, 0)]), Color("c0574b"))
	draw_string(font, Vector2(HOUSE_RECT.position.x, HOUSE_RECT.end.y - 40), revealed_moment_text,
		HORIZONTAL_ALIGNMENT_CENTER, HOUSE_RECT.size.x, 52, Color("1d2b1a"))


func draw_clock() -> void:
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS + 14, Color("3a3a5a"))
	draw_circle(CLOCK_CENTRE, CLOCK_RADIUS, Color.WHITE)
	for minute_mark in 60:
		var angle := minute_mark / 60.0 * TAU - PI / 2
		var direction := Vector2(cos(angle), sin(angle))
		var mark_length := 28.0 if minute_mark % 5 == 0 else 12.0
		var mark_width := 6.0 if minute_mark % 5 == 0 else 3.0
		draw_line(CLOCK_CENTRE + direction * (CLOCK_RADIUS - mark_length), CLOCK_CENTRE + direction * (CLOCK_RADIUS - 4),
			Color("3a3a5a"), mark_width)
	for number in range(1, 13):
		var angle := number / 12.0 * TAU - PI / 2
		var number_position := CLOCK_CENTRE + Vector2(cos(angle), sin(angle)) * (CLOCK_RADIUS - 75)
		draw_string(font, number_position + Vector2(-40, 22), str(number), HORIZONTAL_ALIGNMENT_CENTER, 80, 60, Color("3a3a5a"))

	var hour_angle := fposmod(displayed_minutes, 720.0) / 720.0 * TAU - PI / 2
	var minute_angle := fposmod(displayed_minutes, 60.0) / 60.0 * TAU - PI / 2
	draw_line(CLOCK_CENTRE, CLOCK_CENTRE + Vector2(cos(hour_angle), sin(hour_angle)) * CLOCK_RADIUS * 0.5,
		Color("d9534f"), 24)
	if not RUNG_HIDES_MINUTE_HAND[rung_index]:
		draw_line(CLOCK_CENTRE, CLOCK_CENTRE + Vector2(cos(minute_angle), sin(minute_angle)) * CLOCK_RADIUS * 0.82,
			Color("2f6fd6"), 12)
	draw_circle(CLOCK_CENTRE, 18, Color("3a3a5a"))


func draw_card() -> void:
	var card_text := "Make it " + spoken_time(target_minutes_of_day)
	draw_string(font, Vector2(60, 950), card_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color("222222"))
	draw_string(font, Vector2(60, 995), am_or_pm(target_minutes_of_day), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("777777"))
	if feedback_text != "":
		draw_string(font, Vector2(60, 1050), feedback_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("2f6fd6"))


func draw_state_panel() -> void:
	var minutes_of_day := posmod(wound_minutes, MINUTES_PER_DAY)
	var lines := [
		"PROTOTYPE  Winding the hands",
		"Rung %d  (step %d min%s)   up/down" % [rung_index + 1, RUNG_STEP_MINUTES[rung_index],
			", hour hand only" if RUNG_HIDES_MINUTE_HAND[rung_index] else ""],
		"Hold: %s   LB/RB or Q/E" % HOLD_VARIANT_NAMES[hold_variant_index],
		"Clock %02d:%02d   target %02d:%02d" % [minutes_of_day / 60, minutes_of_day % 60,
			target_minutes_of_day / 60, target_minutes_of_day % 60],
		"Held %.1fs  repeats %d  interval %.3fs  step now %d" % [held_seconds if held_direction != 0 else 0.0,
			repeats_this_hold, last_repeat_interval_seconds, current_step_minutes()],
		"This card: %d presses  %.1fs  %d overshoots" % [presses_this_card, seconds_this_card, overshoots_this_card],
		"Finished cards:",
	]
	lines.append_array(finished_card_log)
	var line_y := 34.0
	for line in lines:
		draw_string(font, Vector2(1040, line_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("555555"))
		line_y += 26.0
