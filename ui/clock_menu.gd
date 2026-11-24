extends MenuScreen
## The Clock menu: Back, then a big "Play with the clock" tile (where the
## cursor starts), then the ladder - rungs 1 to 3, each opening when the one
## before it is cleared (or with "Open everything" in the grown-up settings),
## and faded "Coming soon" tiles for the rungs still being rebuilt. A rung
## that isn't built yet says "Coming soon" too.
##
## The tricky faces are parked, so there's no Tricky tile.

const RUNG_TILE_SIZE: Vector2 = Vector2(220, 220)
const FREE_PLAY_TILE_SIZE: Vector2 = Vector2(340, 468)
const LADDER_RUNGS: int = 3
const TILE_GAP: int = 28
## The tiles go round the rainbow, like the numbers on the clock.
const RUNG_COLOURS: Array[Color] = [PaintColours.RED, PaintColours.ORANGE, PaintColours.YELLOW]
## The later rungs, shown as coming soon: a title and a rung whose clock the tile shows.
const COMING_SOON: Array[Dictionary] = [
	{"title": "quarters", "rung": 4},
	{"title": "5 minutes", "rung": 6},
	{"title": "minutes", "rung": 8},
]
const COMING_SOON_COLOUR: Color = PaintColours.GREEN

var rung_tiles: Array[MenuTile] = []
var coming_soon_tiles: Array[MenuTile] = []
var back: MenuTile
var free_play: MenuTile
var rungs_cleared: int = 0
var all_rungs_opened: bool = false


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Clock", 50)
	ClockMode.tricky_replay = false
	rungs_cleared = GameSettings.get_progress("clock_rungs_cleared")
	all_rungs_opened = GameSettings.get_setting("open_all_clock_rungs") == 1
	var row: HBoxContainer = make_tile_row(200, 50)
	row.get_parent().offset_bottom = 1040
	back = make_back_tile()
	row.add_child(back)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	free_play = make_tile("Play with the clock", "clock", PaintColours.CYAN, FREE_PLAY_TILE_SIZE)
	free_play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	free_play.chosen.connect(play_free)
	row.add_child(free_play)
	var ladder: VBoxContainer = VBoxContainer.new()
	ladder.add_theme_constant_override("separation", TILE_GAP)
	row.add_child(ladder)
	var rung_row: HBoxContainer = make_ladder_row(ladder)
	for rung in range(1, LADDER_RUNGS + 1):
		var tile: MenuTile = make_tile(ClockRungs.title(rung), icon_for(rung), RUNG_COLOURS[rung - 1], RUNG_TILE_SIZE)
		if rung > ClockRungs.RUNGS_BUILT:
			show_as_coming_soon(tile)
		else:
			tile.is_locked = not ClockRungs.is_open(rung, rungs_cleared, all_rungs_opened)
		tile.chosen.connect(play_rung.bind(rung))
		rung_row.add_child(tile)
		rung_tiles.append(tile)
	var coming_soon_row: HBoxContainer = make_ladder_row(ladder)
	for later in COMING_SOON:
		var tile: MenuTile = make_tile(later["title"], icon_for(later["rung"]), COMING_SOON_COLOUR, RUNG_TILE_SIZE)
		show_as_coming_soon(tile)
		coming_soon_row.add_child(tile)
		coming_soon_tiles.append(tile)
	first_focus = tile_to_start_on()
	first_focus.grab_focus_quietly.call_deferred()


func make_ladder_row(ladder: VBoxContainer) -> HBoxContainer:
	var ladder_row: HBoxContainer = HBoxContainer.new()
	ladder_row.add_theme_constant_override("separation", TILE_GAP)
	ladder.add_child(ladder_row)
	return ladder_row


## Locked, faded, no padlock: not shut, just not ready.
func show_as_coming_soon(tile: MenuTile) -> void:
	tile.is_locked = true
	tile.shows_padlock = false
	tile.subtitle = "Coming soon"


## A little clock showing one of the rung's times, without the minute hand
## where the rung doesn't show it.
func icon_for(rung: int) -> String:
	var example: int = ClockRungs.example_minutes(rung)
	if not ClockRungs.shows_minute_hand(rung):
		example = -example
	return "clock_at:%d" % example


func play_free() -> void:
	ClockMode.free_play = true
	SceneManager.go_to("res://clock/clock_mode.tscn")


## Play with the clock, unless a rung was just cleared and the next one is
## open: then that one.
func tile_to_start_on() -> MenuTile:
	var just_finished: int = ClockMode.rung_just_finished
	ClockMode.rung_just_finished = 0
	var next_rung: int = just_finished + 1
	if just_finished > 0 and next_rung <= LADDER_RUNGS and not rung_tiles[next_rung - 1].is_locked:
		return rung_tiles[next_rung - 1]
	return free_play


func play_rung(rung: int) -> void:
	ClockMode.free_play = false
	ClockMode.rung_to_play = rung
	SceneManager.go_to("res://clock/clock_mode.tscn")
