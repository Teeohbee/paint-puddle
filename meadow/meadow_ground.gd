class_name MeadowGround
extends Node2D
## The grass: a soft gradient, lighter patches, tufts and little flowers that
## sway. Laid out from a fixed seed so the meadow looks the same every visit.

const MEADOW_SIZE: Vector2 = Vector2(1920, 1080)
const FLOWER_PETAL_COLOURS: Array[Color] = [
	Color(1.0, 0.45, 0.5), Color(1.0, 0.7, 0.3), Color(1.0, 0.93, 0.45),
	Color(0.55, 0.7, 1.0), Color(0.8, 0.6, 1.0), Color(1.0, 1.0, 1.0),
]

var theme: MeadowTheme = MeadowTheme.day()
var tufts: Array[Vector2] = []
var flowers: Array[Dictionary] = []
var light_patches: Array[Dictionary] = []
var sway_time: float = 0.0


func _ready() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 20261026
	for patch_index in 14:
		light_patches.append({
			"centre": Vector2(random.randf_range(0, MEADOW_SIZE.x), random.randf_range(0, MEADOW_SIZE.y)),
			"radius": random.randf_range(120, 260),
		})
	for tuft_index in 320:
		tufts.append(Vector2(random.randf_range(0, MEADOW_SIZE.x), random.randf_range(0, MEADOW_SIZE.y)))
	for flower_index in 70:
		flowers.append({
			"position": Vector2(random.randf_range(40, MEADOW_SIZE.x - 40), random.randf_range(40, MEADOW_SIZE.y - 40)),
			"colour": FLOWER_PETAL_COLOURS[random.randi_range(0, FLOWER_PETAL_COLOURS.size() - 1)],
			"sway_offset": random.randf_range(0, TAU),
			"size": random.randf_range(5.0, 8.0),
		})


func _process(delta: float) -> void:
	sway_time += delta
	queue_redraw()


func _draw() -> void:
	var top_grass: Color = theme.grass_top
	var bottom_grass: Color = theme.grass_bottom
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(MEADOW_SIZE.x, 0), MEADOW_SIZE, Vector2(0, MEADOW_SIZE.y)]),
		PackedColorArray([top_grass, top_grass, bottom_grass, bottom_grass]))
	for patch in light_patches:
		draw_circle(patch.centre, patch.radius, Color(theme.light_patch, 0.08))
		draw_circle(patch.centre, patch.radius * 0.6, Color(theme.light_patch, 0.06))
	for tuft in tufts:
		draw_tuft(tuft)
	for flower in flowers:
		draw_flower(flower)
	if theme.edge_glow.a > 0.0:
		draw_edge_glow()


## A warm sunset glow fading in from each edge.
func draw_edge_glow() -> void:
	var glow: Color = theme.edge_glow
	var clear: Color = Color(glow, 0.0)
	var depth: float = 260.0
	var corners: Array[Vector2] = [Vector2.ZERO, Vector2(MEADOW_SIZE.x, 0), MEADOW_SIZE, Vector2(0, MEADOW_SIZE.y)]
	var inner: Array[Vector2] = [Vector2(depth, depth), Vector2(MEADOW_SIZE.x - depth, depth),
		MEADOW_SIZE - Vector2(depth, depth), Vector2(depth, MEADOW_SIZE.y - depth)]
	for side in 4:
		var next: int = (side + 1) % 4
		draw_polygon(PackedVector2Array([corners[side], corners[next], inner[next], inner[side]]),
			PackedColorArray([glow, glow, clear, clear]))


func draw_tuft(base: Vector2) -> void:
	var blade_colour: Color = theme.tuft
	var lean: float = sin(sway_time * 1.3 + base.x * 0.01) * 2.0
	draw_line(base, base + Vector2(-5 + lean, -9), blade_colour, 2.0, true)
	draw_line(base, base + Vector2(lean, -12), blade_colour, 2.0, true)
	draw_line(base, base + Vector2(5 + lean, -9), blade_colour, 2.0, true)


func draw_flower(flower: Dictionary) -> void:
	var centre: Vector2 = flower.position
	var petal_size: float = flower.size
	var spin: float = sin(sway_time * 1.1 + flower.sway_offset) * 0.25
	draw_line(centre + Vector2(0, petal_size * 2.2), centre, theme.stem, 2.0, true)
	var petal_colour: Color = flower.colour.lerp(Color.WHITE, theme.petal_paleness)
	for petal_index in 5:
		var petal_angle: float = spin + TAU * petal_index / 5.0
		draw_circle(centre + Vector2.from_angle(petal_angle) * petal_size, petal_size * 0.75, petal_colour)
	draw_circle(centre, petal_size * 0.55, theme.flower_centre)
