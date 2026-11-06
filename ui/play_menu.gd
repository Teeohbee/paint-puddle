extends MenuScreen
## Where shall we play? The Meadow, the Hills, Paint or Splat - or look at the book.
## Starts on whichever was picked last.

const PLACE_TILE_SIZE: Vector2 = Vector2(270, 270)


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Where shall we play?", 150)
	var row: HBoxContainer = make_tile_row(400, 36)
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(200, 200))
	var meadow: MenuTile = make_tile("Meadow", "meadow", PaintColours.RED, PLACE_TILE_SIZE)
	var hills: MenuTile = make_tile("Hills", "hills", PaintColours.BLUE, PLACE_TILE_SIZE)
	var paint: MenuTile = make_tile("Paint", "paint", PaintColours.GREEN, PLACE_TILE_SIZE)
	var splat: MenuTile = make_tile("Splat", "splat", PaintColours.YELLOW, PLACE_TILE_SIZE)
	var book: MenuTile = make_tile("Book", "book", PaintColours.ORANGE, PLACE_TILE_SIZE)
	for tile in [back, meadow, hills, paint, splat, book]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/title_screen.tscn"))
	var places: Dictionary = {
		"meadow": [meadow, "res://meadow/meadow.tscn"],
		"hills": [hills, "res://ui/hills_menu.tscn"],
		"paint": [paint, "res://ui/paint_menu.tscn"],
		"splat": [splat, "res://paint/splat_party.tscn"],
		"book": [book, "res://ui/book.tscn"],
	}
	for place_name in places:
		var tile: MenuTile = places[place_name][0]
		var scene_path: String = places[place_name][1]
		tile.chosen.connect(go_to_place.bind(place_name, scene_path))
	# Back on the place played last, so coming out of it is one press from going back in
	first_focus = places[last_choice("play_menu", "meadow")][0]
	first_focus.grab_focus_quietly.call_deferred()


func go_to_place(place_name: String, scene_path: String) -> void:
	remember_choice("play_menu", place_name)
	SceneManager.go_to(scene_path)
