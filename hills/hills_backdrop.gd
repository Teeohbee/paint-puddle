class_name HillsBackdrop
extends Node2D
## Sky, sun, drifting clouds and two rows of distant hills that scroll more
## slowly than the ground, for depth. A sea of clouds sits below the level,
## so a fall looks soft.

const SCREEN_SIZE: Vector2 = Vector2(1920, 1080)

var level_length: float = 4000.0
var sun_time: float = 0.0


func _ready() -> void:
	var sky_layer: CanvasLayer = CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	var sky: Control = Control.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.draw.connect(draw_sky.bind(sky))
	sky_layer.add_child(sky)
	sky.set_process(true)
	add_parallax_hills(0.25, Color(0.72, 0.86, 0.95), 380.0, 140.0, 11)
	add_parallax_hills(0.5, Color(0.62, 0.84, 0.6), 520.0, 110.0, 23)


func add_parallax_hills(scroll_scale: float, colour: Color, top: float, height: float, seed_number: int) -> void:
	var parallax: Parallax2D = Parallax2D.new()
	parallax.scroll_scale = Vector2(scroll_scale, 1.0)
	parallax.repeat_size = Vector2(SCREEN_SIZE.x, 0)
	parallax.repeat_times = 3
	parallax.z_index = -5
	add_child(parallax)
	var hills: Node2D = Node2D.new()
	parallax.add_child(hills)
	hills.draw.connect(func():
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = seed_number
		var points: PackedVector2Array = PackedVector2Array()
		var bump_phases: Array[float] = [random.randf_range(0, TAU), random.randf_range(0, TAU)]
		for x_step in 65:
			var x: float = x_step * SCREEN_SIZE.x / 64.0
			var wave: float = sin(x / SCREEN_SIZE.x * TAU * 2.0 + bump_phases[0]) * 0.6 \
				+ sin(x / SCREEN_SIZE.x * TAU * 3.0 + bump_phases[1]) * 0.4
			points.append(Vector2(x, top - wave * height))
		points.append(Vector2(SCREEN_SIZE.x, 1700))
		points.append(Vector2(0, 1700))
		hills.draw_colored_polygon(points, colour))


func _process(delta: float) -> void:
	sun_time += delta
	for child in get_children():
		if child is CanvasLayer:
			child.get_child(0).queue_redraw()


func draw_sky(sky: Control) -> void:
	var top_colour: Color = Color(0.55, 0.78, 1.0)
	var bottom_colour: Color = Color(0.92, 0.96, 1.0)
	sky.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(SCREEN_SIZE.x, 0), SCREEN_SIZE, Vector2(0, SCREEN_SIZE.y)]),
		PackedColorArray([top_colour, top_colour, bottom_colour, bottom_colour]))
	var sun_centre: Vector2 = Vector2(1650, 170)
	for ray_index in 12:
		var angle: float = sun_time * 0.2 + TAU * ray_index / 12.0
		sky.draw_line(sun_centre + Vector2.from_angle(angle) * 90, sun_centre + Vector2.from_angle(angle) * 130,
			Color(1.0, 0.88, 0.4, 0.8), 10.0, true)
	sky.draw_circle(sun_centre, 78, Color(1.0, 0.88, 0.4))
	sky.draw_circle(sun_centre + Vector2(-22, -10), 8, PaintColours.INK)
	sky.draw_circle(sun_centre + Vector2(22, -10), 8, PaintColours.INK)
	sky.draw_arc(sun_centre + Vector2(0, 8), 24, 0.4, PI - 0.4, 12, PaintColours.INK, 5.0, true)
	for cloud_index in 4:
		var drift: float = fmod(sun_time * (14.0 + cloud_index * 5.0) + cloud_index * 520.0, SCREEN_SIZE.x + 400.0) - 200.0
		var cloud_centre: Vector2 = Vector2(drift, 120 + cloud_index * 70)
		for puff in [Vector3(-50, 8, 34), Vector3(0, -10, 44), Vector3(50, 6, 36), Vector3(10, 14, 36)]:
			sky.draw_circle(cloud_centre + Vector2(puff.x, puff.y), puff.z, Color(1, 1, 1, 0.9))


## The cloud sea, drawn in the world so it lines up with the gaps.
static func draw_cloud_sea(canvas: CanvasItem, from_x: float, to_x: float, top: float) -> void:
	var x: float = from_x - 100.0
	var puff_index: int = 0
	while x < to_x + 100.0:
		var bob: float = 14.0 * sin(puff_index * 1.3)
		canvas.draw_circle(Vector2(x, top + 40 + bob), 70 + 12 * sin(puff_index * 2.1), Color(1, 1, 1, 0.95))
		x += 80.0
		puff_index += 1
	canvas.draw_rect(Rect2(from_x - 200, top + 60, to_x - from_x + 400, 800), Color(1, 1, 1, 0.95))
