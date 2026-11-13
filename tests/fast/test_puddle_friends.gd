extends GameSuite
# The first time a colour is made, a puddle friend says hello and joins the
# book. Names use the friendlier colour names; recipes come from the bits.

func friends_in(layer):
	var friends = []
	for child in layer.get_children():
		if child is PuddleFriend:
			friends.append(child)
	return friends

func dip(scene, puddle):
	scene.blob.position = Vector2(960, 480)
	await get_tree().physics_frame
	await get_tree().physics_frame
	scene.blob.position = puddle.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

func test_puddle_friends() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var Mixing = load("res://core/paint_mixing.gd")

	# Names and recipes
	check(Mixing.word_for("dark blue") == "Deep blue" and Mixing.friend_name_for("dark blue") == "Deep Blue", "dark blue is called deep blue")
	check(Mixing.friend_name_for("lemon") == "Pale Yellow", "lemon is called pale yellow")
	check(Mixing.friend_name_for("dark red") == "Dark Red", "dark red keeps its name")
	check(Mixing.friend_name_for("dark purple") == "Plum" and Mixing.friend_name_for("dark magenta") == "Berry", "plum and berry")
	check(Mixing.friend_name_for("mint") == "Mint", "mint stays mint")
	var friends = Mixing.all_friend_paints()
	check(friends.size() == 30 and not friends.has("clean"), "30 friends, no clean: %d" % friends.size())
	check(friends[0] == "red" and friends.has("light cyan"), "paint colours first, then the printer's own")
	check(Mixing.recipe_for("dark purple") == ["red", "blue", "black"], "plum is red + blue + black")
	check(Mixing.recipe_for("light cyan") == ["cyan", "white"], "ice blue is cyan + white")
	check(Mixing.recipe_for("grey") == ["white", "black"], "grey is white + black")
	check(Mixing.recipe_for("red") == ["red"], "red is just red")
	var every_friend_drawable = true
	for paint_name in friends:
		if Mixing.recipe_for(paint_name).is_empty() or not Mixing.COLOURS.has(paint_name):
			every_friend_drawable = false
	check(every_friend_drawable, "every friend has a colour and a recipe")
	var book = load("res://ui/book.gd")
	check(book.recipe_text("dark purple") == "Red + blue + black", "the book's recipe reads well: " + book.recipe_text("dark purple"))
	check(book.recipe_text("lemon") == "Yellow + white", "lemon's recipe: " + book.recipe_text("lemon"))

	# In the meadow
	settings.record_progress("next_task_index", 3)
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await get_tree().create_timer(0.5).timeout
	var meadow = get_tree().current_scene
	await dip(meadow, meadow.puddles["red"])
	var said_hello = friends_in(meadow.effects_layer)
	check(said_hello.size() == 1 and said_hello[0].paint_name == "red", "the first red dip says hello")
	check(said_hello[0].first_line == "Hello! I'm Red." and said_hello[0].second_line == "Mix me with other colours!", "red: " + said_hello[0].second_line)
	check(settings.has_found("colours_found", "red"), "red is in the book")
	await dip(meadow, meadow.puddles["yellow"])
	said_hello = friends_in(meadow.effects_layer).filter(func(friend): return not friend.is_leaving)
	check(said_hello.size() == 1 and said_hello[0].paint_name == "orange", "red then yellow: orange says hello")
	check(said_hello[0].second_line == "Red and yellow made me.", "orange: " + said_hello[0].second_line)
	check(friends_in(meadow.effects_layer).any(func(friend): return friend.paint_name == "red" and friend.is_leaving), "red hurries off so only one talks")
	await get_tree().create_timer(6.0).timeout
	check(friends_in(meadow.effects_layer).is_empty(), "friends hop away to the book")
	await dip(meadow, meadow.fountain)
	await dip(meadow, meadow.puddles["red"])
	check(friends_in(meadow.effects_layer).is_empty(), "red again: no second hello")

	# In Paint mode
	get_tree().change_scene_to_file("res://paint/paint_studio.tscn")
	await get_tree().create_timer(0.5).timeout
	var studio = get_tree().current_scene
	await dip(studio, studio.puddles["white"])
	said_hello = friends_in(studio.effects_layer)
	check(said_hello.size() == 1 and said_hello[0].second_line == "Dip in me to make colours lighter!", "white explains itself in Paint")
	await dip(studio, studio.puddles["red"])
	said_hello = friends_in(studio.effects_layer).filter(func(friend): return not friend.is_leaving)
	check(said_hello.size() == 1 and said_hello[0].paint_name == "pink" and said_hello[0].second_line == "White and red made me.", "white then red: pink")

