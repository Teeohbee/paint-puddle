class_name ClockNumberLineIntro
extends Node2D
## Opens Play with the clock, every time: a 1-12 number line, then its
## numbers hop off one at a time, in order, round into their places on the
## face - so the hours of the line go round the clock (the way Year 1 builds
## a clock from a number line). Then the hour hand ticks from 12 round to 7 in
## the morning.
## About 7 seconds: slow hops, worth watching, then quick ticks. Any button
## skips straight to the end. Then it's his turn (ClockMode.on_intro_finished).
##
## Drawn round the clock's centre, over the face, which stays hidden until the
## line has curled.

signal finished

const SECONDS_TO_SHOW_THE_LINE: float = 0.6
## The straight line sits still for a moment, so it's seen as a line first.
const SECONDS_TO_HOLD_THE_LINE: float = 0.8
const SECONDS_TO_CURL: float = 4.5
const SECONDS_PER_TICK: float = 0.18
const LINE_Y: float = 250.0
const LINE_HALF_WIDTH: float = 420.0
## Each number's hop, as a share of the whole curl; the next one sets off this much later.
const HOP_SHARE: float = 0.3
const HOP_GAP: float = (1.0 - HOP_SHARE) / 11.0
const STARTING_HOUR: int = 7

var clock_face: ClockFace
## 0 is the straight line, 1 is every number on the face.
var curl: float = 0.0
var line_opacity: float = 0.0
var sequence: Tween
var playing: bool = false


func _init(face: ClockFace) -> void:
	clock_face = face


func play() -> void:
	playing = true
	curl = 0.0
	line_opacity = 0.0
	clock_face.visible = false
	clock_face.jump_to(0)
	sequence = create_tween()
	sequence.tween_property(self, "line_opacity", 1.0, SECONDS_TO_SHOW_THE_LINE)
	sequence.tween_property(self, "curl", 1.0, SECONDS_TO_CURL).set_delay(SECONDS_TO_HOLD_THE_LINE)
	sequence.tween_callback(show_the_face)
	for hour in range(1, STARTING_HOUR + 1):
		sequence.tween_callback(tick_to.bind(hour)).set_delay(SECONDS_PER_TICK)
	sequence.tween_callback(end).set_delay(SECONDS_PER_TICK)


func is_playing() -> bool:
	return playing


## Straight to the end: the face shows 7 in the morning.
func skip() -> void:
	if not playing:
		return
	if sequence != null:
		sequence.kill()
	show_the_face()
	tick_to(STARTING_HOUR, false)
	end()


func show_the_face() -> void:
	clock_face.visible = true
	line_opacity = 0.0
	queue_redraw()


func tick_to(hour: int, with_sound: bool = true) -> void:
	clock_face.jump_to(hour * ClockTime.MINUTES_IN_AN_HOUR)
	if with_sound:
		Sound.play("tick", 0.02, 1.0 + hour * 0.03)


func end() -> void:
	if not playing:
		return
	playing = false
	queue_redraw()
	finished.emit()


func _process(_delta: float) -> void:
	if playing and line_opacity > 0.0:
		queue_redraw()


## How far a number is on its hop from the line to the face, 0 to 1.
## 1 goes first, 12 last.
func hop_progress(number: int) -> float:
	var progress: float = clampf((curl - (number - 1) * HOP_GAP) / HOP_SHARE, 0.0, 1.0)
	return progress * progress * (3.0 - 2.0 * progress)


func spot_on_the_line(number: int) -> Vector2:
	return Vector2(-LINE_HALF_WIDTH + LINE_HALF_WIDTH * 2.0 * (number - 1) / 11.0, LINE_Y)


## Where the number goes on the face.
func spot_on_the_face(number: int) -> Vector2:
	return ClockFace.point_at(ClockFace.angle_of_turns(number / 12.0), ClockFace.RADIUS - 90)


## On the line, on the face, or on a little arc between them.
func number_spot(number: int) -> Vector2:
	var progress: float = hop_progress(number)
	var lift: Vector2 = Vector2(0, -sin(progress * PI) * 90.0)
	return spot_on_the_line(number).lerp(spot_on_the_face(number), progress) + lift


func _draw() -> void:
	if line_opacity <= 0.0:
		return
	var font: Font = clock_face.game_font()
	# The line fades as its numbers leave it; a ring shows where they're going
	var line_colour: Color = Color(PaintColours.INK, line_opacity * (1.0 - curl))
	draw_line(spot_on_the_line(1), spot_on_the_line(12), line_colour, 8.0, true)
	draw_arc(Vector2.ZERO, ClockFace.RADIUS, 0.0, TAU, 96, Color(PaintColours.INK, line_opacity * curl * 0.6), 6.0, true)
	for number in range(1, 13):
		draw_circle(spot_on_the_line(number), 7.0, line_colour)
	for number in range(1, 13):
		var label: String = str(number)
		var opacity: float = line_opacity
		var colour: Color = ClockFace.number_colour(number).darkened(0.15)
		var size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, ClockFace.NUMBER_FONT_SIZE)
		# Above its dot on the line, centred on its place on the face
		var centre: Vector2 = number_spot(number) + Vector2(0, -50).lerp(Vector2.ZERO, hop_progress(number))
		draw_string(font, centre + Vector2(-size.x / 2.0, ClockFace.NUMBER_FONT_SIZE * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, ClockFace.NUMBER_FONT_SIZE, Color(colour, opacity))
