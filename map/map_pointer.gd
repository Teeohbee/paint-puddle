class_name MapPointer
extends Node2D
## The blob on the map is a paint-drop pin: a round, smiling head that narrows
## to a tip. The tip is where it points - whatever it's over gets the ring and
## the name - so the face never covers the country. Drives like the Meadow
## blob (D-pad or stick), and drifts onto the middle of a country when the
## D-pad is let go close to one.

const HEAD_RADIUS: float = 36.0
const HEAD_CENTRE_ABOVE_TIP: float = 76.0
const OUTLINE_COLOUR: Color = Color(0.16, 0.35, 0.75)
const TIP_RING_COLOUR: Color = Color(1, 1, 1, 0.9)
## Gentler than the Meadow's pull (240), so driving past a country doesn't grab you.
const PULL_TOP_SPEED: float = 120.0
const PULL_RATE: float = 1600.0
const TEARDROP_STEPS: int = 28
## Near the top of the screen the pin turns upside down so its head stays on screen.
const HEAD_FLIPS_BELOW_Y: float = 150.0
const HEAD_FLIP_RANGE: float = 60.0

## The left, right, up and down actions this pointer listens to.
var move_actions: Array[StringName] = PlayerControls.MOVE_ACTIONS.duplicate()
var mover: TopDownMover = TopDownMover.new()
var magnet_picker: MagnetPicker = MagnetPicker.new()
## MapMagnets: the middle of each country on this screen. Empty = no pull.
var magnets: Array = []
## Tells which country (or continent) a point is over, "" over the sea. While the
## tip is over a country only that country's middle can pull it, so a tiny
## neighbour at the border never drags you out of a big country.
var target_at: Callable = func(_point: Vector2) -> String: return ""
var velocity: Vector2 = Vector2.ZERO
var play_area: Rect2 = Rect2(40, 40, 1840, 1000)
## On the world screen the map goes round: off the right edge comes back on the left, and the other way.
var wraps_sideways: bool = false
var paint_colour: Color = PaintColours.BLUE
var squash_stretch: SquashStretchSpring = SquashStretchSpring.new()
var look_direction: Vector2 = Vector2.DOWN
var was_moving: bool = false
var bob_time: float = 0.0


func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(move_actions[0], move_actions[1], move_actions[2], move_actions[3])
	var magnet: Object = null
	var reachable_magnets: Array = magnets_for_the_spot_under_the_tip()
	if input_direction == Vector2.ZERO:
		magnet = magnet_picker.pick(position, reachable_magnets)
	else:
		magnet_picker.note_steering(position, input_direction, reachable_magnets)
	if magnet != null:
		var wanted_velocity: Vector2 = ((magnet.global_position - position) * 5.0).limit_length(PULL_TOP_SPEED)
		velocity = velocity.move_toward(wanted_velocity, PULL_RATE * delta)
	else:
		velocity = mover.next_velocity(velocity, input_direction, delta)
	position = position + velocity * delta
	if wraps_sideways:
		position.x = wrapf(position.x, 0.0, MapData.SCREEN_SIZE.x)
	var kept_inside: Vector2 = position.clamp(Vector2(-INF if wraps_sideways else play_area.position.x, play_area.position.y), Vector2(INF if wraps_sideways else play_area.end.x, play_area.end.y))
	if kept_inside != position:
		velocity = Vector2.ZERO if kept_inside.is_equal_approx(position) else velocity
		position = kept_inside
	react_to_starting_and_stopping(input_direction)
	if input_direction != Vector2.ZERO:
		look_direction = look_direction.lerp(input_direction.normalized(), 12.0 * delta).normalized()


func magnets_for_the_spot_under_the_tip() -> Array:
	var over: String = target_at.call(position)
	if over == "":
		return magnets
	return magnets.filter(func(magnet): return magnet.target_id == over)


func react_to_starting_and_stopping(input_direction: Vector2) -> void:
	var is_moving: bool = input_direction != Vector2.ZERO
	if is_moving and not was_moving:
		squash_stretch.kick(Vector2(2.0, -4.0))
	elif was_moving and not is_moving:
		squash_stretch.kick(Vector2(-3.0, 3.0))
	was_moving = is_moving


func _process(delta: float) -> void:
	squash_stretch.step(delta)
	bob_time += delta
	queue_redraw()


## The head and its tip, squashed and stretched about the tip so the pin stays planted.
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, squash_stretch.scale)
	draw_tip_ring()
	var flip: float = clampf((HEAD_FLIPS_BELOW_Y - position.y) / HEAD_FLIP_RANGE, 0.0, 1.0)
	var head_centre: Vector2 = Vector2(0, -HEAD_CENTRE_ABOVE_TIP).rotated(PI * flip) + Vector2(0, sin(bob_time * 3.0) * 3.0)
	var outline: PackedVector2Array = teardrop_points(head_centre, HEAD_RADIUS, Vector2.ZERO)
	draw_colored_polygon(outline, paint_colour)
	draw_polyline(outline + PackedVector2Array([outline[0]]), OUTLINE_COLOUR, 4.0, true)
	draw_circle(head_centre + Vector2(-HEAD_RADIUS * 0.4, -HEAD_RADIUS * 0.42), HEAD_RADIUS * 0.17, Color(1, 1, 1, 0.9))
	draw_face(head_centre)


func draw_tip_ring() -> void:
	var ring: PackedVector2Array = PackedVector2Array()
	for step in 25:
		var angle: float = TAU * step / 24.0
		ring.append(Vector2(cos(angle) * 20.0, sin(angle) * 9.0))
	draw_polyline(ring, TIP_RING_COLOUR, 4.0, true)


func draw_face(head_centre: Vector2) -> void:
	var glance: Vector2 = look_direction.limit_length(1.0) * 3.0
	for side in [-1.0, 1.0]:
		draw_circle(head_centre + Vector2(side * HEAD_RADIUS * 0.34, -HEAD_RADIUS * 0.12) + glance, HEAD_RADIUS * 0.12, PaintColours.INK)
	draw_arc(head_centre + Vector2(0, HEAD_RADIUS * 0.1) + glance, HEAD_RADIUS * 0.26, deg_to_rad(25), deg_to_rad(155), 12, PaintColours.INK, 3.0, true)


## A round head of the given radius narrowing to a point: the classic map pin.
static func teardrop_points(head_centre: Vector2, radius: float, tip: Vector2) -> PackedVector2Array:
	var towards_tip: Vector2 = tip - head_centre
	var base_angle: float = towards_tip.angle()
	var spread: float = acos(radius / towards_tip.length())
	var points: PackedVector2Array = PackedVector2Array([tip])
	var start_angle: float = base_angle + spread
	var end_angle: float = base_angle - spread + TAU
	for step in TEARDROP_STEPS + 1:
		var angle: float = lerpf(start_angle, end_angle, float(step) / TEARDROP_STEPS)
		points.append(head_centre + Vector2.from_angle(angle) * radius)
	return points
