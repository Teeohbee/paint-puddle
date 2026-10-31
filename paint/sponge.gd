class_name Sponge
extends Area2D
## A big sponge in the corner of paint mode. Sit on it while the ring fills
## up to wipe the picture clean - the wait means driving over it by accident
## doesn't lose a painting.

signal wiped

const SIZE: Vector2 = Vector2(150, 100)
const SECONDS_TO_WIPE: float = 1.5

var magnet_radius: float = 130.0
## How full the ring is, from 0 to 1.
var hold_progress: float = 0.0
var needs_leaving: bool = false
var is_blob_on: bool = false
var squish_age: float = 99.0


func _ready() -> void:
	add_to_group("magnets")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 40.0
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body): if body is MeadowBlob: is_blob_on = true)
	body_exited.connect(func(body): if body is MeadowBlob: is_blob_on = false)


func _physics_process(delta: float) -> void:
	advance(delta, is_blob_on)


func _process(delta: float) -> void:
	squish_age += delta
	queue_redraw()


func advance(delta: float, blob_is_on: bool) -> void:
	if not blob_is_on:
		hold_progress = 0.0
		needs_leaving = false
		return
	if needs_leaving:
		return
	hold_progress = minf(hold_progress + delta / SECONDS_TO_WIPE, 1.0)
	if hold_progress >= 1.0:
		hold_progress = 0.0
		needs_leaving = true
		squish_age = 0.0
		wiped.emit()


func _draw() -> void:
	var squish: float = 1.0 - 0.15 * sin(clampf(squish_age / 0.4, 0.0, 1.0) * PI) - hold_progress * 0.08
	var sponge_size: Vector2 = SIZE * Vector2(1.0 + (1.0 - squish), squish)
	var sponge_rect: Rect2 = Rect2(-sponge_size / 2.0, sponge_size)
	draw_rect(Rect2(sponge_rect.position + Vector2(6, 10), sponge_rect.size), Color(0, 0, 0, 0.15))
	var body: StyleBoxFlat = StyleBoxFlat.new()
	body.bg_color = PaintColours.YELLOW
	body.set_corner_radius_all(22)
	body.border_color = PaintColours.YELLOW.darkened(0.25)
	body.set_border_width_all(5)
	body.anti_aliasing = true
	draw_style_box(body, sponge_rect)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 7
	for hole_index in 9:
		var hole: Vector2 = Vector2(random.randf_range(-0.38, 0.38), random.randf_range(-0.3, 0.3)) * sponge_size
		draw_circle(hole, random.randf_range(5, 9), PaintColours.YELLOW.darkened(0.15))
	for bubble_index in 3:
		var bubble_angle: float = squish_age * 1.5 + bubble_index * 2.1
		var bubble: Vector2 = Vector2(-40 + bubble_index * 40, -sponge_size.y / 2.0 - 14 + sin(bubble_angle) * 5)
		draw_circle(bubble, 9.0 - bubble_index * 1.5, Color(1, 1, 1, 0.85))
	if hold_progress > 0.0:
		draw_arc(Vector2.ZERO, 92, -PI / 2.0, -PI / 2.0 + TAU, 48, Color(1, 1, 1, 0.5), 14, true)
		draw_arc(Vector2.ZERO, 92, -PI / 2.0, -PI / 2.0 + TAU * hold_progress, 48, PaintColours.BLUE, 14, true)
