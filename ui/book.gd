extends MenuScreen
## The book of everything found: each word spelled into life in the Meadow,
## with its picture. Things not found yet are a grey "?", so it's easy to
## see what's left. Ten to a page like the Hills menu: Back on the left,
## More on the right. Pick a picture to see it big.

const ENTRY_TILE_SIZE: Vector2 = Vector2(230, 230)
const ENTRIES_PER_ROW: int = 5
const ENTRIES_PER_PAGE: int = 10
const TILE_GAP: int = 30
const NOT_FOUND_COLOUR: Color = Color(0.72, 0.72, 0.76)

var entries: Array[String] = []
var page: int = 0
var page_holder: Control
var found_label: Label
var close_up: Control


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("My Book", 70)
	found_label = make_heading("", 185)
	found_label.add_theme_font_size_override("font_size", 44)
	found_label.add_theme_constant_override("outline_size", 16)
	entries = words_in_the_book()
	var found_count: int = 0
	for entry in entries:
		if GameSettings.has_found("words_spelled", entry):
			found_count += 1
	if found_count == 0:
		found_label.text = "Spell a word in the Meadow to fill this book."
	else:
		found_label.text = "You have found %d of %d!" % [found_count, entries.size()]
	show_page(0, 0)


## Every thing a Meadow task can bring to life, in the order the tasks come.
static func words_in_the_book() -> Array[String]:
	var words: Array[String] = []
	for task in MeadowTask.load_list(TaskRunner.TASKS_PATH):
		if task.thing != "" and not words.has(task.thing):
			words.append(task.thing)
	return words


func page_count() -> int:
	return maxi(1, ceili(entries.size() / float(ENTRIES_PER_PAGE)))


## Builds one page and puts the D-pad on the given entry, or More if the
## entry isn't on this page.
func show_page(new_page: int, entry_to_focus: int) -> void:
	page = new_page
	if page_holder != null:
		page_holder.queue_free()
	var row: HBoxContainer = make_tile_row(290, 50)
	page_holder = row.get_parent()
	page_holder.offset_bottom = 290 + 620
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(200, 200))
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	back.chosen.connect(go_back)
	var entry_rows: VBoxContainer = VBoxContainer.new()
	entry_rows.add_theme_constant_override("separation", TILE_GAP + 20)
	row.add_child(entry_rows)
	var entry_row: HBoxContainer = null
	var first_entry: int = page * ENTRIES_PER_PAGE
	var last_entry: int = mini(first_entry + ENTRIES_PER_PAGE, entries.size()) - 1
	var tile_to_start_on: MenuTile = back
	for entry_index in range(first_entry, last_entry + 1):
		if (entry_index - first_entry) % ENTRIES_PER_ROW == 0:
			entry_row = HBoxContainer.new()
			entry_row.add_theme_constant_override("separation", TILE_GAP)
			entry_rows.add_child(entry_row)
		var tile: MenuTile = make_entry_tile(entry_index)
		entry_row.add_child(tile)
		if entry_index == entry_to_focus or (entry_index == first_entry and tile_to_start_on == back):
			tile_to_start_on = tile
	if page + 1 < page_count():
		var more: MenuTile = make_tile("More", "more", PaintColours.ORANGE, Vector2(200, 200))
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		more.chosen.connect(func(): show_page(page + 1, (page + 1) * ENTRIES_PER_PAGE))
		row.add_child(more)
		if entry_to_focus > last_entry:
			tile_to_start_on = more
	first_focus = tile_to_start_on
	tile_to_start_on.grab_focus_quietly.call_deferred()


func make_entry_tile(entry_index: int) -> MenuTile:
	var thing_name: String = entries[entry_index]
	if not GameSettings.has_found("words_spelled", thing_name):
		var mystery: MenuTile = make_tile("", "text:?", NOT_FOUND_COLOUR, ENTRY_TILE_SIZE)
		mystery.is_locked = true
		mystery.shows_padlock = false
		return mystery
	var colour: Color = PaintColours.RAINBOW[entry_index % PaintColours.RAINBOW.size()]
	var tile: MenuTile = make_tile(thing_name.to_upper(), "", colour.lerp(Color.WHITE, 0.35), ENTRY_TILE_SIZE)
	tile.picture = "thing:" + thing_name
	tile.chosen.connect(show_close_up.bind(tile))
	return tile


## The picture big in the middle of the screen. Picking it again puts it away.
func show_close_up(from_tile: MenuTile) -> void:
	close_up = Control.new()
	close_up.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(close_up)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.16, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_up.add_child(dim)
	var holder: CenterContainer = CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_up.add_child(holder)
	var big: MenuTile = make_tile(from_tile.word, "", from_tile.paint_colour, Vector2(620, 620))
	big.picture = from_tile.picture
	holder.add_child(big)
	big.chosen.connect(hide_close_up.bind(from_tile))
	first_focus = big
	big.grab_focus_quietly.call_deferred()


func hide_close_up(back_to_tile: MenuTile) -> void:
	close_up.queue_free()
	close_up = null
	first_focus = back_to_tile
	back_to_tile.grab_focus_quietly.call_deferred()


func go_back() -> void:
	if page == 0:
		SceneManager.go_to("res://ui/play_menu.tscn")
	else:
		show_page(page - 1, entries.size())
