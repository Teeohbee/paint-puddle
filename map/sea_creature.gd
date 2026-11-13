class_name SeaCreature
extends Node2D
## The whale, or two dolphins, up at one spot for a few seconds and then gone.
## The whale rises, spouts and dives; the dolphins leap twice each. Everything
## is drawn from progress (0 to 1), which a tween runs once.

signal finished

enum Kind { WHALE, DOLPHINS }

const SECONDS: float = 4.5
const WHALE_SIZE: float = 0.4
const DOLPHIN_SIZES: Array[float] = [0.55, 0.45]
## The second dolphin is a little behind and to the right of the first.
const DOLPHIN_OFFSETS: Array[Vector2] = [Vector2.ZERO, Vector2(50, -15)]
const DOLPHIN_DELAYS: Array[float] = [0.0, 0.12]
## Each leap takes this much of the progress; the second leap starts LEAP_GAP after the first.
const LEAP_LENGTH: float = 0.35
const LEAP_GAP: float = 0.4
const LEAP_WIDTH: float = 140.0
const LEAP_HEIGHT: float = 60.0
const SINK_DEPTH: float = 30.0

const WHALE_BODY: String = "M-120 14 C-110 -34 -50 -48 10 -34 C56 -24 84 -4 96 18 C60 36 -20 42 -120 14Z"
const WHALE_BELLY: String = "M-96 18 C-30 36 40 34 90 20 C60 40 -30 44 -96 18Z"
const WHALE_TAIL: String = "M96 18 C120 4 140 -14 148 -36 C152 -8 150 14 132 36 C122 28 112 26 96 18Z"
const WHALE_SPOUTS: Array[String] = ["M-14 -18 C-22 -60 -4 -78 8 -96", "M-14 -18 C-6 -62 14 -70 26 -90"]
const DOLPHIN_BODY: String = "M-44 8 C-30 -22 8 -30 38 -12 L58 -22 L54 2 L62 14 L40 8 C20 22 -22 24 -44 8Z"
const DOLPHIN_SNOUT: String = "M-34 -6 L-64 4 L-36 12Z"
const DOLPHIN_FIN: String = "M-4 -22 L4 -36 L10 -20Z"
const DOLPHIN_BELLY: String = "M-30 12 C-8 20 20 18 36 8 C18 24 -14 26 -30 12Z"

const WHALE_COLOUR: Color = Color("#4f7fc9")
const WHALE_EDGE: Color = Color("#34609f")
const DOLPHIN_COLOUR: Color = Color("#5b8bd6")
const DOLPHIN_SNOUT_COLOUR: Color = Color("#6f9be0")
const DOLPHIN_FIN_COLOUR: Color = Color("#4a78c4")
const DOLPHIN_EDGE: Color = Color("#3a64a8")
const BELLY_COLOUR: Color = Color("#e8f1ff")
const EYE_COLOUR: Color = Color("#1d2b4a")
const WATER_COLOUR: Color = Color(1, 1, 1, 0.75)

var kind: Kind = Kind.WHALE
var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()


static func make(creature_kind: Kind, spot: Vector2) -> SeaCreature:
	var creature: SeaCreature = SeaCreature.new()
	creature.kind = creature_kind
	creature.position = spot
	return creature


func play() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "progress", 1.0, SECONDS).from(0.0)
	tween.tween_callback(func() -> void:
		finished.emit()
		queue_free())


## 0 to 1 over the part of progress from start to end, eased.
static func stage(at: float, start: float, end: float) -> float:
	return smoothstep(start, end, at)


func _draw() -> void:
	if kind == Kind.WHALE:
		draw_whale()
	else:
		for index in DOLPHIN_SIZES.size():
			draw_dolphin_leaps(index)


func draw_whale() -> void:
	var rise: float = stage(progress, 0.0, 0.2)
	var dive: float = stage(progress, 0.8, 1.0)
	var showing: float = rise * (1.0 - dive)
	if showing <= 0.0:
		return
	var sink: float = SINK_DEPTH * ((1.0 - rise) + dive)
	draw_set_transform(Vector2(0, sink), -dive * 0.15, Vector2.ONE * WHALE_SIZE)
	var spout: float = sin(PI * clampf((progress - 0.25) / 0.5, 0.0, 1.0))
	if spout > 0.0:
		var spout_colour: Color = Color(1, 1, 1, 0.9 * spout * showing)
		var spout_base: Vector2 = Vector2(-14, -18)
		for path in WHALE_SPOUTS:
			var line: PackedVector2Array = SeaArt.outline(path)
			for point_index in line.size():
				line[point_index] = spout_base + (line[point_index] - spout_base) * spout
			draw_polyline(line, spout_colour, 8.0, true)
		draw_circle(spout_base + (Vector2(-10, -100) - spout_base) * spout, 10.0 * spout, Color(1, 1, 1, 0.85 * spout * showing))
		draw_circle(spout_base + (Vector2(26, -94) - spout_base) * spout, 8.0 * spout, Color(1, 1, 1, 0.85 * spout * showing))
	SeaArt.draw_shape(self, SeaArt.outline(WHALE_BODY), faded(WHALE_COLOUR, showing), faded(WHALE_EDGE, showing), 5.0)
	draw_colored_polygon(SeaArt.outline(WHALE_BELLY), faded(BELLY_COLOUR, showing))
	SeaArt.draw_shape(self, SeaArt.outline(WHALE_TAIL), faded(WHALE_COLOUR, showing), faded(WHALE_EDGE, showing), 5.0)
	draw_circle(Vector2(-76, -4), 5.5, faded(EYE_COLOUR, showing))
	draw_circle(Vector2(-77.5, -5.5), 2.0, faded(Color.WHITE, showing))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * WHALE_SIZE)
	var water: Color = faded(WATER_COLOUR, showing)
	draw_polyline(curve(Vector2(-130, 30), Vector2(-90, 42), Vector2(-50, 36)), water, 6.0, true)
	draw_polyline(curve(Vector2(30, 40), Vector2(70, 50), Vector2(120, 38)), water, 6.0, true)
	draw_set_transform(Vector2.ZERO)


## One dolphin, leaping twice from right to left, head first.
func draw_dolphin_leaps(index: int) -> void:
	for leap in 2:
		var start: float = DOLPHIN_DELAYS[index] + leap * LEAP_GAP
		var leap_progress: float = (progress - start) / LEAP_LENGTH
		draw_splash(index, leap_progress)
		if leap_progress <= 0.0 or leap_progress >= 1.0:
			continue
		var height: float = sin(PI * leap_progress)
		var centre: Vector2 = DOLPHIN_OFFSETS[index] + Vector2(lerpf(LEAP_WIDTH / 2.0, -LEAP_WIDTH / 2.0, leap_progress), 10.0 - LEAP_HEIGHT * height)
		var velocity: Vector2 = Vector2(-LEAP_WIDTH, -LEAP_HEIGHT * PI * cos(PI * leap_progress))
		var showing: float = clampf(height * 4.0, 0.0, 1.0)
		draw_set_transform(centre, atan2(-velocity.y, -velocity.x), Vector2.ONE * DOLPHIN_SIZES[index])
		SeaArt.draw_shape(self, SeaArt.outline(DOLPHIN_BODY), faded(DOLPHIN_COLOUR, showing), faded(DOLPHIN_EDGE, showing), 4.0)
		SeaArt.draw_shape(self, SeaArt.outline(DOLPHIN_SNOUT), faded(DOLPHIN_SNOUT_COLOUR, showing), faded(DOLPHIN_EDGE, showing), 3.0)
		SeaArt.draw_shape(self, SeaArt.outline(DOLPHIN_FIN), faded(DOLPHIN_FIN_COLOUR, showing), faded(DOLPHIN_EDGE, showing), 3.0)
		draw_colored_polygon(SeaArt.outline(DOLPHIN_BELLY), faded(BELLY_COLOUR, showing))
		draw_circle(Vector2(-22, -6), 3.0, faded(EYE_COLOUR, showing))
		draw_set_transform(Vector2.ZERO)


## A white curl on the water where a dolphin leaves it, and again where it goes back in.
func draw_splash(index: int, leap_progress: float) -> void:
	for end in [0.0, 1.0]:
		var since: float = absf(leap_progress - end)
		if since > 0.3:
			continue
		var strength: float = 1.0 - since / 0.3
		var x: float = lerpf(LEAP_WIDTH / 2.0, -LEAP_WIDTH / 2.0, end)
		var at: Vector2 = DOLPHIN_OFFSETS[index] + Vector2(x, 12)
		var width: float = 26.0 * (0.6 + 0.4 * strength)
		draw_polyline(curve(at - Vector2(width, 0), at + Vector2(0, 5), at + Vector2(width, -2)), faded(WATER_COLOUR, strength), 3.0, true)


func faded(colour: Color, amount: float) -> Color:
	return Color(colour, colour.a * amount)


static func curve(start: Vector2, control: Vector2, end: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for step in 9:
		var weight: float = step / 8.0
		points.append(start.lerp(control, weight).lerp(control.lerp(end, weight), weight))
	return points
