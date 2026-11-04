extends MenuScreen
## Where shall we play? The Meadow, the Hills or Paint - or look at the book.


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Where shall we play?", 150)
	var row: HBoxContainer = make_tile_row(380, 50)
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(220, 220))
	var meadow: MenuTile = make_tile("Meadow", "meadow", PaintColours.RED, Vector2(320, 320))
	var hills: MenuTile = make_tile("Hills", "hills", PaintColours.BLUE, Vector2(320, 320))
	var paint: MenuTile = make_tile("Paint", "paint", PaintColours.GREEN, Vector2(320, 320))
	var book: MenuTile = make_tile("Book", "book", PaintColours.ORANGE, Vector2(320, 320))
	for tile in [back, meadow, hills, paint, book]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/title_screen.tscn"))
	meadow.chosen.connect(func(): SceneManager.go_to("res://meadow/meadow.tscn"))
	hills.chosen.connect(func(): SceneManager.go_to("res://ui/hills_menu.tscn"))
	paint.chosen.connect(func(): SceneManager.go_to("res://ui/paint_menu.tscn"))
	book.chosen.connect(func(): SceneManager.go_to("res://ui/book.tscn"))
	first_focus = meadow
	meadow.grab_focus_quietly.call_deferred()
