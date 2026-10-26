extends MenuScreen
## The title: a live meadow, the rainbow logo with a blob hopping along it,
## and three tiles - Play, Options, Quit.


func _ready() -> void:
	add_child(MenuBackdrop.new())
	var logo: RainbowLogo = RainbowLogo.new()
	logo.position = Vector2(960, 330)
	add_child(logo)
	add_child(LogoHopper.new(logo))

	var row: HBoxContainer = make_tile_row(560)
	var play: MenuTile = make_tile("Play", "play", PaintColours.ORANGE, Vector2(360, 360))
	var options: MenuTile = make_tile("Options", "options", PaintColours.BLUE)
	var quit: MenuTile = make_tile("Quit", "quit", PaintColours.PURPLE)
	for tile in [options, play, quit]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	play.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	options.chosen.connect(func(): SceneManager.go_to("res://ui/options_screen.tscn"))
	quit.chosen.connect(quit_game)
	first_focus = play
	play.grab_focus_quietly.call_deferred()


func quit_game() -> void:
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
