extends MenuScreen
## The book of everything found, in three parts. Words: each word spelled into
## life in the Meadow, with its picture. Colours: a puddle friend for every
## colour mixed, with what made it. Countries: a flag for every country found
## in Map mode. Things not found yet are a grey "?", so
## it's easy to see what's left. Thirty-two to a page, Back in the top-left
## corner, and a tall page tab either side. Pick a picture to see it big. Finishing a part gets it a
## gold star, and confetti the first time the Book opens after.

const ENTRY_TILE_SIZE: Vector2 = Vector2(150, 150)
const BACK_TILE_SIZE: Vector2 = Vector2(150, 150)
const BACK_TILE_CORNER: Vector2 = Vector2(95, 80)
const PAGE_TAB_SIZE: Vector2 = Vector2(110, 560)
const TAB_GAP: int = 40
const PAGE_TOP: float = 240.0
const FOCUS_FIRST_ENTRY: String = "first entry"
const FOCUS_PREVIOUS_PAGE: String = "previous page"
const FOCUS_NEXT_PAGE: String = "next page"
const ENTRIES_PER_ROW: int = 8
const ROWS_PER_PAGE: int = 4
const ENTRIES_PER_PAGE: int = ENTRIES_PER_ROW * ROWS_PER_PAGE
const TILE_GAP: int = 24
const ROW_GAP: int = 8
const NOT_FOUND_COLOUR: Color = Color(0.72, 0.72, 0.76)
## Names too long for a small tile; the close-up shows the whole name.
const SHORT_NAMES: Dictionary = {"united_kingdom": "UK", "united_arab_emirates": "UAE", "papua_new_guinea": "PNG", "north_macedonia": "N. Macedonia",
	"central_african_republic": "C. African Rep.", "bosnia_and_herzegovina": "Bosnia"}
const SECTIONS: Dictionary = {
	"words": {"title": "Words", "collection": "words_spelled", "empty": "Spell a word in the Meadow to fill this page.",
		"all_found": "You found every word!"},
	"colours": {"title": "Colours", "collection": "colours_found", "empty": "Mix a colour to meet a puddle friend.",
		"all_found": "You found every colour!"},
	"countries": {"title": "Countries", "collection": "countries_found", "empty": "Find a country in Map mode to fill this page.",
		"all_found": "You found every country!"},
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
var page_footer: VBoxContainer


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	heading = make_heading("My Book", 70)
	found_label = make_heading("", 165)
	found_label.add_theme_font_size_override("font_size", 40)
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


## Every country Map mode can ask for, A to Z.
static func countries_in_the_book() -> Array[String]:
	var countries: Array[String] = []
	for task in MapTask.load_list():
		if not countries.has(task.country_id):
			countries.append(task.country_id)
	countries.sort_custom(func(a: String, b: String) -> bool: return MapData.country(a)["name"] < MapData.country(b)["name"])
	return countries


static func entries_for(book_section: String) -> Array[String]:
	match book_section:
		"words":
			return words_in_the_book()
		"countries":
			return countries_in_the_book()
	return PaintMixing.all_friend_paints()


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
	var row: HBoxContainer = make_tile_row(330, 50)
	page_holder = row.get_parent()
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(220, 220))
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	var words: MenuTile = make_tile("Words", "", PaintColours.ORANGE, Vector2(400, 400))
	words.picture = "thing:cat"
	var colours: MenuTile = make_tile("Colours", "colour_set:paint", PaintColours.BLUE, Vector2(400, 400))
	var countries: MenuTile = make_tile("Countries", "", PaintColours.GREEN, Vector2(400, 400))
	countries.picture = "flag:japan"
	for tile_and_section in [[words, "words"], [colours, "colours"], [countries, "countries"]]:
		var tile: MenuTile = tile_and_section[0]
		var book_section: String = tile_and_section[1]
		var total: int = entries_for(book_section).size()
		tile.subtitle = "%d of %d" % [found_count(book_section), total]
		if is_finished(book_section):
			tile.subtitle = "All %d!" % total
			tile.has_gold_star = true
		tile.chosen.connect(open_section.bind(book_section))
	for tile in [back, words, colours, countries]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	first_focus = {"colours": colours, "countries": countries}.get(section_to_focus, words)
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


## Builds one page: Back in the top-left corner, the entries in rows, a tall
## page tab either side of them, and under them which page this is. Up from
## the top row reaches Back, left and right off the ends reach the tabs.
## "focus" is where the D-pad goes: FOCUS_FIRST_ENTRY, or the tab just
## pressed so mashing it flicks on.
func show_page(new_page: int, focus: String = FOCUS_FIRST_ENTRY) -> void:
	page = new_page
	clear_page()
	page_holder = Control.new()
	page_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_holder)

	back_tile = make_tile("Back", "back", PaintColours.PURPLE, BACK_TILE_SIZE)
	back_tile.position = BACK_TILE_CORNER
	back_tile.chosen.connect(go_back)
	page_holder.add_child(back_tile)

	var centre: CenterContainer = CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_TOP_WIDE)
	centre.offset_top = PAGE_TOP
	centre.offset_bottom = PAGE_TOP + 800
	page_holder.add_child(centre)
	var page_column: VBoxContainer = VBoxContainer.new()
	page_column.add_theme_constant_override("separation", 14)
	centre.add_child(page_column)
	var grid_row: HBoxContainer = HBoxContainer.new()
	grid_row.add_theme_constant_override("separation", TAB_GAP)
	page_column.add_child(grid_row)

	make_page_tabs()
	# Always the size of a full page, so a short last page doesn't shift anything
	var entry_rows: VBoxContainer = VBoxContainer.new()
	entry_rows.add_theme_constant_override("separation", ROW_GAP)
	entry_rows.custom_minimum_size = Vector2(
		ENTRY_TILE_SIZE.x * ENTRIES_PER_ROW + TILE_GAP * (ENTRIES_PER_ROW - 1),
		ENTRY_TILE_SIZE.y * ROWS_PER_PAGE + ROW_GAP * (ROWS_PER_PAGE - 1))
	grid_row.add_child(previous_page_tile)
	grid_row.add_child(entry_rows)
	grid_row.add_child(next_page_tile)
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

	page_column.add_child(make_page_footer())
	link_entries_to_tabs()
	link_back_tile()

	var tile_to_start_on: MenuTile = back_tile if entry_tiles.is_empty() else entry_tiles[0]
	if focus == FOCUS_PREVIOUS_PAGE and not previous_page_tile.is_locked:
		tile_to_start_on = previous_page_tile
	elif focus == FOCUS_NEXT_PAGE and not next_page_tile.is_locked:
		tile_to_start_on = next_page_tile
	first_focus = tile_to_start_on
	tile_to_start_on.grab_focus_quietly.call_deferred()


## Back a page and Next page: tall tabs with just an arrow. A tab with nowhere
## to go is greyed out but stays put, so nothing jumps about. A part with only
## one page has nowhere to go either way, so its tabs vanish but keep their
## space, and the grid sits where it does in every other part.
func make_page_tabs() -> void:
	previous_page_tile = make_tile("", "back", PaintColours.ORANGE, PAGE_TAB_SIZE)
	previous_page_tile.chosen.connect(func(): show_page(page - 1, FOCUS_PREVIOUS_PAGE))
	next_page_tile = make_tile("", "more", PaintColours.ORANGE, PAGE_TAB_SIZE)
	next_page_tile.chosen.connect(func(): show_page(page + 1, FOCUS_NEXT_PAGE))
	for tab_and_is_possible in [[previous_page_tile, page > 0], [next_page_tile, page + 1 < page_count()]]:
		var tab: MenuTile = tab_and_is_possible[0]
		tab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tab.icon_scale = 0.75
		tab.icon_height = 0.5
		if not tab_and_is_possible[1]:
			tab.is_locked = true
			tab.shows_padlock = false
			tab.focus_mode = Control.FOCUS_NONE
		if page_count() == 1:
			tab.modulate = Color.TRANSPARENT
			tab.mouse_filter = Control.MOUSE_FILTER_IGNORE


## A dot for every page and "Page 2 of 5", under the grid. Hidden but still
## taking up room in a one-page part, like the tabs.
func make_page_footer() -> VBoxContainer:
	page_footer = VBoxContainer.new()
	page_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	var dots: PageDots = PageDots.new()
	dots.page = page
	dots.page_count = page_count()
	page_footer.add_child(dots)
	page_label = Label.new()
	page_label.text = "Page %d of %d" % [page + 1, page_count()]
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size", 40)
	page_label.add_theme_color_override("font_color", PaintColours.INK)
	page_label.add_theme_color_override("font_outline_color", Color.WHITE)
	page_label.add_theme_constant_override("outline_size", 14)
	page_footer.add_child(page_label)
	if page_count() == 1:
		page_footer.modulate = Color.TRANSPARENT
	return page_footer


## Left off the first column reaches Back a page, right off the end of a row
## Next page, unless that tab is greyed, when the D-pad stays put. Down from a
## tile with nothing under it stays put too, rather than jumping diagonally.
## Each tab leads back in to the top row; up and down on a tab go nowhere.
func link_entries_to_tabs() -> void:
	var itself: NodePath = NodePath(".")
	for entry_number in entry_tiles.size():
		var tile: MenuTile = entry_tiles[entry_number]
		var column: int = entry_number % ENTRIES_PER_ROW
		var is_row_end: bool = column == ENTRIES_PER_ROW - 1 or entry_number == entry_tiles.size() - 1
		if entry_number + ENTRIES_PER_ROW >= entry_tiles.size():
			tile.focus_neighbor_bottom = itself
		if column == 0:
			tile.focus_neighbor_left = itself if previous_page_tile.is_locked else tile.get_path_to(previous_page_tile)
		if is_row_end:
			tile.focus_neighbor_right = itself if next_page_tile.is_locked else tile.get_path_to(next_page_tile)
	for tab in [previous_page_tile, next_page_tile]:
		tab.focus_neighbor_top = itself
		tab.focus_neighbor_bottom = itself
	previous_page_tile.focus_neighbor_left = itself
	next_page_tile.focus_neighbor_right = itself
	if entry_tiles.is_empty():
		return
	previous_page_tile.focus_neighbor_right = previous_page_tile.get_path_to(entry_tiles[0])
	var first_row_end: int = mini(ENTRIES_PER_ROW, entry_tiles.size()) - 1
	next_page_tile.focus_neighbor_left = next_page_tile.get_path_to(entry_tiles[first_row_end])


## Up from any tile in the top row goes to Back, and down from Back to the
## first tile. Back sits off on its own, so left and right go nowhere.
func link_back_tile() -> void:
	var itself: NodePath = NodePath(".")
	back_tile.focus_neighbor_left = itself
	back_tile.focus_neighbor_right = itself
	back_tile.focus_neighbor_top = itself
	if entry_tiles.is_empty():
		return
	back_tile.focus_neighbor_bottom = back_tile.get_path_to(entry_tiles[0])
	for column in mini(ENTRIES_PER_ROW, entry_tiles.size()):
		entry_tiles[column].focus_neighbor_top = entry_tiles[column].get_path_to(back_tile)


func make_entry_tile(entry_index: int) -> MenuTile:
	var entry: String = entries[entry_index]
	if not GameSettings.has_found(SECTIONS[section].collection, entry):
		var mystery: MenuTile = make_tile("", "text:?", NOT_FOUND_COLOUR, ENTRY_TILE_SIZE)
		mystery.is_locked = true
		mystery.shows_padlock = false
		return mystery
	var tile: MenuTile
	if section == "countries":
		var colour: Color = PaintColours.RAINBOW[entry_index % PaintColours.RAINBOW.size()]
		tile = make_tile(SHORT_NAMES.get(entry, MapData.country(entry)["name"]), "", colour.lerp(Color.WHITE, 0.35), ENTRY_TILE_SIZE)
		tile.picture = "flag:" + entry
	elif section == "words":
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
	var big: MenuTile = make_tile(from_tile.word if not from_tile.picture.begins_with("flag:") else MapData.country(from_tile.picture.trim_prefix("flag:"))["name"], "", from_tile.paint_colour, Vector2(620, 620))
	big.picture = from_tile.picture
	if from_tile.picture.begins_with("friend:"):
		big.subtitle = recipe_text(from_tile.picture.trim_prefix("friend:"))
	elif from_tile.picture.begins_with("flag:"):
		big.subtitle = MapData.continent(MapData.country(from_tile.picture.trim_prefix("flag:"))["home"])["name"]
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
