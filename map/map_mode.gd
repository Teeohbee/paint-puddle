class_name MapMode
extends Node2D
## Map mode: drive the blob round the world. The country under the blob gets
## a white ring and its name along the bottom; A picks it.

signal country_picked(country_id: String)

const BLOB_SCENE: PackedScene = preload("res://blob/meadow_blob.tscn")
## Crossing the whole map takes about nine seconds.
const BLOB_TOP_SPEED: float = 520.0
const BLOB_START: Vector2 = Vector2(2430, 520)
const KEEP_BLOB_INSIDE_BY: float = 50.0
const NAME_PILL_COLOUR: Color = Color(1.0, 0.97, 0.9, 0.92)
const NAME_FONT_SIZE: int = 76

var world_map: WorldMap
var blob: MeadowBlob
var camera: Camera2D
var effects_layer: Node2D
var controls_hint: ControlsHint
var name_pill: PanelContainer
var name_label: Label
## The country the blob is over right now, "" over the sea.
var country_under_blob: String = ""


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	world_map = WorldMap.new()
	add_child(world_map)
	blob = BLOB_SCENE.instantiate()
	blob.position = BLOB_START
	blob.mover.top_speed = BLOB_TOP_SPEED
	add_child(blob)
	effects_layer = Node2D.new()
	add_child(effects_layer)
	add_camera()
	add_hud()
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func add_camera() -> void:
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_map.map_size.x)
	camera.limit_bottom = int(world_map.map_size.y)
	camera.position = blob.position
	add_child(camera)
	camera.make_current()


func add_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	controls_hint.shows_jump = false
	controls_hint.shows_act_button = true
	hud.add_child(controls_hint)
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
	blob.position = blob.position.clamp(
		Vector2.ONE * KEEP_BLOB_INSIDE_BY, world_map.map_size - Vector2.ONE * KEEP_BLOB_INSIDE_BY)
	camera.position = blob.position
	update_country_under_blob()
	if Input.is_action_just_pressed(PlayerControls.ACT_ACTION):
		pick_country_under_blob()


func update_country_under_blob() -> void:
	var now_over: String = world_map.country_at(blob.position)
	if now_over == country_under_blob:
		return
	country_under_blob = now_over
	world_map.set_highlight(now_over)
	name_pill.visible = now_over != ""
	if now_over != "":
		name_label.text = world_map.countries[now_over].display_name


func pick_country_under_blob() -> void:
	blob.look.squash_stretch.kick(Vector2(-10, 10))
	if country_under_blob == "":
		return
	Sound.play("pop")
	country_picked.emit(country_under_blob)
