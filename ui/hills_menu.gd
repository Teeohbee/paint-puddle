extends MenuScreen
## Pick a Rainbow Hills level. Each one unlocks when the one before it is done.
## Twenty levels to a page: More on the right goes to the next page, and Back on
## the left goes to the page before (or the play menu from the first page).

const LEVEL_TILE_SIZE: Vector2 = Vector2(170, 170)
const LEVELS_PER_ROW: int = 5
const LEVELS_PER_PAGE: int = 20
const TILE_GAP: int = 24

var page: int = 0
var page_holder: Control


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Rainbow Hills", 50)
	var level_to_focus: int = level_to_start_on()
	show_page(floori(level_to_focus / float(LEVELS_PER_PAGE)), level_to_focus)


## Builds one page of levels and puts the D-pad on the given level, or on
## More if that level isn't on this page.
func show_page(new_page: int, level_to_focus: int) -> void:
	page = new_page
	if page_holder != null:
		page_holder.queue_free()
	# Back on the left, then the levels in rows beside it, then More
	var row: HBoxContainer = make_tile_row(200, 50)
	page_holder = row.get_parent()
	page_holder.offset_bottom = 1040
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(200, 200))
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	back.chosen.connect(go_back)
	var level_rows: VBoxContainer = VBoxContainer.new()
	level_rows.add_theme_constant_override("separation", TILE_GAP)
	row.add_child(level_rows)
	var level_row: HBoxContainer = null
	var first_level: int = page * LEVELS_PER_PAGE
	var last_level: int = mini(first_level + LEVELS_PER_PAGE, HillsLevels.level_count()) - 1
	var tile_to_start_on: MenuTile = null
	for level_index in range(first_level, last_level + 1):
		if (level_index - first_level) % LEVELS_PER_ROW == 0:
			level_row = HBoxContainer.new()
			level_row.add_theme_constant_override("separation", TILE_GAP)
			level_row.alignment = BoxContainer.ALIGNMENT_CENTER
			level_rows.add_child(level_row)
		var level: Dictionary = HillsLevels.LEVELS[level_index]
		var tile: MenuTile = make_tile(level.name, "text:%d" % (level_index + 1), PaintMixing.colour_of(level.paint), LEVEL_TILE_SIZE)
		tile.is_locked = not HillsLevels.is_unlocked(level_index)
		tile.chosen.connect(play_level.bind(level_index))
		level_row.add_child(tile)
		if level_index == level_to_focus:
			tile_to_start_on = tile
	if last_level + 1 < HillsLevels.level_count():
		var more: MenuTile = make_tile("More", "more", PaintColours.ORANGE, Vector2(200, 200))
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		more.is_locked = not HillsLevels.is_unlocked(last_level + 1)
		more.chosen.connect(func(): show_page(page + 1, last_level + 1))
		row.add_child(more)
		if tile_to_start_on == null:
			tile_to_start_on = more
	first_focus = tile_to_start_on
	tile_to_start_on.grab_focus_quietly.call_deferred()


func go_back() -> void:
	if page == 0:
		SceneManager.go_to("res://ui/play_menu.tscn")
	else:
		# Land on More, the way back to where we were
		show_page(page - 1, -1)


func play_level(level_index: int) -> void:
	HillsLevel.level_to_play = level_index
	SceneManager.go_to("res://hills/hills_level.tscn")


## The level after the one just finished, or the latest open level.
func level_to_start_on() -> int:
	var last_level: int = HillsLevels.level_count() - 1
	var latest_unlocked: int = mini(GameSettings.get_progress("hills_levels_completed"), last_level)
	var just_finished: int = HillsLevel.level_just_finished
	HillsLevel.level_just_finished = -1
	if just_finished < 0:
		return latest_unlocked
	return mini(just_finished + 1, last_level)
