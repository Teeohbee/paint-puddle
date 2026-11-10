class_name MapMode
extends Node2D
## Map mode. The world screen shows seven continents: drive the pin onto one
## and press A to zoom in. A continent screen shows every country on it: the
## one under the pin's tip gets a white ring and its name, and A picks it.
## The globe in the corner zooms back out.

signal country_picked(country_id: String)
signal screen_changed(screen_name: String)
## Fired once a zoom has finished, with the continent the pin is now in (not for the world).
signal continent_entered(continent_id: String)
signal zoom_finished

const WORLD: String = "world"
const WORLD_POINTER_SPEED: float = 520.0
const CONTINENT_POINTER_SPEED: float = 380.0
const FIRST_CONTINENT: String = "europe"
const SECONDS_TO_ZOOM_OUT: float = 0.2
const SECONDS_TO_ZOOM_IN: float = 0.25
const ZOOM_OUT_SCALE: float = 1.6
const ZOOM_IN_START_SCALE: float = 0.7
const NAME_PILL_COLOUR: Color = Color(1.0, 0.97, 0.9, 0.92)
const NAME_FONT_SIZE: int = 76

var screen_name: String = WORLD
var screen: MapScreen
var screen_root: Node2D
var pointer: MapPointer
var effects_layer: Node2D
var controls_hint: ControlsHint
var globe_button: GlobeButton
var hint_arrow: HintArrow
var task_banner: MapTaskBanner
var task_runner: MapTaskRunner
var name_pill: PanelContainer
var name_label: Label
var is_changing_screen: bool = false
## What the pointer is over: a continent id on the world screen, a country id on a continent.
var target_under_pointer: String = ""
## The continent the pointer was last in, so zooming out lands back on it.
var last_continent: String = FIRST_CONTINENT


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	screen_root = Node2D.new()
	screen_root.name = "ScreenRoot"
	add_child(screen_root)
	# Above the HUD (layer 10), so the tip can be seen resting on the globe
	var pointer_layer: CanvasLayer = CanvasLayer.new()
	pointer_layer.layer = 11
	add_child(pointer_layer)
	hint_arrow = HintArrow.new()
	hint_arrow.name = "HintArrow"
	pointer_layer.add_child(hint_arrow)
	pointer = MapPointer.new()
	pointer.name = "Pointer"
	pointer_layer.add_child(pointer)
	effects_layer = Node2D.new()
	add_child(effects_layer)
	add_hud()
	build_screen(WORLD)
	task_runner = MapTaskRunner.new(self)
	task_runner.name = "TaskRunner"
	add_child(task_runner)
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func add_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	controls_hint.shows_jump = false
	controls_hint.shows_act_button = true
	hud.add_child(controls_hint)
	task_banner = MapTaskBanner.new()
	hud.add_child(task_banner)
	globe_button = GlobeButton.new()
	globe_button.visible = false
	hud.add_child(globe_button)
	name_pill = PanelContainer.new()
	name_pill.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	name_pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	name_pill.grow_vertical = Control.GROW_DIRECTION_BEGIN
	name_pill.offset_bottom = -40
	name_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = NAME_PILL_COLOUR
	pill_style.set_corner_radius_all(48)
	pill_style.content_margin_left = 52
	pill_style.content_margin_right = 52
	pill_style.content_margin_top = 14
	pill_style.content_margin_bottom = 22
	name_pill.add_theme_stylebox_override("panel", pill_style)
	name_pill.visible = false
	hud.add_child(name_pill)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", PaintColours.INK)
	name_pill.add_child(name_label)


func _physics_process(_delta: float) -> void:
	if is_changing_screen:
		return
	update_target_under_pointer()
	globe_button.is_hovered = globe_button.visible and globe_button.contains(pointer.position)
	if Input.is_action_just_pressed(PlayerControls.ACT_ACTION):
		press_a()


func update_target_under_pointer() -> void:
	var now_over: String = "" if globe_button.is_hovered else screen.target_at(pointer.position)
	if now_over == target_under_pointer:
		return
	target_under_pointer = now_over
	screen.set_highlight(now_over)
	name_pill.visible = now_over != ""
	if now_over != "":
		name_label.text = screen.name_of(now_over)
	if screen_name != WORLD and now_over != "":
		last_continent = screen_name


func press_a() -> void:
	pointer.squash_stretch.kick(Vector2(-6, 8))
	if globe_button.is_hovered:
		Sound.play("pop")
		zoom_to(WORLD)
		return
	if target_under_pointer == "":
		return
	Sound.play("pop")
	if screen_name == WORLD and MapData.continent(target_under_pointer)["zoomable"]:
		zoom_to(target_under_pointer)
	else:
		country_picked.emit(target_under_pointer)


## Zooms out of the current screen and into another.
func zoom_to(new_screen_name: String) -> void:
	is_changing_screen = true
	name_pill.visible = false
	var came_from_continent: String = screen_name if screen_name != WORLD else ""
	var tween: Tween = create_tween()
	tween.tween_method(zoom_out_step, 0.0, 1.0, SECONDS_TO_ZOOM_OUT)
	tween.tween_callback(build_screen.bind(new_screen_name, came_from_continent))
	tween.tween_method(zoom_in_step, 0.0, 1.0, SECONDS_TO_ZOOM_IN)
	tween.tween_callback(finish_changing_screen)


func zoom_out_step(progress: float) -> void:
	apply_zoom(lerpf(1.0, ZOOM_OUT_SCALE, ease(progress, 0.5)), 1.0 - progress)


func zoom_in_step(progress: float) -> void:
	apply_zoom(lerpf(ZOOM_IN_START_SCALE, 1.0, ease(progress, 0.4)), progress)


## Scales the screen about the pointer, so it feels like diving in at that spot.
func apply_zoom(zoom_scale: float, opacity: float) -> void:
	screen_root.scale = Vector2.ONE * zoom_scale
	screen_root.position = pointer.position * (1.0 - zoom_scale)
	screen_root.modulate.a = opacity


func finish_changing_screen() -> void:
	apply_zoom(1.0, 1.0)
	is_changing_screen = false
	target_under_pointer = ""
	update_target_under_pointer()
	zoom_finished.emit()
	if screen_name != WORLD:
		continent_entered.emit(screen_name)


## Fills a country in on the screen being shown (other screens fill it in when they are built).
func paint_country(country_id: String) -> void:
	if screen is ContinentScreen:
		screen.paint_country(country_id)


## Swaps in the world or one continent. Coming out of a continent lands the
## pointer on that continent; going in puts it in the middle.
func build_screen(new_screen_name: String, came_from_continent: String = "") -> void:
	if screen != null:
		screen.queue_free()
	screen_name = new_screen_name
	if new_screen_name == WORLD:
		screen = WorldScreen.new()
	else:
		var continent_screen: ContinentScreen = ContinentScreen.new()
		continent_screen.continent_id = new_screen_name
		screen = continent_screen
	screen.name = "Screen"
	screen_root.add_child(screen)
	screen_root.move_child(screen, 0)
	pointer.magnets = screen.magnets
	pointer.target_at = screen.target_at
	pointer.wraps_sideways = new_screen_name == WORLD
	pointer.velocity = Vector2.ZERO
	if new_screen_name == WORLD:
		var landing: String = came_from_continent if came_from_continent != "" else last_continent
		var label: Array = MapData.continent(landing)["label"]
		pointer.position = Vector2(label[0], label[1])
		pointer.mover.top_speed = WORLD_POINTER_SPEED
	else:
		last_continent = new_screen_name
		pointer.position = MapData.SCREEN_SIZE / 2.0 + Vector2(0, 60)
		pointer.mover.top_speed = CONTINENT_POINTER_SPEED
	globe_button.visible = new_screen_name != WORLD
	if new_screen_name != WORLD:
		globe_button.set_continent(new_screen_name)
	target_under_pointer = ""
	if not is_changing_screen:
		update_target_under_pointer()
	screen_changed.emit(new_screen_name)
