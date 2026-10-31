class_name ControlsHint
extends Control
## A soft reminder of the controls in the corner of the sky: the D-pad to
## walk and the A button to jump. Each part lights up while it's pressed,
## so it shows which thumb does what.

const CARD_SIZE: Vector2 = Vector2(300, 120)
const DPAD_CENTRE: Vector2 = Vector2(86, 60)
const BUTTON_CENTRE: Vector2 = Vector2(220, 60)
const ARM_LENGTH: float = 40.0
const ARM_WIDTH: float = 34.0
const BUTTON_RADIUS: float = 36.0
const RESTING_COLOUR: Color = Color(1, 1, 1, 0.75)
const ARROW_COLOUR: Color = Color(PaintColours.INK, 0.45)
const FADE_SPEED: float = 3.0

## How lit each part is, from 0 (resting) to 1 (pressed).
var glow: Dictionary = {"left": 0.0, "right": 0.0, "jump": 0.0}
var actions: Dictionary = {"left": "move_left", "right": "move_right", "jump": "act"}


func _ready() -> void:
	position = Vector2(24, 14)
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	for part in glow:
		if Input.is_action_pressed(actions[part]):
			glow[part] = 1.0
		else:
			glow[part] = move_toward(glow[part], 0.0, FADE_SPEED * delta)
	queue_redraw()


func _draw() -> void:
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color(1, 1, 1, 0.3)
	card.set_corner_radius_all(44)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(Vector2.ZERO, size))
	draw_dpad()
	draw_jump_button()


func draw_dpad() -> void:
	var arms: Dictionary = {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}
	# One shape for the whole cross, so see-through pieces don't overlap
	var half_width: float = ARM_WIDTH / 2.0
	var reach: float = half_width + ARM_LENGTH
	var w: float = half_width
	var cross: PackedVector2Array = PackedVector2Array()
	for point in [Vector2(-w, -reach), Vector2(w, -reach), Vector2(w, -w), Vector2(reach, -w), Vector2(reach, w), Vector2(w, w),
			Vector2(w, reach), Vector2(-w, reach), Vector2(-w, w), Vector2(-reach, w), Vector2(-reach, -w), Vector2(-w, -w)]:
		cross.append(DPAD_CENTRE + point)
	draw_colored_polygon(cross, RESTING_COLOUR)
	for arm in arms:
		var direction: Vector2 = arms[arm]
		var lit: float = glow.get(arm, 0.0)
		var arm_centre: Vector2 = DPAD_CENTRE + direction * (half_width + ARM_LENGTH / 2.0)
		var arm_size: Vector2 = Vector2(ARM_LENGTH, ARM_WIDTH) if direction.y == 0.0 else Vector2(ARM_WIDTH, ARM_LENGTH)
		if lit > 0.0:
			draw_rect(Rect2(arm_centre - arm_size / 2.0, arm_size), Color(PaintColours.YELLOW, lit))
		if arm == "up" or arm == "down":
			continue
		var tip: Vector2 = arm_centre + direction * (8.0 + lit * 3.0)
		var side: Vector2 = direction.orthogonal() * 10.0
		var back: Vector2 = tip - direction * 14.0
		draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), ARROW_COLOUR.lerp(PaintColours.INK, lit))


func draw_jump_button() -> void:
	var lit: float = glow["jump"]
	var radius: float = BUTTON_RADIUS * (1.0 + lit * 0.12)
	draw_circle(BUTTON_CENTRE, radius, RESTING_COLOUR.lerp(PaintColours.GREEN, lit))
	var letter_colour: Color = ARROW_COLOUR.lerp(Color.WHITE, lit)
	var font: Font = get_theme_default_font()
	var font_size: int = int(radius * 1.3)
	var letter_size: Vector2 = font.get_string_size("A", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, BUTTON_CENTRE + Vector2(-letter_size.x / 2.0, font_size * 0.36), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, letter_colour)
