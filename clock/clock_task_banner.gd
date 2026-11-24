class_name ClockTaskBanner
extends Control
## The task card across the top of Clock mode, in the Meadow banner's style:
## a little clock, the sentence, a small line under it for help, and a row of
## stars on the right - one for each card right first time this session.
## While a card is up it wears its job: an orange rim and a winding clock
## for set cards, a blue rim and two eyes for read cards (see ClockJob).

const CARD_HEIGHT: float = 140.0
const MOST_WIDTH: float = 1300.0
const LEAST_WIDTH: float = 640.0
const SHOWN_Y: float = 14.0
const HIDDEN_Y: float = -180.0
## Centred in the space right of the controls hint.
const AREA_LEFT: float = 360.0
const AREA_WIDTH: float = 1520.0
const TEXT_LEFT: float = 150.0
const TEXT_RIGHT_MARGIN: float = 50.0
const MAIN_FONT_SIZE: int = 50
const SMALL_FONT_SIZE: int = 32
const STAR_SPACING: float = 34.0
const STAR_RADIUS: float = 16.0

## The big line, and the small line under it ("" for none).
var main_text: String = ""
var small_text: String = ""
var card_width: float = MOST_WIDTH
## Stars: how many earned, out of how many cards this session (0 hides the row).
var stars_earned: int = 0
var stars_total: int = 0
var slide_tween: Tween
var flash: float = 0.0
var job: ClockJob.Job = ClockJob.Job.NONE:
	set(new_job):
		job = new_job
		queue_redraw()


func _ready() -> void:
	size = Vector2(MOST_WIDTH, CARD_HEIGHT)
	position = Vector2(AREA_LEFT, HIDDEN_Y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_text(new_main_text: String, new_small_text: String = "") -> void:
	main_text = new_main_text
	small_text = new_small_text
	var font: Font = get_theme_default_font()
	var main_width: float = font.get_string_size(main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, MAIN_FONT_SIZE).x
	var small_width: float = font.get_string_size(small_text, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE).x
	var text_width: float = maxf(main_width, small_width)
	card_width = clampf(text_width + TEXT_LEFT + TEXT_RIGHT_MARGIN + stars_room(), LEAST_WIDTH, MOST_WIDTH)
	size = Vector2(card_width, CARD_HEIGHT)
	position.x = AREA_LEFT + (AREA_WIDTH - card_width) / 2.0
	queue_redraw()
	slide_to(SHOWN_Y)


func set_stars(earned: int, total: int) -> void:
	stars_earned = earned
	stars_total = total
	show_text(main_text, small_text)


func stars_room() -> float:
	return STAR_SPACING * stars_total + 20.0 if stars_total > 0 else 0.0


func hide_card() -> void:
	slide_to(HIDDEN_Y)


func slide_to(y: float) -> void:
	if slide_tween != null:
		slide_tween.kill()
	slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func celebrate() -> void:
	flash = 1.0


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = move_toward(flash, 0.0, delta * 1.5)
		queue_redraw()


func _draw() -> void:
	if main_text == "":
		return
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE.lerp(PaintColours.YELLOW, flash * 0.6)
	card.set_corner_radius_all(44)
	card.shadow_color = Color(0, 0, 0, 0.2)
	card.shadow_size = 12
	card.shadow_offset = Vector2(0, 6)
	card.anti_aliasing = true
	if job != ClockJob.Job.NONE:
		card.border_color = ClockJob.colour_for(job)
		card.set_border_width_all(8)
	draw_style_box(card, Rect2(Vector2.ZERO, size))
	var picture_centre: Vector2 = Vector2(75, CARD_HEIGHT / 2.0)
	draw_job_picture(picture_centre)
	var font: Font = get_theme_default_font()
	var room_for_text: float = card_width - TEXT_LEFT - TEXT_RIGHT_MARGIN - stars_room()
	draw_stars()
	var main_baseline: float = CARD_HEIGHT / 2.0 + MAIN_FONT_SIZE * 0.35
	if small_text != "":
		main_baseline -= 20.0
	var font_size: int = fitting_font_size(font, main_text, room_for_text)
	draw_string(font, Vector2(TEXT_LEFT, main_baseline), main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PaintColours.INK)
	if small_text != "":
		var small_size: int = SMALL_FONT_SIZE
		while small_size > 20 and font.get_string_size(small_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size).x > room_for_text:
			small_size -= 2
		draw_string(font, Vector2(TEXT_LEFT, main_baseline + 46), small_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_size, Color(PaintColours.INK, 0.75))


## A plain clock between cards; a clock with a winding arrow for set cards;
## two big eyes for read cards.
func draw_job_picture(centre: Vector2) -> void:
	if job == ClockJob.Job.NONE:
		draw_circle(centre, 50, PaintColours.CYAN.lightened(0.6))
		MenuIcons.draw_icon(self, "clock", centre, 78, PaintColours.CYAN.darkened(0.1))
		return
	var colour: Color = ClockJob.colour_for(job)
	draw_circle(centre, 50, colour.lightened(0.6))
	if job == ClockJob.Job.WIND:
		MenuIcons.draw_icon(self, "clock", centre, 66, colour.darkened(0.1))
		draw_arc(centre, 40, deg_to_rad(-80), deg_to_rad(10), 16, colour.darkened(0.25), 7, true)
		var tip_base: Vector2 = centre + Vector2.from_angle(deg_to_rad(10)) * 40
		draw_colored_polygon(PackedVector2Array([tip_base + Vector2(-10, 0), tip_base + Vector2(10, 0), tip_base + Vector2(-6, 14)]), colour.darkened(0.25))
		return
	for side in [-1.0, 1.0]:
		var eye: Vector2 = centre + Vector2(side * 18.0, 0)
		draw_set_transform(eye, 0.0, Vector2(1.0, 1.35))
		draw_circle(Vector2.ZERO, 15, Color.WHITE)
		draw_arc(Vector2.ZERO, 15, 0, TAU, 32, PaintColours.INK, 3, true)
		draw_circle(Vector2(2, 2), 7, PaintColours.INK)
		draw_set_transform(Vector2.ZERO)


## One star per card, in a row on the right, filled in as they're earned.
func draw_stars() -> void:
	for star_index in stars_total:
		var centre: Vector2 = Vector2(card_width - TEXT_RIGHT_MARGIN / 2.0 - STAR_SPACING * (stars_total - star_index) + STAR_SPACING / 2.0, CARD_HEIGHT / 2.0)
		var earned: bool = star_index < stars_earned
		var points: PackedVector2Array = PackedVector2Array()
		for point_index in 10:
			var radius: float = STAR_RADIUS if point_index % 2 == 0 else STAR_RADIUS * 0.45
			points.append(centre + Vector2.from_angle(-PI / 2.0 + TAU * point_index / 10.0) * radius)
		draw_colored_polygon(points, PaintColours.YELLOW if earned else Color(PaintColours.INK, 0.22))
		if earned:
			points.append(points[0])
			draw_polyline(points, PaintColours.ORANGE.darkened(0.2), 2.0, true)


func fitting_font_size(font: Font, text: String, room: float) -> int:
	for font_size in range(MAIN_FONT_SIZE, 33, -2):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= room:
			return font_size
	return 34
