class_name ClockJob
extends Node2D
## Which job the card wants, shown round the clock so a 4-year-old can tell
## them apart without reading: an orange ring and an arrow sweeping round
## the top for "wind the clock", a blue ring and no arrow for "look at the
## clock". Nothing between cards, in free play or in the intros' "Watch!".
## The banner wears the same colour and picture (ClockTaskBanner.job).
##
## Drawn round the clock's centre, under the face, so the ring peeks out
## around the rim.

enum Job { NONE, WIND, LOOK }

const WIND_COLOUR: Color = PaintColours.ORANGE
const LOOK_COLOUR: Color = PaintColours.BLUE
const RING_RADIUS: float = ClockFace.RADIUS + ClockFace.RIM_WIDTH + 10.0
const RING_WIDTH: float = 16.0
const ARROW_RADIUS: float = ClockFace.RADIUS + ClockFace.RIM_WIDTH + 44.0
const ARROW_WIDTH: float = 16.0
## The arrow runs from 12 towards 2 o'clock, round the way the hands go.
const ARROW_START_ANGLE: float = deg_to_rad(8.0)
const ARROW_END_ANGLE: float = deg_to_rad(52.0)
const ARROW_NUDGE_ANGLE: float = deg_to_rad(6.0)
const FADE_SPEED: float = 4.0

var job: Job = Job.NONE
## How strongly each ring shows, 0 to 1, so a change of job fades across.
var wind_strength: float = 0.0
var look_strength: float = 0.0
var time_shown: float = 0.0


static func colour_for(for_job: Job) -> Color:
	return WIND_COLOUR if for_job == Job.WIND else LOOK_COLOUR


func _process(delta: float) -> void:
	time_shown += delta
	wind_strength = move_toward(wind_strength, 1.0 if job == Job.WIND else 0.0, FADE_SPEED * delta)
	look_strength = move_toward(look_strength, 1.0 if job == Job.LOOK else 0.0, FADE_SPEED * delta)
	queue_redraw()


func _draw() -> void:
	if look_strength > 0.0:
		draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 128, Color(LOOK_COLOUR, look_strength), RING_WIDTH, true)
	if wind_strength > 0.0:
		draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 128, Color(WIND_COLOUR, wind_strength), RING_WIDTH, true)
		draw_wind_arrow(Color(WIND_COLOUR.darkened(0.15), wind_strength))


## A curved arrow outside the rim, nudging round clockwise again and again.
func draw_wind_arrow(colour: Color) -> void:
	var nudge: float = absf(sin(time_shown * 3.0)) * ARROW_NUDGE_ANGLE
	var start: float = ARROW_START_ANGLE + nudge
	var end: float = ARROW_END_ANGLE + nudge
	# Angles here count from 12 o'clock; draw_arc counts from 3 o'clock
	draw_arc(Vector2.ZERO, ARROW_RADIUS, start - PI / 2.0, end - PI / 2.0, 32, colour, ARROW_WIDTH, true)
	var tip_direction: Vector2 = Vector2.from_angle(end - PI / 2.0)
	var along: Vector2 = tip_direction.orthogonal() * -1.0
	var base_centre: Vector2 = tip_direction * ARROW_RADIUS
	var tip: Vector2 = base_centre + along * 30.0
	draw_colored_polygon(PackedVector2Array([tip, base_centre + tip_direction * 22.0, base_centre - tip_direction * 22.0]), colour)
