class_name PaintCanvas
extends Node2D
## The picture in paint mode. The paper is split into little squares that
## remember which paints have touched them, so painting red across blue
## makes purple where they cross - the same mixing as the meadow.
##
## Each square is one pixel of a small picture, stretched over the paper
## with smoothing and a soft edge so strokes look round rather than blocky.
## Wiping fades the picture away and starts a fresh one.

const PICTURE_SIZE: Vector2i = Vector2i(1920, 1080)
const CELL_SIZE: int = 4
const DAB_RADIUS: float = 30.0
const DAB_SPACING: float = 6.0
const PRIMARY_BITS: Dictionary = {"red": 1, "yellow": 2, "blue": 4}

var dabs_painted: int = 0
var columns: int = ceili(float(PICTURE_SIZE.x) / CELL_SIZE)
var rows: int = ceili(float(PICTURE_SIZE.y) / CELL_SIZE)
## Which primaries are on each square, as bits - see PRIMARY_BITS.
var cells: PackedByteArray = PackedByteArray()
## How much of each square is painted, from 0 to 1, for smooth edges.
var coverage: PackedFloat32Array = PackedFloat32Array()
var paint_names_by_bits: Array[String] = []
var picture: Image
var picture_texture: ImageTexture
var picture_sprite: Sprite2D
var picture_changed: bool = false
var wipe_tween: Tween


func _init() -> void:
	cells.resize(columns * rows)
	coverage.resize(columns * rows)
	for bits in 8:
		var primaries: Array = []
		for primary in PRIMARY_BITS:
			if bits & PRIMARY_BITS[primary]:
				primaries.append(primary)
		paint_names_by_bits.append(PaintMixing.paint_made_of(primaries))


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
## with whatever paint is already on the paper.
func paint_line(from: Vector2, to: Vector2, paint_name: String) -> void:
	var paint_bits: int = bits_of(paint_name)
	var points: PackedVector2Array = dab_points(from, to, DAB_SPACING)
	for point in points:
		dab(point, paint_bits)
	dabs_painted += points.size()


func dab(centre: Vector2, paint_bits: int) -> void:
	var reach: int = ceili(DAB_RADIUS / CELL_SIZE) + 1
	var centre_cell: Vector2i = Vector2i(centre / CELL_SIZE)
	for row in range(centre_cell.y - reach, centre_cell.y + reach + 1):
		for column in range(centre_cell.x - reach, centre_cell.x + reach + 1):
			if column < 0 or row < 0 or column >= columns or row >= rows:
				continue
			var cell_centre: Vector2 = (Vector2(column, row) + Vector2(0.5, 0.5)) * CELL_SIZE
			# How much of the square the round dab covers, roughly, so the
			# stretched picture can find a smooth edge between squares
			var cover: float = clampf((DAB_RADIUS - cell_centre.distance_to(centre)) / CELL_SIZE + 0.5, 0.0, 1.0)
			if cover <= 0.0:
				continue
			var index: int = row * columns + column
			var mixed_bits: int = cells[index] | paint_bits
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


## Which paint is on the paper at this point: "clean" if none.
func paint_at(point: Vector2) -> String:
	var cell: Vector2i = Vector2i(point / CELL_SIZE)
	if cell.x < 0 or cell.y < 0 or cell.x >= columns or cell.y >= rows:
		return "clean"
	return paint_names_by_bits[cells[cell.y * columns + cell.x]]


func bits_of(paint_name: String) -> int:
	var bits: int = 0
	for primary in PaintMixing.PRIMARIES_IN[paint_name]:
		bits |= PRIMARY_BITS[primary]
	return bits


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
	if picture != null:
		picture.fill(Color.TRANSPARENT)
		picture_changed = true
