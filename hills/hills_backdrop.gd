class_name HillsBackdrop
extends Node2D
## Sky, sun, drifting clouds and two rows of distant hills that scroll more
## slowly than the ground, for depth. A sea of clouds sits below the level,
## so a fall looks soft. Colours come from the level's scene - see HillsScenes.
##
## A scene can also stand trees along the near hills and send weather - snow,
## leaves - drifting down in front of everything but the word and controls.

const SCREEN_SIZE: Vector2 = Vector2(1920, 1080)

var level_length: float = 4000.0
var scene: Dictionary = HillsScenes.SCENES[HillsScenes.DEFAULT_SCENE]
var sun_time: float = 0.0
## Each snowflake, leaf or firefly: where it starts, how fast it moves, how big it is.
var weather_bits: Array[Dictionary] = []


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
	add_parallax_hills(0.25, scene.far_hills, 380.0, 140.0, 11)
	if scene.near_layer == "sea":
		add_parallax_sea(0.5, scene.near_hills, 600.0)
	else:
		add_parallax_hills(0.5, scene.near_hills, 520.0, 110.0, 23, scene.trees)
	if scene.weather != "":
		add_weather()


func add_parallax_hills(scroll_scale: float, colour: Color, top: float, height: float, seed_number: int, trees: String = "") -> void:
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
			points.append(Vector2(x, hill_top_at(x, top, height, bump_phases)))
		points.append(Vector2(SCREEN_SIZE.x, 1700))
		points.append(Vector2(0, 1700))
		if trees != "":
			# Behind the hill's edge, so they stand in it rather than on it
			var x: float = random.randf_range(40, 160)
			while x < SCREEN_SIZE.x - 80:
				var size: float = random.randf_range(0.75, 1.2)
				draw_tree(hills, trees, Vector2(x, hill_top_at(x, top, height, bump_phases) + 18), size, random)
				x += random.randf_range(110, 260)
		hills.draw_colored_polygon(points, colour))


## A flat sea out to the horizon, with lighter wave lines and a sailing boat.
func add_parallax_sea(scroll_scale: float, colour: Color, horizon: float) -> void:
	var parallax: Parallax2D = Parallax2D.new()
	parallax.scroll_scale = Vector2(scroll_scale, 1.0)
	parallax.repeat_size = Vector2(SCREEN_SIZE.x, 0)
	parallax.repeat_times = 3
	parallax.z_index = -5
	add_child(parallax)
	var sea: Node2D = Node2D.new()
	parallax.add_child(sea)
	sea.draw.connect(func():
		sea.draw_rect(Rect2(0, horizon, SCREEN_SIZE.x, 1700 - horizon), colour)
		sea.draw_line(Vector2(0, horizon), Vector2(SCREEN_SIZE.x, horizon), colour.lightened(0.25), 4.0)
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 31
		for wave_index in 26:
			var wave_spot: Vector2 = Vector2(random.randf_range(30, SCREEN_SIZE.x - 60), random.randf_range(horizon + 30, horizon + 320))
			sea.draw_arc(wave_spot, 14, PI + 0.5, TAU - 0.5, 8, colour.lightened(0.3), 4.0, true)
			sea.draw_arc(wave_spot + Vector2(24, 0), 14, PI + 0.5, TAU - 0.5, 8, colour.lightened(0.3), 4.0, true)
		draw_boat(sea, Vector2(1300, horizon + 70)))


func draw_boat(canvas: CanvasItem, waterline: Vector2) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([waterline + Vector2(-70, -26), waterline + Vector2(70, -26), waterline + Vector2(48, 6), waterline + Vector2(-48, 6)]), PaintColours.RED)
	canvas.draw_line(waterline + Vector2(0, -26), waterline + Vector2(0, -150), Color(0.45, 0.36, 0.34), 5.0)
	canvas.draw_colored_polygon(PackedVector2Array([waterline + Vector2(6, -146), waterline + Vector2(6, -34), waterline + Vector2(70, -34)]), Color(1, 1, 1))
	canvas.draw_colored_polygon(PackedVector2Array([waterline + Vector2(-6, -120), waterline + Vector2(-6, -34), waterline + Vector2(-50, -34)]), PaintColours.YELLOW)


static func hill_top_at(x: float, top: float, height: float, bump_phases: Array[float]) -> float:
	var wave: float = sin(x / SCREEN_SIZE.x * TAU * 2.0 + bump_phases[0]) * 0.6 \
		+ sin(x / SCREEN_SIZE.x * TAU * 3.0 + bump_phases[1]) * 0.4
	return top - wave * height


## One tree in the distance, standing on base, scaled by size.
func draw_tree(canvas: CanvasItem, kind: String, base: Vector2, size: float, random: RandomNumberGenerator) -> void:
	match kind:
		"pines":
			var trunk: Color = Color(0.45, 0.36, 0.34)
			var needles: Color = Color(0.32, 0.5, 0.5)
			canvas.draw_rect(Rect2(base.x - 7 * size, base.y - 30 * size, 14 * size, 30 * size), trunk)
			for tier in 3:
				var tier_base: float = base.y - (24 + tier * 34) * size
				var half_width: float = (58 - tier * 14) * size
				var tip: Vector2 = Vector2(base.x, tier_base - 62 * size)
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(base.x - half_width, tier_base), Vector2(base.x + half_width, tier_base), tip]), needles)
				# Snow on each tier's top
				canvas.draw_colored_polygon(PackedVector2Array([tip.lerp(Vector2(base.x - half_width, tier_base), 0.4), tip.lerp(Vector2(base.x + half_width, tier_base), 0.4), tip]), Color(1, 1, 1))
		"palms":
			var trunk_colour: Color = Color(0.5, 0.36, 0.24)
			var crown: Vector2 = base + Vector2(random.randf_range(-24, 24), -170) * size
			canvas.draw_polyline(PackedVector2Array([base, base.lerp(crown, 0.5) + Vector2(10, 0) * size, crown]), trunk_colour, 14 * size, true)
			for frond_index in 6:
				var frond_angle: float = PI + 0.2 + frond_index * (PI - 0.4) / 5.0
				var frond_tip: Vector2 = crown + Vector2.from_angle(frond_angle) * 70 * size + Vector2(0, 26) * size
				draw_leaf(canvas, crown.lerp(frond_tip, 0.5), 42 * size, frond_angle, Color(0.18, 0.46, 0.26))
		"acacia":
			var bark: Color = Color(0.36, 0.25, 0.2)
			var fork: Vector2 = base + Vector2(0, -70) * size
			canvas.draw_line(base, fork, bark, 10 * size, true)
			canvas.draw_line(fork, fork + Vector2(-40, -44) * size, bark, 7 * size, true)
			canvas.draw_line(fork, fork + Vector2(36, -48) * size, bark, 7 * size, true)
			var canopy: PackedVector2Array = PackedVector2Array()
			for point_index in 20:
				var around: float = TAU * point_index / 20.0
				canopy.append(fork + Vector2(0, -56) * size + Vector2(cos(around) * 110, sin(around) * 24) * size)
			canvas.draw_colored_polygon(canopy, Color(0.42, 0.5, 0.24))
		"autumn":
			var leaves: Color = HillsScenes.AUTUMN_LEAVES[random.randi_range(0, HillsScenes.AUTUMN_LEAVES.size() - 1)]
			canvas.draw_rect(Rect2(base.x - 8 * size, base.y - 70 * size, 16 * size, 70 * size), Color(0.45, 0.3, 0.22))
			for puff in [Vector3(0, -110, 46), Vector3(-34, -82, 36), Vector3(34, -84, 38), Vector3(0, -70, 34)]:
				canvas.draw_circle(base + Vector2(puff.x, puff.y) * size, puff.z * size, leaves)
			canvas.draw_circle(base + Vector2(-14, -122) * size, 14 * size, leaves.lightened(0.2))


## Stars in fixed places, each twinkling at its own pace.
func draw_stars(sky: Control) -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 17
	for star_index in 60:
		var spot: Vector2 = Vector2(random.randf_range(0, SCREEN_SIZE.x), random.randf_range(0, SCREEN_SIZE.y * 0.55))
		var twinkle: float = 0.55 + 0.45 * sin(sun_time * random.randf_range(1.0, 2.5) + star_index)
		sky.draw_circle(spot, random.randf_range(1.5, 3.5), Color(1, 0.97, 0.85, twinkle))


func draw_moon(sky: Control, moon_centre: Vector2) -> void:
	sky.draw_circle(moon_centre, 112, Color(1, 0.96, 0.8, 0.07))
	sky.draw_circle(moon_centre, 96, Color(1, 0.96, 0.8, 0.07))
	sky.draw_circle(moon_centre, 78, Color(0.99, 0.95, 0.78))
	sky.draw_circle(moon_centre + Vector2(30, 34), 12, Color(0.93, 0.88, 0.7))
	sky.draw_circle(moon_centre + Vector2(-38, 22), 8, Color(0.93, 0.88, 0.7))
	# Asleep: closed eyes and a little smile
	for eye_x in [-22.0, 22.0]:
		sky.draw_arc(moon_centre + Vector2(eye_x, -14), 10, 0.3, PI - 0.3, 10, PaintColours.INK, 4.0, true)
	sky.draw_arc(moon_centre + Vector2(0, 10), 14, 0.5, PI - 0.5, 10, PaintColours.INK, 4.0, true)


func add_weather() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 5
	for bit_index in 70:
		weather_bits.append({
			"start": Vector2(random.randf_range(0, SCREEN_SIZE.x), random.randf_range(0, SCREEN_SIZE.y)),
			"fall_speed": random.randf_range(40, 95),
			"size": random.randf_range(0.6, 1.3),
			"phase": random.randf_range(0, TAU),
			"tint": random.randi_range(0, 2),
		})
	var weather_layer: CanvasLayer = CanvasLayer.new()
	# In front of the level, behind the word bar and controls (layer 10)
	weather_layer.layer = 5
	add_child(weather_layer)
	var weather: Control = Control.new()
	weather.set_anchors_preset(Control.PRESET_FULL_RECT)
	weather.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weather.draw.connect(draw_weather.bind(weather))
	weather_layer.add_child(weather)


func draw_weather(weather: Control) -> void:
	# Drift against the camera a little, so the weather feels like it's in the world
	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_x: float = camera.get_screen_center_position().x if camera != null else 0.0
	var wrap_size: Vector2 = SCREEN_SIZE + Vector2(80, 80)
	for bit in weather_bits:
		var sway: float = sin(sun_time * 0.9 + bit.phase) * 30.0
		var x: float = fposmod(bit.start.x - camera_x * 0.6 + sway, wrap_size.x) - 40.0
		var y: float = fposmod(bit.start.y + sun_time * bit.fall_speed, wrap_size.y) - 40.0
		match scene.weather:
			"vines":
				# The first few hang from the top; two parrots fly through
				if bit.tint == 2 and bit.phase < 1.0:
					var parrot: Vector2 = Vector2(fposmod(bit.start.x + sun_time * 120.0 - camera_x * 0.4, wrap_size.x) - 40.0, 180.0 + bit.start.y * 0.2 + sin(sun_time * 2.0 + bit.phase) * 20.0)
					weather.draw_circle(parrot, 14, PaintColours.RED)
					weather.draw_circle(parrot + Vector2(14, -8), 9, PaintColours.RED)
					weather.draw_colored_polygon(PackedVector2Array([parrot + Vector2(22, -10), parrot + Vector2(30, -6), parrot + Vector2(21, -3)]), PaintColours.YELLOW)
					weather.draw_circle(parrot + Vector2(16, -10), 2.0, PaintColours.INK)
					weather.draw_colored_polygon(PackedVector2Array([parrot + Vector2(-14, 0), parrot + Vector2(-34, 6), parrot + Vector2(-14, 8)]), PaintColours.BLUE)
					var wing_lift: float = sin(sun_time * 10.0 + bit.phase) * 14.0
					weather.draw_colored_polygon(PackedVector2Array([parrot + Vector2(-6, -2), parrot + Vector2(6, -2), parrot + Vector2(-2, -18 - wing_lift)]), PaintColours.YELLOW)
				if bit.tint != 0 or bit.phase > 1.8:
					continue
				var vine_x: float = fposmod(bit.start.x - camera_x * 0.8, wrap_size.x) - 40.0
				var vine_length: float = 90.0 + bit.start.y * 0.15
				var vine: PackedVector2Array = PackedVector2Array()
				for vine_step in 9:
					var down: float = vine_length * vine_step / 8.0
					vine.append(Vector2(vine_x + sin(down * 0.04 + sun_time * 0.8 + bit.phase) * 6.0 * vine_step / 8.0, down))
				weather.draw_polyline(vine, Color(0.2, 0.45, 0.22), 5.0, true)
				for leaf_step in [3, 5, 7, 8]:
					draw_leaf(weather, vine[leaf_step] + Vector2(8 if leaf_step % 2 == 0 else -8, 0), 11.0, 0.6 if leaf_step % 2 == 0 else -0.6, Color(0.28, 0.6, 0.3))
			"gulls":
				# A few birds gliding across high up
				if bit.phase > 0.5:
					continue
				var gull: Vector2 = Vector2(fposmod(bit.start.x + sun_time * bit.fall_speed - camera_x * 0.3, wrap_size.x) - 40.0, 80.0 + bit.start.y * 0.3 + sin(sun_time + bit.phase * 3.0) * 12.0)
				var flap: float = 0.35 + 0.25 * sin(sun_time * 4.0 + bit.phase * 5.0)
				weather.draw_arc(gull + Vector2(-12, 0), 12, PI + flap, TAU - 0.2, 8, PaintColours.INK, 3.5, true)
				weather.draw_arc(gull + Vector2(12, 0), 12, PI + 0.2, TAU - flap, 8, PaintColours.INK, 3.5, true)
			"fireflies":
				# Fewer of them, wandering low down rather than falling
				if bit.tint == 0:
					continue
				y = SCREEN_SIZE.y * 0.45 + bit.start.y * 0.45 + sin(sun_time * 0.7 + bit.phase * 2.0) * 40.0
				var glow: float = 0.5 + 0.5 * sin(sun_time * 2.0 + bit.phase)
				weather.draw_circle(Vector2(x, y), 12.0 * bit.size, Color(0.9, 1.0, 0.5, 0.18 * glow))
				weather.draw_circle(Vector2(x, y), 3.5 * bit.size, Color(0.95, 1.0, 0.65, 0.4 + 0.6 * glow))
			"snow":
				weather.draw_circle(Vector2(x, y), 5.0 * bit.size, Color(1, 1, 1, 0.85))
			"leaves":
				draw_leaf(weather, Vector2(x, y), 11.0 * bit.size, sun_time * 1.5 + bit.phase, HillsScenes.AUTUMN_LEAVES[bit.tint])


## A leaf: a pointed oval, turned by angle.
static func draw_leaf(canvas: CanvasItem, centre: Vector2, length: float, angle: float, colour: Color) -> void:
	var outline: PackedVector2Array = PackedVector2Array()
	for point_index in 12:
		var along: float = TAU * point_index / 12.0
		outline.append(centre + Vector2(cos(along) * length, sin(along) * length * 0.45 * absf(cos(along * 0.5))).rotated(angle))
	canvas.draw_colored_polygon(outline, colour)


func _process(delta: float) -> void:
	sun_time += delta
	for child in get_children():
		if child is CanvasLayer:
			child.get_child(0).queue_redraw()


func draw_sky(sky: Control) -> void:
	var top_colour: Color = scene.sky_top
	var bottom_colour: Color = scene.sky_bottom
	sky.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(SCREEN_SIZE.x, 0), SCREEN_SIZE, Vector2(0, SCREEN_SIZE.y)]),
		PackedColorArray([top_colour, top_colour, bottom_colour, bottom_colour]))
	match scene.sky_body:
		"sun":
			draw_sun(sky, Vector2(1650, 170))
		"moon":
			draw_stars(sky)
			draw_moon(sky, Vector2(1650, 170))
		"low sun":
			var low_sun: Vector2 = Vector2(1500, 290)
			sky.draw_circle(low_sun, 190, Color(1, 0.8, 0.5, 0.25))
			sky.draw_circle(low_sun, 140, Color(1.0, 0.68, 0.32))
			sky.draw_circle(low_sun + Vector2(-34, -16), 10, PaintColours.INK)
			sky.draw_circle(low_sun + Vector2(34, -16), 10, PaintColours.INK)
			sky.draw_arc(low_sun + Vector2(0, 10), 30, 0.4, PI - 0.4, 12, PaintColours.INK, 6.0, true)
	for cloud_index in 4:
		var drift: float = fmod(sun_time * (14.0 + cloud_index * 5.0) + cloud_index * 520.0, SCREEN_SIZE.x + 400.0) - 200.0
		var cloud_centre: Vector2 = Vector2(drift, 120 + cloud_index * 70)
		for puff in [Vector3(-50, 8, 34), Vector3(0, -10, 44), Vector3(50, 6, 36), Vector3(10, 14, 36)]:
			sky.draw_circle(cloud_centre + Vector2(puff.x, puff.y), puff.z, scene.cloud_colour)


func draw_sun(sky: Control, sun_centre: Vector2) -> void:
	for ray_index in 12:
		var angle: float = sun_time * 0.2 + TAU * ray_index / 12.0
		sky.draw_line(sun_centre + Vector2.from_angle(angle) * 90, sun_centre + Vector2.from_angle(angle) * 130,
			Color(1.0, 0.88, 0.4, 0.8), 10.0, true)
	sky.draw_circle(sun_centre, 78, Color(1.0, 0.88, 0.4))
	sky.draw_circle(sun_centre + Vector2(-22, -10), 8, PaintColours.INK)
	sky.draw_circle(sun_centre + Vector2(22, -10), 8, PaintColours.INK)
	sky.draw_arc(sun_centre + Vector2(0, 8), 24, 0.4, PI - 0.4, 12, PaintColours.INK, 5.0, true)


## The cloud sea, drawn in the world so it lines up with the gaps.
static func draw_cloud_sea(canvas: CanvasItem, from_x: float, to_x: float, top: float, colour: Color) -> void:
	var x: float = from_x - 100.0
	var puff_index: int = 0
	while x < to_x + 100.0:
		var bob: float = 14.0 * sin(puff_index * 1.3)
		canvas.draw_circle(Vector2(x, top + 40 + bob), 70 + 12 * sin(puff_index * 2.1), colour)
		x += 80.0
		puff_index += 1
	canvas.draw_rect(Rect2(from_x - 200, top + 60, to_x - from_x + 400, 800), colour)
