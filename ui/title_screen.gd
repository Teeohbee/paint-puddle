extends MenuScreen
## The title: a live meadow, the rainbow logo with a blob hopping along it,
## and three tiles - Play, Options, Quit. On a birthday (see Birthday) the
## blobs wear party hats, balloons float up and a message runs along the bottom.

const BIRTHDAY_HAT_COLOURS: Array[Color] = [PaintColours.MAGENTA, PaintColours.CYAN, PaintColours.ORANGE, PaintColours.PURPLE]

## The confetti and chime happen once a launch, not every time back at the title.
static var has_cheered_the_birthday: bool = false

var birthday_message: RainbowLogo


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	var birthday: Birthday = Birthday.load_from_disk()
	var party: Birthday.Party = birthday.party_on(Birthday.today()) if birthday != null else Birthday.Party.NONE
	if party != Birthday.Party.NONE:
		add_child(BirthdayParty.new(party, birthday.age_on(Birthday.today())))
	var logo: RainbowLogo = RainbowLogo.new()
	logo.position = Vector2(960, 330)
	add_child(logo)
	add_child(LogoHopper.new(logo))

	# On a birthday the tiles move up a little to leave room for the message underneath
	var row: HBoxContainer = make_tile_row(560 if party == Birthday.Party.NONE else 515)
	var play: MenuTile = make_tile("Play", "play", PaintColours.ORANGE, Vector2(360, 360))
	var options: MenuTile = make_tile("Options", "options", PaintColours.BLUE)
	var quit: MenuTile = make_tile("Quit", "quit", PaintColours.PURPLE)
	for tile in [options, play, quit]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	play.chosen.connect(func():
		remember_choice("title", "play")
		SceneManager.go_to("res://ui/play_menu.tscn"))
	options.chosen.connect(func():
		remember_choice("title", "options")
		SceneManager.go_to("res://ui/options_screen.tscn"))
	quit.chosen.connect(quit_game)
	# Back from Options lands on Options; otherwise Play
	first_focus = options if last_choice("title", "play") == "options" else play
	first_focus.grab_focus_quietly.call_deferred()
	if party != Birthday.Party.NONE:
		celebrate(birthday, party)


func celebrate(birthday: Birthday, party: Birthday.Party) -> void:
	var hat_index: int = 0
	for blob_look in find_children("*", "PaintBlobLook", true, false):
		blob_look.party_hat_colour = BIRTHDAY_HAT_COLOURS[hat_index % BIRTHDAY_HAT_COLOURS.size()]
		hat_index += 1
	birthday_message = RainbowLogo.new()
	birthday_message.text = birthday.message_on(Birthday.today())
	birthday_message.font_size = 76 if party == Birthday.Party.BIRTHDAY else 64
	birthday_message.position = Vector2(960, 1035)
	add_child(birthday_message)
	if party == Birthday.Party.BIRTHDAY and not has_cheered_the_birthday:
		has_cheered_the_birthday = true
		add_child(Confetti.new())
		Sound.play("chime")


func quit_game() -> void:
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
