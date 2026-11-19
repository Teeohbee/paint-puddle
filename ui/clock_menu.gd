extends MenuScreen
## Pick a Clock mode rung. Each one opens when the one before it is cleared
## (or all of them, with "Open all rungs" in the grown-up settings). Starts on
## the rung after the one just cleared, or the one being climbed.

const RUNG_TILE_SIZE: Vector2 = Vector2(220, 220)
const RUNGS_PER_ROW: int = 4
const TILE_GAP: int = 28
## The tiles go round the rainbow, like the numbers on the clock.
const RUNG_COLOURS: Array[Color] = [
	PaintColours.RED, PaintColours.ORANGE, PaintColours.YELLOW, PaintColours.GREEN,
	PaintColours.CYAN, PaintColours.BLUE, PaintColours.PURPLE, PaintColours.MAGENTA,
]

var rung_tiles: Array[MenuTile] = []
var back: MenuTile


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Clock", 50)
	var row: HBoxContainer = make_tile_row(200, 50)
	row.get_parent().offset_bottom = 1040
	back = make_tile("Back", "back", PaintColours.PURPLE, Vector2(200, 200))
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	var rung_rows: VBoxContainer = VBoxContainer.new()
	rung_rows.add_theme_constant_override("separation", TILE_GAP)
	row.add_child(rung_rows)
	var rung_row: HBoxContainer = null
	var rungs_cleared: int = GameSettings.get_progress("clock_rungs_cleared")
	var all_rungs_opened: bool = GameSettings.get_setting("open_all_clock_rungs") == 1
	for rung in range(1, ClockRungs.RUNG_COUNT + 1):
		if (rung - 1) % RUNGS_PER_ROW == 0:
			rung_row = HBoxContainer.new()
			rung_row.add_theme_constant_override("separation", TILE_GAP)
			rung_rows.add_child(rung_row)
		var tile: MenuTile = make_tile(ClockRungs.title(rung), icon_for(rung), RUNG_COLOURS[rung - 1], RUNG_TILE_SIZE)
		tile.is_locked = not ClockRungs.is_open(rung, rungs_cleared, all_rungs_opened)
		tile.chosen.connect(play_rung.bind(rung))
		rung_row.add_child(tile)
		rung_tiles.append(tile)
	first_focus = rung_tiles[rung_to_start_on(rungs_cleared) - 1]
	first_focus.grab_focus_quietly.call_deferred()


## A little clock showing one of the rung's times, without the minute hand
## where the rung doesn't show it.
func icon_for(rung: int) -> String:
	var example: int = ClockRungs.example_minutes(rung)
	if not ClockRungs.shows_minute_hand(rung):
		example = -example
	return "clock_at:%d" % example


func play_rung(rung: int) -> void:
	ClockMode.rung_to_play = rung
	SceneManager.go_to("res://clock/clock_mode.tscn")


## The rung after the one just finished, or the one being climbed (the top
## rung once they're all cleared).
func rung_to_start_on(rungs_cleared: int) -> int:
	var just_finished: int = ClockMode.rung_just_finished
	ClockMode.rung_just_finished = 0
	if just_finished > 0:
		return mini(just_finished + 1, ClockRungs.RUNG_COUNT)
	var climbing: int = ClockRungs.climbing_rung(rungs_cleared)
	if climbing == 0:
		return ClockRungs.RUNG_COUNT
	return climbing
