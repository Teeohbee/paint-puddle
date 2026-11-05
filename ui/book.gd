extends MenuScreen
## The book of everything found, in two parts. Words: each word spelled into
## life in the Meadow, with its picture. Colours: a puddle friend for every
## colour mixed, with what made it. Things not found yet are a grey "?", so
## it's easy to see what's left. Ten to a page, Back on the left, and a page
## bar underneath. Pick a picture to see it big. Finishing a part gets it a
## gold star, and confetti the first time the Book opens after.

const ENTRY_TILE_SIZE: Vector2 = Vector2(210, 210)
const BACK_TILE_SIZE: Vector2 = Vector2(200, 200)
const PAGE_BUTTON_SIZE: Vector2 = Vector2(340, 170)
const PAGE_TOP: float = 255.0
const FOCUS_FIRST_ENTRY: String = "first entry"
const FOCUS_PREVIOUS_PAGE: String = "previous page"
const FOCUS_NEXT_PAGE: String = "next page"
const ENTRIES_PER_ROW: int = 5
const ENTRIES_PER_PAGE: int = 10
const TILE_GAP: int = 30
const NOT_FOUND_COLOUR: Color = Color(0.72, 0.72, 0.76)
const SECTIONS: Dictionary = {
	"words": {"title": "Words", "collection": "words_spelled", "empty": "Spell a word in the Meadow to fill this page.",
		"all_found": "You found every word!"},
	"colours": {"title": "Colours", "collection": "colours_found", "empty": "Mix a colour to meet a puddle friend.",
		"all_found": "You found every colour!"},
}

## "" for the first page that picks Words or Colours.
var section: String = ""
var entries: Array[String] = []
var page: int = 0
var page_holder: Control
var heading: Label
var found_label: Label
var close_up: Control
var back_tile: MenuTile
var entry_tiles: Array[MenuTile] = []
var previous_page_tile: MenuTile
var next_page_tile: MenuTile
var page_label: Label


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	heading = make_heading("My Book", 70)
	found_label = make_heading("", 185)
	found_label.add_theme_font_size_override("font_size", 44)
	found_label.add_theme_constant_override("outline_size", 16)
	show_sections(last_choice("book", "words"))
	celebrate_newly_finished_parts()


## Every thing a Meadow task can bring to life, in the order the tasks come.
static func words_in_the_book() -> Array[String]:
	var words: Array[String] = []
	for task in MeadowTask.load_list(TaskRunner.TASKS_PATH):
		if task.thing != "" and not words.has(task.thing):
			words.append(task.thing)
	return words


static func entries_for(book_section: String) -> Array[String]:
	return words_in_the_book() if book_section == "words" else PaintMixing.all_friend_paints()


static func found_count(book_section: String) -> int:
	var count: int = 0
	for entry in entries_for(book_section):
		if GameSettings.has_found(SECTIONS[book_section].collection, entry):
			count += 1
	return count


static func is_finished(book_section: String) -> bool:
	return found_count(book_section) == entries_for(book_section).size()


## Confetti and a chime for a part finished since the Book last opened.
## Remembered in the save, so it's a once-only moment.
func celebrate_newly_finished_parts() -> void:
	for book_section in SECTIONS:
		if is_finished(book_section) and GameSettings.record_found("book_parts_celebrated", book_section):
			found_label.text = SECTIONS[book_section].all_found
			Sound.play("chime", 0.0)
			add_child(Confetti.new())
			return


func clear_page() -> void:
	if page_holder != null:
		page_holder.queue_free()


## The first page: Words or Colours, each saying how many are found.
func show_sections(section_to_focus: String) -> void:
	section = ""
	clear_page()
	heading.text = "My Book"
	found_label.text = ""
	var row: HBoxContainer = make_tile_row(330, 60)
	page_holder = row.get_parent()
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(220, 220))
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	var words: MenuTile = make_tile("Words", "", PaintColours.ORANGE, Vector2(400, 400))
	words.picture = "thing:cat"
	var colours: MenuTile = make_tile("Colours", "colour_set:paint", PaintColours.BLUE, Vector2(400, 400))
	for tile_and_section in [[words, "words"], [colours, "colours"]]:
		var tile: MenuTile = tile_and_section[0]
		var book_section: String = tile_and_section[1]
		var total: int = entries_for(book_section).size()
		tile.subtitle = "%d of %d" % [found_count(book_section), total]
		if is_finished(book_section):
			tile.subtitle = "All %d!" % total
			tile.has_gold_star = true
		tile.chosen.connect(open_section.bind(book_section))
	for tile in [back, words, colours]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	first_focus = colours if section_to_focus == "colours" else words
	first_focus.grab_focus_quietly.call_deferred()


func open_section(book_section: String) -> void:
	remember_choice("book", book_section)
	section = book_section
	entries = entries_for(book_section)
	heading.text = SECTIONS[book_section].title
	var count: int = found_count(book_section)
	if count == 0:
		found_label.text = SECTIONS[book_section].empty
	elif count == entries.size():
		found_label.text = SECTIONS[book_section].all_found
	else:
		found_label.text = "You have found %d of %d!" % [count, entries.size()]
	show_page(0)


func page_count() -> int:
	return maxi(1, ceili(entries.size() / float(ENTRIES_PER_PAGE)))


## Builds one page: Back on the left, the entries in rows, and under them the
## page bar - Back a page, which page this is, Next page. Down from any entry
## reaches the bar in two presses at most. "focus" is where the D-pad goes:
## FOCUS_FIRST_ENTRY, or the page button just pressed so mashing it flicks on.
func show_page(new_page: int, focus: String = FOCUS_FIRST_ENTRY) -> void:
	page = new_page
	clear_page()
	page_holder = CenterContainer.new()
	page_holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
	page_holder.offset_top = PAGE_TOP
	page_holder.offset_bottom = PAGE_TOP + 700
	add_child(page_holder)
	var page_column: VBoxContainer = VBoxContainer.new()
	page_column.add_theme_constant_override("separation", TILE_GAP + 10)
	page_holder.add_child(page_column)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 50)
	page_column.add_child(row)

	back_tile = make_tile("Back", "back", PaintColours.PURPLE, BACK_TILE_SIZE)
	back_tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_tile.chosen.connect(go_back)
	row.add_child(back_tile)
	var entry_rows: VBoxContainer = VBoxContainer.new()
	entry_rows.add_theme_constant_override("separation", TILE_GAP + 20)
	row.add_child(entry_rows)
	entry_tiles = []
	var entry_row: HBoxContainer = null
	var first_entry: int = page * ENTRIES_PER_PAGE
	var last_entry: int = mini(first_entry + ENTRIES_PER_PAGE, entries.size()) - 1
	for entry_index in range(first_entry, last_entry + 1):
		if (entry_index - first_entry) % ENTRIES_PER_ROW == 0:
			entry_row = HBoxContainer.new()
			entry_row.add_theme_constant_override("separation", TILE_GAP)
			entry_rows.add_child(entry_row)
		var tile: MenuTile = make_entry_tile(entry_index)
		entry_row.add_child(tile)
		entry_tiles.append(tile)

	page_column.add_child(make_page_bar())
	link_entries_to_page_bar()

	var tile_to_start_on: MenuTile = back_tile if entry_tiles.is_empty() else entry_tiles[0]
	if focus == FOCUS_PREVIOUS_PAGE and not previous_page_tile.is_locked:
		tile_to_start_on = previous_page_tile
	elif focus == FOCUS_NEXT_PAGE and not next_page_tile.is_locked:
		tile_to_start_on = next_page_tile
	first_focus = tile_to_start_on
	tile_to_start_on.grab_focus_quietly.call_deferred()


## Back a page, "Page 2 of 5" with a dot per page, Next page. Lined up under
## the entries rather than the Back tile. A button with nowhere to go is
## greyed out but stays put, so nothing jumps about.
func make_page_bar() -> HBoxContainer:
	var bar_row: HBoxContainer = HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 50)
	var under_back: Control = Control.new()
	under_back.custom_minimum_size = Vector2(BACK_TILE_SIZE.x, 0)
	bar_row.add_child(under_back)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.custom_minimum_size = Vector2(ENTRY_TILE_SIZE.x * ENTRIES_PER_ROW + TILE_GAP * (ENTRIES_PER_ROW - 1), 0)
	bar_row.add_child(bar)

	previous_page_tile = make_tile("Back a page", "back", PaintColours.ORANGE, PAGE_BUTTON_SIZE)
	previous_page_tile.chosen.connect(func(): show_page(page - 1, FOCUS_PREVIOUS_PAGE))
	next_page_tile = make_tile("Next page", "more", PaintColours.ORANGE, PAGE_BUTTON_SIZE)
	next_page_tile.chosen.connect(func(): show_page(page + 1, FOCUS_NEXT_PAGE))
	for page_button_and_is_possible in [[previous_page_tile, page > 0], [next_page_tile, page + 1 < page_count()]]:
		var page_button: MenuTile = page_button_and_is_possible[0]
		if not page_button_and_is_possible[1]:
			page_button.is_locked = true
			page_button.shows_padlock = false
			page_button.focus_mode = Control.FOCUS_NONE

	var page_label_column: VBoxContainer = VBoxContainer.new()
	page_label_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_label_column.alignment = BoxContainer.ALIGNMENT_CENTER
	page_label = Label.new()
	page_label.text = "Page %d of %d" % [page + 1, page_count()]
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size", 52)
	page_label.add_theme_color_override("font_color", PaintColours.INK)
	page_label.add_theme_color_override("font_outline_color", Color.WHITE)
	page_label.add_theme_constant_override("outline_size", 18)
	page_label_column.add_child(page_label)
	var dots: PageDots = PageDots.new()
	dots.page = page
	dots.page_count = page_count()
	page_label_column.add_child(dots)

	bar.add_child(previous_page_tile)
	bar.add_child(page_label_column)
	bar.add_child(next_page_tile)
	return bar_row


## Down from the bottom entries goes to the page bar: the left two columns
## to Back a page, the rest to Next page, or whichever of them can be
## picked. Entries with nothing under them go straight to the bar too.
func link_entries_to_page_bar() -> void:
	var can_go_back: bool = not previous_page_tile.is_locked
	var can_go_on: bool = not next_page_tile.is_locked
	for entry_number in entry_tiles.size():
		var tile: MenuTile = entry_tiles[entry_number]
		var has_an_entry_below: bool = entry_number + ENTRIES_PER_ROW < entry_tiles.size()
		if has_an_entry_below:
			continue
		var column: int = entry_number % ENTRIES_PER_ROW
		var wants_previous: bool = column < 2
		var page_button: MenuTile = null
		if (wants_previous and can_go_back) or (not can_go_on and can_go_back):
			page_button = previous_page_tile
		elif can_go_on:
			page_button = next_page_tile
		if page_button != null:
			tile.focus_neighbor_bottom = tile.get_path_to(page_button)
	if entry_tiles.is_empty():
		return
	var bottom_row_start: int = (entry_tiles.size() - 1) / ENTRIES_PER_ROW * ENTRIES_PER_ROW
	previous_page_tile.focus_neighbor_top = previous_page_tile.get_path_to(entry_tiles[bottom_row_start])
	previous_page_tile.focus_neighbor_left = previous_page_tile.get_path_to(back_tile)
	next_page_tile.focus_neighbor_top = next_page_tile.get_path_to(entry_tiles[entry_tiles.size() - 1])
	next_page_tile.focus_neighbor_right = NodePath(".")
	if can_go_back and can_go_on:
		previous_page_tile.focus_neighbor_right = previous_page_tile.get_path_to(next_page_tile)
		next_page_tile.focus_neighbor_left = next_page_tile.get_path_to(previous_page_tile)


func make_entry_tile(entry_index: int) -> MenuTile:
	var entry: String = entries[entry_index]
	if not GameSettings.has_found(SECTIONS[section].collection, entry):
		var mystery: MenuTile = make_tile("", "text:?", NOT_FOUND_COLOUR, ENTRY_TILE_SIZE)
		mystery.is_locked = true
		mystery.shows_padlock = false
		return mystery
	var tile: MenuTile
	if section == "words":
		var colour: Color = PaintColours.RAINBOW[entry_index % PaintColours.RAINBOW.size()]
		tile = make_tile(entry.to_upper(), "", colour.lerp(Color.WHITE, 0.35), ENTRY_TILE_SIZE)
		tile.picture = "thing:" + entry
	else:
		tile = make_tile(PaintMixing.friend_name_for(entry), "", friend_tile_colour(entry), ENTRY_TILE_SIZE)
		tile.picture = "friend:" + entry
	tile.chosen.connect(show_close_up.bind(tile))
	return tile


## Pale enough that the friend stands out, but never white on white.
static func friend_tile_colour(paint_name: String) -> Color:
	var colour: Color = PaintMixing.colour_of(paint_name)
	if colour.get_luminance() > 0.85:
		return Color(0.62, 0.72, 0.9)
	return colour.lerp(Color.WHITE, 0.45)


## "Red + blue + black", or what a first colour is for.
static func recipe_text(paint_name: String) -> String:
	var recipe: Array[String] = PaintMixing.recipe_for(paint_name)
	if recipe.size() <= 1:
		return "A first colour"
	var words: Array[String] = []
	for ingredient in recipe:
		words.append(PaintMixing.word_for(ingredient).to_lower())
	var text: String = " + ".join(words)
	return text.left(1).to_upper() + text.substr(1)


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
	if from_tile.picture.begins_with("friend:"):
		big.subtitle = recipe_text(from_tile.picture.trim_prefix("friend:"))
	holder.add_child(big)
	big.chosen.connect(hide_close_up.bind(from_tile))
	keep_focus_on(big)
	first_focus = big
	big.grab_focus_quietly.call_deferred()


## Every D-pad direction leads back to the tile itself, so the tiles hidden
## behind a close-up can't be reached.
static func keep_focus_on(tile: Control) -> void:
	var itself: NodePath = NodePath(".")
	tile.focus_neighbor_left = itself
	tile.focus_neighbor_right = itself
	tile.focus_neighbor_top = itself
	tile.focus_neighbor_bottom = itself
	tile.focus_next = itself
	tile.focus_previous = itself


func hide_close_up(back_to_tile: MenuTile) -> void:
	close_up.queue_free()
	close_up = null
	first_focus = back_to_tile
	back_to_tile.grab_focus_quietly.call_deferred()


## Straight back to Words or Colours from any page, not a page at a time.
func go_back() -> void:
	show_sections(section)


## A dot for every page, the one you're on filled in.
class PageDots extends Control:
	const DOT_RADIUS: float = 11.0
	const DOT_GAP: float = 36.0
	var page: int = 0
	var page_count: int = 1

	func _init() -> void:
		custom_minimum_size = Vector2(0, DOT_RADIUS * 2 + 12)

	func _draw() -> void:
		var first_x: float = size.x / 2.0 - DOT_GAP * (page_count - 1) / 2.0
		for dot in page_count:
			var centre: Vector2 = Vector2(first_x + DOT_GAP * dot, size.y / 2.0)
			draw_circle(centre, DOT_RADIUS + 3, Color.WHITE)
			if dot == page:
				draw_circle(centre, DOT_RADIUS, PaintColours.INK)
			else:
				draw_circle(centre, DOT_RADIUS - 3, Color(0.82, 0.82, 0.86))
