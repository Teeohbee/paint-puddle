extends MenuScreen
## Easy or Medium, for the Hills or the Meadow. Medium stays locked until Easy
## is done: every Hills level finished, or every Meadow card dealt once.

const DIFFICULTY_TILE_SIZE: Vector2 = Vector2(320, 320)
const MeadowScript = preload("res://meadow/meadow.gd")

## "hills" or "meadow", set in each place's scene.
@export var place: String = "hills"


func _ready() -> void:
	Music.play_track("title")
	add_child(MenuBackdrop.new())
	make_heading("Rainbow Hills" if place == "hills" else "Meadow", 150)
	var row: HBoxContainer = make_tile_row(400, 60)
	var back: MenuTile = make_back_tile()
	var easy: MenuTile = make_tile("Easy", place, PaintColours.GREEN, DIFFICULTY_TILE_SIZE)
	var medium: MenuTile = make_tile("Medium", place, PaintColours.ORANGE, DIFFICULTY_TILE_SIZE)
	medium.is_locked = not is_medium_unlocked()
	for tile in [back, easy, medium]:
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tile)
	back.chosen.connect(func(): SceneManager.go_to("res://ui/play_menu.tscn"))
	easy.chosen.connect(choose_difficulty.bind(HillsLevels.EASY))
	medium.chosen.connect(choose_difficulty.bind(HillsLevels.MEDIUM))
	# Back on the difficulty played last
	var last: String = last_choice(place + "_difficulty", HillsLevels.EASY)
	first_focus = medium if last == HillsLevels.MEDIUM and not medium.is_locked else easy
	first_focus.grab_focus_quietly.call_deferred()


func is_medium_unlocked() -> bool:
	return HillsLevels.is_medium_unlocked() if place == "hills" else TaskRunner.is_medium_unlocked()


func choose_difficulty(difficulty: String) -> void:
	remember_choice(place + "_difficulty", difficulty)
	if place == "hills":
		HillsLevel.difficulty = difficulty
		SceneManager.go_to("res://ui/hills_menu.tscn")
	else:
		MeadowScript.difficulty = difficulty
		SceneManager.go_to("res://meadow/meadow.tscn")
