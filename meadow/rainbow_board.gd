class_name RainbowBoard
extends Node2D
## A big rainbow waiting to be painted, with a paint pot for each stripe
## underneath. Filling a pot paints its stripe with a sweep. When all six
## are painted the rainbow is finished.

signal pot_entered(pot: PaintPot)
signal rainbow_finished

const OUTER_RADIUS: float = 360.0
const STRIPE_WIDTH: float = 34.0
const SECONDS_TO_PAINT_STRIPE: float = 0.8
const POT_ROW_Y: float = 110.0
const POT_SPACING: float = 150.0

var pots: Array[PaintPot] = []
## How much of each stripe is painted, 0 to 1, in rainbow order.
var stripe_paint: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var stripe_fade: float = 1.0
var shimmer_time: float = 0.0
var is_shimmering: bool = false


func _ready() -> void:
	var stripe_count: int = PaintMixing.RAINBOW_ORDER.size()
	for stripe_index in stripe_count:
		var pot: PaintPot = PaintPot.new()
		pot.paint_name = PaintMixing.RAINBOW_ORDER[stripe_index]
		pot.position = Vector2((stripe_index - (stripe_count - 1) / 2.0) * POT_SPACING, POT_ROW_Y)
		pot.blob_entered.connect(func(entered_pot): pot_entered.emit(entered_pot))
		add_child(pot)
		pots.append(pot)


func is_stripe_painted(paint_name: String) -> bool:
	return stripe_paint[PaintMixing.RAINBOW_ORDER.find(paint_name)] >= 1.0 or pot_for(paint_name).is_filled


func pot_for(paint_name: String) -> PaintPot:
	return pots[PaintMixing.RAINBOW_ORDER.find(paint_name)]


func paint_stripe(paint_name: String) -> void:
	var stripe_index: int = PaintMixing.RAINBOW_ORDER.find(paint_name)
	pots[stripe_index].fill()
	var sweep: Tween = create_tween()
	sweep.tween_method(set_stripe_paint.bind(stripe_index), 0.0, 1.0, SECONDS_TO_PAINT_STRIPE) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if all_pots_filled():
		sweep.tween_callback(finish_rainbow)


func set_stripe_paint(amount: float, stripe_index: int) -> void:
	stripe_paint[stripe_index] = amount


func all_pots_filled() -> bool:
	for pot in pots:
		if not pot.is_filled:
			return false
	return true


func finish_rainbow() -> void:
	is_shimmering = true
	rainbow_finished.emit()


## Fades the painted rainbow away and empties the pots, ready to paint again.
func start_again() -> void:
	is_shimmering = false
	var fade: Tween = create_tween()
	fade.tween_property(self, "stripe_fade", 0.0, 0.8)
	await fade.finished
	for stripe_index in stripe_paint.size():
		stripe_paint[stripe_index] = 0.0
	for pot in pots:
		pot.empty()
	stripe_fade = 1.0


func _process(delta: float) -> void:
	shimmer_time += delta
	queue_redraw()


func _draw() -> void:
	draw_cloud(Vector2(-OUTER_RADIUS + STRIPE_WIDTH * 3.0, 0))
	draw_cloud(Vector2(OUTER_RADIUS - STRIPE_WIDTH * 3.0, 0))
	for stripe_index in stripe_paint.size():
		var outer: float = OUTER_RADIUS - stripe_index * STRIPE_WIDTH
		var colour: Color = PaintMixing.colour_of(PaintMixing.RAINBOW_ORDER[stripe_index])
		draw_band(outer, PI, TAU, Color(1, 1, 1, 0.45))
		draw_band_edges(outer, colour)
		var painted: float = stripe_paint[stripe_index]
		if painted > 0.0:
			var painted_colour: Color = colour
			if is_shimmering:
				painted_colour = colour.lightened(0.25 * (0.5 + 0.5 * sin(shimmer_time * 6.0 - stripe_index * 0.8)))
			painted_colour.a = stripe_fade
			draw_band(outer, PI, PI + PI * painted, painted_colour)
	draw_cloud(Vector2(-OUTER_RADIUS + STRIPE_WIDTH * 3.0, 0), true)
	draw_cloud(Vector2(OUTER_RADIUS - STRIPE_WIDTH * 3.0, 0), true)


func draw_band(outer_radius: float, from_angle: float, to_angle: float, colour: Color) -> void:
	var inner_radius: float = outer_radius - STRIPE_WIDTH + 1.0
	var steps: int = maxi(4, int((to_angle - from_angle) / PI * 48.0))
	var points: PackedVector2Array = PackedVector2Array()
	for step in steps + 1:
		points.append(Vector2.from_angle(lerpf(from_angle, to_angle, float(step) / steps)) * outer_radius)
	for step in range(steps, -1, -1):
		points.append(Vector2.from_angle(lerpf(from_angle, to_angle, float(step) / steps)) * inner_radius)
	draw_colored_polygon(points, colour)


func draw_band_edges(outer_radius: float, colour: Color) -> void:
	var faint: Color = colour
	faint.a = 0.5
	var middle_radius: float = outer_radius - STRIPE_WIDTH / 2.0
	var dash_count: int = 18
	for dash_index in dash_count:
		var start_angle: float = PI + PI * dash_index / dash_count
		draw_arc(Vector2.ZERO, middle_radius, start_angle, start_angle + PI / dash_count * 0.5, 4, faint, 4.0, true)


## A fluffy cloud at each foot of the rainbow. The front puffs are drawn
## after the stripes so the rainbow looks like it comes out of them.
func draw_cloud(centre: Vector2, front_only: bool = false) -> void:
	var puffs: Array[Vector3] = [Vector3(-60, 10, 44), Vector3(60, 10, 44), Vector3(-22, -18, 52), Vector3(28, -12, 48), Vector3(0, 18, 50)]
	if not front_only:
		for puff in puffs:
			draw_circle(centre + Vector2(puff.x, puff.y + 8), puff.z, Color(0.6, 0.7, 0.85, 0.35))
	for puff in puffs:
		if front_only and puff.y < 0:
			continue
		draw_circle(centre + Vector2(puff.x, puff.y), puff.z, Color.WHITE)
