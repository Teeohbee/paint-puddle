extends MenuScreen
## Where shall we play? The Meadow, or the Hills once they're ready.


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Where shall we play?", 150)
	var row: HBoxContainer = make_tile_row(360)
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(240, 240))
	var meadow: MenuTile = make_tile("Meadow", "meadow", PaintColours.RED, Vector2(360, 360))
	var hills: MenuTile = make_tile("Hills", "hills", PaintColours.BLUE, Vector2(360, 360))
	for tile in [back, meadow, hills]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/title_screen.tscn"))
	meadow.chosen.connect(func(): SceneManager.go_to("res://meadow/meadow.tscn"))
	hills.chosen.connect(func(): SceneManager.go_to("res://ui/hills_menu.tscn"))
	first_focus = meadow
	meadow.grab_focus_quietly.call_deferred()
