extends MenuScreen
## Where shall we play? The Meadow, the Hills, Paint, Splat, the Map or the Clock - or look at the book.
## Starts on whichever was picked last.

const PLACE_TILE_SIZE: Vector2 = Vector2(250, 250)
const GRID_TOP: float = 320.0
const TILE_GAP: int = 40
## Back stands a little apart from the places, like on the Hills levels.
const BACK_GAP: int = 70


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Where shall we play?", 150)
	var back: MenuTile = make_back_tile()
	var meadow: MenuTile = make_tile("Meadow", "meadow", PaintColours.RED, PLACE_TILE_SIZE)
	var hills: MenuTile = make_tile("Hills", "hills", PaintColours.BLUE, PLACE_TILE_SIZE)
	var paint: MenuTile = make_tile("Paint", "paint", PaintColours.GREEN, PLACE_TILE_SIZE)
	# Write has Splat's old place. Splat is archived: its code stays, with no tile.
	var write: MenuTile = make_tile("Write", "text:a", PaintColours.YELLOW, PLACE_TILE_SIZE)
	var map: MenuTile = make_tile("Map", "map", PaintColours.PURPLE, PLACE_TILE_SIZE)
	var clock: MenuTile = make_tile("Clock", "clock", PaintColours.CYAN, PLACE_TILE_SIZE)
	var book: MenuTile = make_tile("Book", "book", PaintColours.ORANGE, PLACE_TILE_SIZE)
	var players: MenuTile = make_players_tile()
	var top_row: Array[MenuTile] = [meadow, hills, paint, write]
	var bottom_row: Array[MenuTile] = [map, clock, book, players]
	# Back on its own on the left, then the places in two rows beside it
	var row: HBoxContainer = make_tile_row(GRID_TOP, BACK_GAP)
	row.get_parent().offset_bottom = GRID_TOP + PLACE_TILE_SIZE.y * 2 + TILE_GAP
	row.add_child(back)
	var grid: VBoxContainer = VBoxContainer.new()
	grid.add_theme_constant_override("separation", TILE_GAP)
	row.add_child(grid)
	for tiles in [top_row, bottom_row]:
		var grid_row: HBoxContainer = HBoxContainer.new()
		grid_row.add_theme_constant_override("separation", TILE_GAP)
		grid.add_child(grid_row)
		for tile in tiles:
			grid_row.add_child(tile)
	link_focus(back, top_row, bottom_row)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/title_screen.tscn"))
	var places: Dictionary = {
		"meadow": [meadow, "res://ui/meadow_difficulty_menu.tscn"],
		"hills": [hills, "res://ui/hills_difficulty_menu.tscn"],
		"paint": [paint, "res://ui/paint_menu.tscn"],
		"write": [write, "res://ui/write_menu.tscn"],
		"map": [map, "res://map/map_mode.tscn"],
		"clock": [clock, "res://ui/clock_menu.tscn"],
		"book": [book, "res://ui/book.tscn"],
	}
	for place_name in places:
		var tile: MenuTile = places[place_name][0]
		var scene_path: String = places[place_name][1]
		tile.chosen.connect(go_to_place.bind(place_name, scene_path))
	# Back on the place played last, so coming out of it is one press from going back in
	# A place that's gone (Splat) lands on Meadow
	var last_place: String = last_choice("play_menu", "meadow")
	first_focus = places[last_place if places.has(last_place) else "meadow"][0]
	first_focus.grab_focus_quietly.call_deferred()


## Up, down, left and right move round the grid and stop at its edges, except
## left off either row, which goes out to Back. Right from Back goes in at Meadow.
func link_focus(back: MenuTile, top_row: Array[MenuTile], bottom_row: Array[MenuTile]) -> void:
	for tiles in [top_row, bottom_row]:
		for column in tiles.size():
			var tile: MenuTile = tiles[column]
			tile.focus_neighbor_left = (back if column == 0 else tiles[column - 1]).get_path()
			tile.focus_neighbor_right = tiles[mini(column + 1, tiles.size() - 1)].get_path()
			tile.focus_neighbor_top = top_row[column].get_path()
			tile.focus_neighbor_bottom = bottom_row[column].get_path()
	back.focus_neighbor_left = back.get_path()
	back.focus_neighbor_right = top_row[0].get_path()
	back.focus_neighbor_top = back.get_path()
	back.focus_neighbor_bottom = back.get_path()


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
