extends MenuScreen
## Which paints? Paint colours (red, yellow, blue) or printer colours (cyan,
## magenta, yellow), which mix their own way.


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Which colours?", 150)
	var row: HBoxContainer = make_tile_row(360)
	var back: MenuTile = make_tile("Back", "back", PaintColours.PURPLE, Vector2(240, 240))
	var paint_colours: MenuTile = make_tile("Paint colours", "colour_set:paint", PaintColours.GREEN, Vector2(460, 360))
	var printer_colours: MenuTile = make_tile("Printer colours", "colour_set:printer", PaintColours.BLUE, Vector2(460, 360))
	for tile in [back, paint_colours, printer_colours]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	paint_colours.chosen.connect(start_painting.bind("paint"))
	printer_colours.chosen.connect(start_painting.bind("printer"))
	first_focus = printer_colours if PaintStudio.colour_set == "printer" else paint_colours
	first_focus.grab_focus_quietly.call_deferred()


func start_painting(colour_set: String) -> void:
	PaintStudio.colour_set = colour_set
	SceneManager.go_to("res://paint/paint_studio.tscn")
