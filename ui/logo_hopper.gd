class_name LogoHopper
extends Node2D
## A blob that hops along the logo from letter to letter, picking up each
## letter's paint as it lands. The letter dips under it.

const SECONDS_PER_HOP: float = 0.5
const HOP_HEIGHT: float = 110.0
const STANDING_HEIGHT: float = 120.0

var logo: RainbowLogo
var look: PaintBlobLook
var letter_order: Array[int] = []
var current_step: int = 0
var step_direction: int = 1
var hop_progress: float = 0.0
var seconds_resting: float = 0.6


func _init(logo_to_hop_on: RainbowLogo) -> void:
	logo = logo_to_hop_on


func _ready() -> void:
	look = PaintBlobLook.new()
	look.scale = Vector2(1.1, 1.1)
	look.stretch_follows_look = false
	add_child(look)
	letter_order = logo.visible_letter_indices()
	look.paint_colour = logo.letter_colour(letter_order[0])
	position = standing_spot(letter_order[0])


func standing_spot(letter_index: int) -> Vector2:
	return logo.position + logo.letter_centre(letter_index) + Vector2(0, logo.letter_bob(letter_index) - STANDING_HEIGHT)


func _process(delta: float) -> void:
	var from_letter: int = letter_order[current_step]
	if seconds_resting > 0.0:
		seconds_resting -= delta
		position = standing_spot(from_letter)
		return
	var next_step: int = current_step + step_direction
	if next_step < 0 or next_step >= letter_order.size():
		step_direction = -step_direction
		next_step = current_step + step_direction
	var to_letter: int = letter_order[next_step]
	if hop_progress == 0.0:
		look.squash_stretch.kick(Vector2(10, -8))
	hop_progress = minf(hop_progress + delta / SECONDS_PER_HOP, 1.0)
	var ground: Vector2 = standing_spot(from_letter).lerp(standing_spot(to_letter), hop_progress)
	position = ground - Vector2(0, sin(hop_progress * PI) * HOP_HEIGHT)
	look.look_direction = Vector2(step_direction, 0.3).normalized()
	if hop_progress >= 1.0:
		land_on(next_step)


func land_on(step: int) -> void:
	current_step = step
	hop_progress = 0.0
	var letter_index: int = letter_order[step]
	logo.dip_letter(letter_index)
	look.paint_colour = logo.letter_colour(letter_index)
	look.squash_stretch.kick(Vector2(-10, 9))
	seconds_resting = 0.15 if randf() < 0.8 else 1.2
