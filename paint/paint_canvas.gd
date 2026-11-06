class_name PaintCanvas
extends Node2D
## The picture in paint mode. The paper is split into little squares that
## remember which paint is on them, so painting red across blue makes
## purple where they cross - the same mixing as dipping the blob.
##
## A square mixes once each time the brush passes over it, like one dip in a
## puddle: black across pink makes red, and a second pass makes dark red.
##
## Each square is one pixel of a small picture, stretched over the paper
## with smoothing and a soft edge so strokes look round rather than blocky.
## Wiping fades the picture away and starts a fresh one.

const PICTURE_SIZE: Vector2i = Vector2i(1920, 1080)
const CELL_SIZE: int = 4
const DAB_RADIUS: float = 30.0
const DAB_SPACING: float = 6.0
const SPLAT_RADIUS: float = 70.0
const SPLAT_DROPLETS_MIN: int = 5
const SPLAT_DROPLETS_MAX: int = 7
## How many different paints a square can hold, one for each bit pattern.
const BIT_PATTERNS: int = PaintMixing.PRIMARY_BITS + PaintMixing.SHADE_BITS + 1

var dabs_painted: int = 0
var columns: int = ceili(float(PICTURE_SIZE.x) / CELL_SIZE)
var rows: int = ceili(float(PICTURE_SIZE.y) / CELL_SIZE)
## Which paint is on each square, as bits - see PaintMixing.
var cells: PackedByteArray = PackedByteArray()
## How many brushes can paint at once, one for each player.
const MAX_BRUSHES: int = 2

## Each brush keeps its own pass state, so one brush resting on a square
## isn't mistaken for a new pass just because the other brush painted in between.
## The pass that last painted each square, for each brush. A pass is a run of
## brush lines in one paint, so a square stays in the same pass while the
## brush is over it.
var last_pass_painted_by_brush: Array[PackedInt32Array] = []
## Counts up by one for each line a brush paints; a square that wasn't painted
## by the line before this one has had the brush leave it, so it mixes again.
var line_number_by_brush: PackedInt32Array = PackedInt32Array()
var last_line_paint_bits_by_brush: PackedInt32Array = PackedInt32Array()
## What each paint makes on top of each paint, worked out once:
## mixed_bits_table[square bits * BIT_PATTERNS + paint bits].
var mixed_bits_table: PackedByteArray = PackedByteArray()
## How much of each square is painted, from 0 to 1, for smooth edges.
var coverage: PackedFloat32Array = PackedFloat32Array()
var paint_names_by_bits: Array[String] = []
## Which colour set's mixing the paper uses - see PaintMixing.
var colour_set: String = "paint":
	set(new_colour_set):
		colour_set = new_colour_set
		name_paints_by_bits()
var picture: Image
var picture_texture: ImageTexture
var picture_sprite: Sprite2D
var picture_changed: bool = false
var wipe_tween: Tween


func _init() -> void:
	cells.resize(columns * rows)
	coverage.resize(columns * rows)
	line_number_by_brush.resize(MAX_BRUSHES)
	last_line_paint_bits_by_brush.resize(MAX_BRUSHES)
	for brush in MAX_BRUSHES:
		var last_pass_painted: PackedInt32Array = PackedInt32Array()
		last_pass_painted.resize(columns * rows)
		last_pass_painted.fill(-1)
		last_pass_painted_by_brush.append(last_pass_painted)
	name_paints_by_bits()
	mixed_bits_table.resize(BIT_PATTERNS * BIT_PATTERNS)
	for square_bits in BIT_PATTERNS:
		for paint_bits in BIT_PATTERNS:
			mixed_bits_table[square_bits * BIT_PATTERNS + paint_bits] = PaintMixing.mix_bits(square_bits, paint_bits)


func name_paints_by_bits() -> void:
	paint_names_by_bits.clear()
	for bits in BIT_PATTERNS:
		paint_names_by_bits.append(PaintMixing.paint_made_of(bits, colour_set))


func _ready() -> void:
	picture = Image.create(columns, rows, false, Image.FORMAT_RGBA8)
	picture_texture = ImageTexture.create_from_image(picture)
	picture_sprite = Sprite2D.new()
	picture_sprite.centered = false
	picture_sprite.texture = picture_texture
	picture_sprite.scale = Vector2.ONE * CELL_SIZE
	var soft_edge: ShaderMaterial = ShaderMaterial.new()
	soft_edge.shader = preload("res://paint/soft_paint_edge.gdshader")
	soft_edge.set_shader_parameter("paint", picture_texture)
	picture_sprite.material = soft_edge
	add_child(picture_sprite)


func _process(_delta: float) -> void:
	if picture_changed:
		picture_texture.update(picture)
		picture_changed = false


## Paints a smooth line of round dabs from one point to another, mixing
## with whatever paint is already on the paper. Each player paints with their
## own brush number; a lone brush is brush 0.
func paint_line(from: Vector2, to: Vector2, paint_bits: int, brush: int = 0) -> void:
	# A new paint starts a new pass, so it mixes even where the brush already is
	line_number_by_brush[brush] += 2 if paint_bits != last_line_paint_bits_by_brush[brush] else 1
	last_line_paint_bits_by_brush[brush] = paint_bits
	var points: PackedVector2Array = dab_points(from, to, DAB_SPACING)
	for point in points:
		dab(point, paint_bits, brush)
	dabs_painted += points.size()


func dab(centre: Vector2, paint_bits: int, brush: int = 0, radius: float = DAB_RADIUS) -> void:
	var line_number: int = line_number_by_brush[brush]
	var last_pass_painted: PackedInt32Array = last_pass_painted_by_brush[brush]
	var reach: int = ceili(radius / CELL_SIZE) + 1
	var centre_cell: Vector2i = Vector2i(centre / CELL_SIZE)
	for row in range(centre_cell.y - reach, centre_cell.y + reach + 1):
		for column in range(centre_cell.x - reach, centre_cell.x + reach + 1):
			if column < 0 or row < 0 or column >= columns or row >= rows:
				continue
			var cell_centre: Vector2 = (Vector2(column, row) + Vector2(0.5, 0.5)) * CELL_SIZE
			# How much of the square the round dab covers, roughly, so the
			# stretched picture can find a smooth edge between squares
			var cover: float = clampf((radius - cell_centre.distance_to(centre)) / CELL_SIZE + 0.5, 0.0, 1.0)
			if cover <= 0.0:
				continue
			var index: int = row * columns + column
			var is_same_pass: bool = last_pass_painted[index] >= line_number - 1
			last_pass_painted[index] = line_number
			var mixed_bits: int = cells[index] if is_same_pass else mixed_bits_table[cells[index] * BIT_PATTERNS + paint_bits]
			var mixed_cover: float = maxf(coverage[index], cover)
			if mixed_bits == cells[index] and mixed_cover == coverage[index]:
				continue
			cells[index] = mixed_bits
			coverage[index] = mixed_cover
			if picture != null:
				# Stored premultiplied, so smoothing doesn't darken the edges
				var colour: Color = PaintMixing.colour_of(paint_names_by_bits[mixed_bits])
				picture.set_pixel(column, row, Color(colour.r * mixed_cover, colour.g * mixed_cover, colour.b * mixed_cover, mixed_cover))
				picture_changed = true


## One splat: a big dab with droplets scattered round it, all in one pass so
## they don't mix with each other. A new pass for the brush, so a splat on top
## of older paint mixes with it - and the same splat twice mixes twice. The
## scatter comes from the centre, so the same splat always looks the same.
func splat(centre: Vector2, paint_bits: int, brush: int = 0) -> void:
	line_number_by_brush[brush] += 2
	var scatter: RandomNumberGenerator = RandomNumberGenerator.new()
	scatter.seed = hash(centre)
	dab(centre, paint_bits, brush, SPLAT_RADIUS)
	for droplet_index in scatter.randi_range(SPLAT_DROPLETS_MIN, SPLAT_DROPLETS_MAX):
		var angle: float = scatter.randf() * TAU
		var distance: float = scatter.randf_range(SPLAT_RADIUS + 10.0, SPLAT_RADIUS + 80.0)
		var droplet_radius: float = scatter.randf_range(12.0, 25.0)
		dab(centre + Vector2.from_angle(angle) * distance, paint_bits, brush, droplet_radius)
	picture_changed = true


## Which paint is on the paper at this point: "clean" if none.
func paint_at(point: Vector2) -> String:
	var cell: Vector2i = Vector2i(point / CELL_SIZE)
	if cell.x < 0 or cell.y < 0 or cell.x >= columns or cell.y >= rows:
		return "clean"
	return paint_names_by_bits[cells[cell.y * columns + cell.x]]


## Points from just after `from` up to and including `to`, never further
## apart than `spacing`.
static func dab_points(from: Vector2, to: Vector2, spacing: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = maxi(1, ceili(from.distance_to(to) / spacing))
	for step in range(1, steps + 1):
		points.append(from.lerp(to, float(step) / steps))
	return points


## Fades the picture out, then starts a clean one.
func wipe() -> void:
	dabs_painted = 0
	if picture_sprite == null:
		clear_paper()
		return
	if wipe_tween != null:
		wipe_tween.kill()
	wipe_tween = create_tween()
	wipe_tween.tween_property(picture_sprite, "modulate:a", 0.0, 0.5)
	wipe_tween.tween_callback(clear_paper)
	wipe_tween.tween_interval(0.05)
	wipe_tween.tween_property(picture_sprite, "modulate:a", 1.0, 0.0)


## Forgets the paint and clears the picture together, so paint added while
## the picture fades can't be remembered but not shown.
func clear_paper() -> void:
	cells.fill(0)
	coverage.fill(0.0)
	# The fresh paper takes paint even where the brushes are sitting
	for brush in MAX_BRUSHES:
		line_number_by_brush[brush] += 2
	if picture != null:
		picture.fill(Color.TRANSPARENT)
		picture_changed = true
