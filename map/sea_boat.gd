class_name SeaBoat
extends Node2D
## One little boat on the world map, sailing slowly to and fro along its lane.
## It turns round at each end, bobs on the water and leaves a wake. Drawn
## facing right in the mock's units, then shrunk and flipped to face its way.

const SIZE_OF_KIND: Dictionary = {
	SeaLifeData.Kind.SAILING_BOAT: 0.28,
	SeaLifeData.Kind.CARGO_SHIP: 0.3,
	SeaLifeData.Kind.DINGHY: 0.34,
}
const BOB_HEIGHT: float = 2.5
const BOB_SPEED: float = 1.6
const ROCK_ANGLE: float = 0.04
## How quickly it swings round at the end of its lane (a full flip takes 1 / TURN_SPEED * 2 seconds).
const TURN_SPEED: float = 2.5
const WAKE_SPEED: float = 0.6
const EDGE: Color = Color(0, 0, 0, 0.2)
const HULL_EDGE: Color = Color(0, 0, 0, 0.27)
const WAKE_COLOUR: Color = Color(1, 1, 1, 0.85)
const MAST_COLOUR: Color = Color("#8a6a4a")
const BRIDGE_COLOUR: Color = Color.WHITE
const WINDOW_COLOUR: Color = Color("#7fb7e8")

const SAILING_HULL: String = "M-62 4 L58 4 C50 28 30 38 6 38 L-30 38 C-48 36 -58 22 -62 4Z"
const SAILING_MAIN_SAIL: String = "M-4 -80 C30 -66 44 -34 46 -6 L-4 -6Z"
const SAILING_FRONT_SAIL: String = "M-8 -66 C-30 -50 -40 -28 -44 -6 L-8 -6Z"
const CARGO_HULL: String = "M-76 -6 L66 -6 C58 18 40 26 18 26 L-52 26 C-66 24 -72 12 -76 -6Z"
const DINGHY_HULL: String = "M-40 0 L40 0 C34 18 20 24 0 24 L-22 24 C-34 22 -38 12 -40 0Z"
const DINGHY_SAIL: String = "M0 -34 L26 -6 L0 -6Z"

var kind: SeaLifeData.Kind = SeaLifeData.Kind.SAILING_BOAT
var lane_from: Vector2 = Vector2.ZERO
var lane_to: Vector2 = Vector2.ZERO
var hull_colour: Color = Color.WHITE
var sail_colour: Color = Color.WHITE
var sail_2_colour: Color = Color.WHITE
## Pixels a second along the lane.
var speed: float = 15.0
## 0 at the lane's start, 1 at its end.
var along: float = 0.0
## 1 sailing towards the lane's end, -1 back towards its start.
var heading: float = 1.0
## 1 facing right, -1 facing left, in between while swinging round.
var facing: float = 1.0
var time: float = 0.0
var bob_phase: float = 0.0


static func make(lane: Dictionary, boat_speed: float, start_along: float, start_heading: float, start_bob_phase: float) -> SeaBoat:
	var boat: SeaBoat = SeaBoat.new()
	boat.kind = lane["kind"]
	boat.lane_from = lane["from"]
	boat.lane_to = lane["to"]
	boat.hull_colour = lane["hull"]
	boat.sail_colour = lane["sail"]
	boat.sail_2_colour = lane.get("sail_2", lane["sail"])
	boat.speed = boat_speed
	boat.along = start_along
	boat.heading = start_heading
	boat.bob_phase = start_bob_phase
	boat.facing = boat.wanted_facing()
	boat.place()
	return boat


func _process(delta: float) -> void:
	time += delta
	var lane_length: float = maxf(lane_from.distance_to(lane_to), 1.0)
	along += heading * speed * delta / lane_length
	if along >= 1.0 or along <= 0.0:
		along = clampf(along, 0.0, 1.0)
		heading = -heading
	facing = move_toward(facing, wanted_facing(), TURN_SPEED * delta)
	place()
	queue_redraw()


## Bow first: right when the way it's going is rightwards.
func wanted_facing() -> float:
	var sideways: float = (lane_to.x - lane_from.x) * heading
	return -1.0 if sideways < 0.0 else 1.0


func place() -> void:
	position = lane_from.lerp(lane_to, along) + Vector2(0, sin(time * BOB_SPEED + bob_phase) * BOB_HEIGHT)
	rotation = sin(time * BOB_SPEED * 0.8 + bob_phase) * ROCK_ANGLE
	var size: float = SIZE_OF_KIND[kind]
	# Never quite flat while swinging round, so the transform can always be inverted.
	var width: float = facing if absf(facing) > 0.05 else 0.05 * signf(facing + 0.0001)
	scale = Vector2(size * width, size)


func _draw() -> void:
	var wake_phase: float = time * WAKE_SPEED
	match kind:
		SeaLifeData.Kind.SAILING_BOAT:
			SeaArt.draw_wave(self, Vector2(-80, 46), 160.0, 40.0, 5.0, wake_phase, WAKE_COLOUR, 6.0)
			draw_line(Vector2(-4, -86), Vector2(-4, 6), EDGE, 3.0, true)
			SeaArt.draw_shape(self, SeaArt.outline(SAILING_MAIN_SAIL), sail_colour, EDGE, 3.0)
			SeaArt.draw_shape(self, SeaArt.outline(SAILING_FRONT_SAIL), sail_2_colour, EDGE, 3.0)
			SeaArt.draw_shape(self, SeaArt.outline(SAILING_HULL), hull_colour, HULL_EDGE, 4.0)
		SeaLifeData.Kind.CARGO_SHIP:
			SeaArt.draw_wave(self, Vector2(-90, 34), 200.0, 40.0, 5.0, wake_phase, WAKE_COLOUR, 6.0)
			draw_box(Rect2(-52, -30, 30, 24), sail_colour)
			draw_box(Rect2(-18, -30, 30, 24), sail_2_colour)
			draw_box(Rect2(16, -44, 26, 38), BRIDGE_COLOUR)
			draw_rect(Rect2(21, -38, 7, 8), WINDOW_COLOUR)
			draw_rect(Rect2(32, -38, 7, 8), WINDOW_COLOUR)
			SeaArt.draw_shape(self, SeaArt.outline(CARGO_HULL), hull_colour, HULL_EDGE, 4.0)
		SeaLifeData.Kind.DINGHY:
			SeaArt.draw_wave(self, Vector2(-56, 32), 112.0, 28.0, 4.0, wake_phase, WAKE_COLOUR, 6.0)
			draw_rect(Rect2(-4, -34, 4, 34), MAST_COLOUR)
			SeaArt.draw_shape(self, SeaArt.outline(DINGHY_SAIL), sail_colour, EDGE, 3.0)
			SeaArt.draw_shape(self, SeaArt.outline(DINGHY_HULL), hull_colour, HULL_EDGE, 4.0)


func draw_box(box: Rect2, colour: Color) -> void:
	draw_rect(box, colour)
	draw_rect(box, EDGE, false, 3.0)
