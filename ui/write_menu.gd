extends MenuScreen
## Pick a letter to trace. All 26, in the order school teaches them, each
## opening once the one before it is traced (or all of them, with "Open
## everything" in the grown-up settings). Starts on the letter after the one
## just traced, or the next one to trace.
##
## Back stands on its own left of the letters, as on the Clock menu.

const LETTER_TILE_SIZE: Vector2 = Vector2(150, 150)
const LETTERS_PER_ROW: int = 9
const TILE_GAP: int = 20

var letter_tiles: Array[MenuTile] = []


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Write", 80)
	var row: HBoxContainer = make_tile_row(250, 50)
	row.get_parent().offset_bottom = 1000
	var back: MenuTile = make_back_tile()
	row.add_child(back)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	var letter_rows: VBoxContainer = VBoxContainer.new()
	letter_rows.add_theme_constant_override("separation", TILE_GAP)
	row.add_child(letter_rows)
	var letter_row: HBoxContainer = null
	for index in TracingLetters.ORDER.length():
		if index % LETTERS_PER_ROW == 0:
			letter_row = HBoxContainer.new()
			letter_row.add_theme_constant_override("separation", TILE_GAP)
			letter_rows.add_child(letter_row)
		var paint_name: String = TracingMode.LETTER_PAINTS[index % TracingMode.LETTER_PAINTS.size()]
		var tile: MenuTile = make_tile("", "text:" + TracingLetters.ORDER[index], PaintMixing.colour_of(paint_name), LETTER_TILE_SIZE)
		tile.icon_height = 0.5
		tile.icon_scale = 0.5
		tile.is_locked = not TracingMode.is_letter_open(index)
		tile.chosen.connect(trace_letter.bind(index))
		letter_row.add_child(tile)
		letter_tiles.append(tile)
	first_focus = letter_tiles[letter_to_start_on()]
	if first_focus.is_locked:
		first_focus = back
	first_focus.grab_focus_quietly.call_deferred()


func trace_letter(index: int) -> void:
	TracingMode.letter_to_play = index
	SceneManager.go_to("res://tracing/tracing_mode.tscn")


## The letter after the one just traced, or the next to trace (the last
## letter once they're all traced).
func letter_to_start_on() -> int:
	var last_index: int = TracingLetters.ORDER.length() - 1
	var just_finished: int = TracingMode.letter_just_finished
	TracingMode.letter_just_finished = -1
	if just_finished >= 0:
		return mini(just_finished + 1, last_index)
	return mini(GameSettings.get_progress("letters_traced"), last_index)
