extends MenuScreen
## Where shall we play? The Meadow, the Hills, Paint, Splat, the Map or the Clock - or look at the book.
## Starts on whichever was picked last.

const PLACE_TILE_SIZE: Vector2 = Vector2(250, 250)
const TOP_ROW_Y: float = 260.0
const BOTTOM_ROW_Y: float = 580.0
const TILE_GAP: int = 40


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Where shall we play?", 150)
	var back: MenuTile = make_back_tile()
	var meadow: MenuTile = make_tile("Meadow", "meadow", PaintColours.RED, PLACE_TILE_SIZE)
	var hills: MenuTile = make_tile("Hills", "hills", PaintColours.BLUE, PLACE_TILE_SIZE)
	var paint: MenuTile = make_tile("Paint", "paint", PaintColours.GREEN, PLACE_TILE_SIZE)
	var splat: MenuTile = make_tile("Splat", "splat", PaintColours.YELLOW, PLACE_TILE_SIZE)
	var map: MenuTile = make_tile("Map", "map", PaintColours.PURPLE, PLACE_TILE_SIZE)
	var clock: MenuTile = make_tile("Clock", "clock", PaintColours.CYAN, PLACE_TILE_SIZE)
	var book: MenuTile = make_tile("Book", "book", PaintColours.ORANGE, PLACE_TILE_SIZE)
	var players: MenuTile = make_players_tile()
	var top_row: Array[MenuTile] = [back, meadow, hills, paint, splat]
	var bottom_row: Array[MenuTile] = [map, clock, book, players]
	fill_row(make_tile_row(TOP_ROW_Y, TILE_GAP), top_row)
	fill_row(make_tile_row(BOTTOM_ROW_Y, TILE_GAP), bottom_row)
	link_focus(top_row, bottom_row)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/title_screen.tscn"))
	var places: Dictionary = {
		"meadow": [meadow, "res://meadow/meadow.tscn"],
		"hills": [hills, "res://ui/hills_difficulty_menu.tscn"],
		"paint": [paint, "res://ui/paint_menu.tscn"],
		"splat": [splat, "res://paint/splat_party.tscn"],
		"map": [map, "res://map/map_mode.tscn"],
		"clock": [clock, "res://ui/clock_menu.tscn"],
		"book": [book, "res://ui/book.tscn"],
	}
	for place_name in places:
		var tile: MenuTile = places[place_name][0]
		var scene_path: String = places[place_name][1]
		tile.chosen.connect(go_to_place.bind(place_name, scene_path))
	# Back on the place played last, so coming out of it is one press from going back in
	first_focus = places[last_choice("play_menu", "meadow")][0]
	first_focus.grab_focus_quietly.call_deferred()


func fill_row(row: HBoxContainer, tiles: Array[MenuTile]) -> void:
	for tile in tiles:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)


## Left and right read through both rows like a book, so every tile is reachable with them alone.
## The bottom row is one shorter and sits centred, so each of its tiles is between two above:
## down goes to the one below and right, up to the one above and right.
func link_focus(top_row: Array[MenuTile], bottom_row: Array[MenuTile]) -> void:
	var reading_order: Array[MenuTile] = top_row + bottom_row
	for tile_index in reading_order.size():
		var tile: MenuTile = reading_order[tile_index]
		tile.focus_neighbor_left = reading_order[maxi(tile_index - 1, 0)].get_path()
		tile.focus_neighbor_right = reading_order[mini(tile_index + 1, reading_order.size() - 1)].get_path()
	for tile_index in top_row.size():
		top_row[tile_index].focus_neighbor_top = top_row[tile_index].get_path()
		top_row[tile_index].focus_neighbor_bottom = bottom_row[mini(tile_index, bottom_row.size() - 1)].get_path()
	for tile_index in bottom_row.size():
		bottom_row[tile_index].focus_neighbor_bottom = bottom_row[tile_index].get_path()
		bottom_row[tile_index].focus_neighbor_top = top_row[mini(tile_index + 1, top_row.size() - 1)].get_path()


func go_to_place(place_name: String, scene_path: String) -> void:
	remember_choice("play_menu", place_name)
	SceneManager.go_to(scene_path)


## One player or two, chosen once here and kept in every place. Picking two
## asks each person to press A on their own pad; picking it again goes back to one.
func make_players_tile() -> MenuTile:
	var word: String = "2 Players" if PlayerSession.is_two_player() else "1 Player"
	var tile: MenuTile = make_tile(word, "players", PaintColours.PURPLE, PLACE_TILE_SIZE)
	tile.chosen.connect(toggle_players)
	return tile


func toggle_players() -> void:
	if PlayerSession.is_two_player():
		PlayerSession.choose_one_player()
		SceneManager.go_to("res://ui/play_menu.tscn")
	else:
		SceneManager.go_to("res://ui/join_screen.tscn")
