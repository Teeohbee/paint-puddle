extends GameSuite
# Paint mode: the blob paints a lasting trail in its colour, and the sponge wipes the picture.

func hold(action, seconds):
	Input.action_press(action)
	await get_tree().create_timer(seconds).timeout
	Input.action_release(action)

# Paints a line in a named paint; the paper takes bits.
# Each call is a new pass: the brush first moves away to a far corner, as it
# has to in the game before it can come back over the same spot.
func paint(paper, from, to, paint_name):
	var bits = PaintMixing.bits_of(paint_name, paper.colour_set)
	paper.paint_line(Vector2(1800, 40), Vector2(1800, 40), bits)
	paper.paint_line(from, to, bits)

func test_paint() -> void:
	var canvas_script = load("res://paint/paint_canvas.gd")
	var points = canvas_script.dab_points(Vector2(0, 0), Vector2(100, 0), 6.0)
	check(points.size() >= 16 and points[points.size() - 1] == Vector2(100, 0), "a stroke is filled with dabs right to its end: %d" % points.size())
	var biggest_gap = 0.0
	for index in range(1, points.size()):
		biggest_gap = maxf(biggest_gap, points[index].distance_to(points[index - 1]))
	check(biggest_gap <= 6.0, "with no gaps bigger than the spacing: %.1f" % biggest_gap)
	check(canvas_script.dab_points(Vector2(5, 5), Vector2(5, 5), 6.0).size() == 1, "standing still dabs once")

	# The sponge on its own
	var sponge = load("res://paint/sponge.gd").new()
	var wipes = [0]
	sponge.wiped.connect(func(): wipes[0] += 1)
	sponge.advance(1.0, true)
	check(wipes[0] == 0 and sponge.hold_progress > 0.5, "sitting on the sponge fills its ring: %.2f" % sponge.hold_progress)
	sponge.advance(0.1, false)
	check(sponge.hold_progress == 0.0, "driving off before it's full starts the ring again")
	for step in 20: sponge.advance(0.1, true)
	check(wipes[0] == 1, "sitting long enough wipes the picture once")
	for step in 20: sponge.advance(0.1, true)
	check(wipes[0] == 1, "staying on doesn't keep wiping")
	sponge.advance(0.1, false)
	for step in 20: sponge.advance(0.1, true)
	check(wipes[0] == 2, "leaving and coming back can wipe again")
	sponge.free()

	# Paint mixes on the paper
	var paper = canvas_script.new()
	get_tree().root.add_child(paper)
	paint(paper, Vector2(200, 300), Vector2(600, 300), "blue")
	paint(paper, Vector2(400, 100), Vector2(400, 500), "red")
	check(paper.paint_at(Vector2(400, 300)) == "purple", "red across blue makes purple where they cross: %s" % paper.paint_at(Vector2(400, 300)))
	check(paper.paint_at(Vector2(250, 300)) == "blue", "the blue away from the crossing stays blue")
	check(paper.paint_at(Vector2(400, 150)) == "red", "the red away from the crossing stays red")
	check(paper.paint_at(Vector2(800, 800)) == "clean", "untouched paper is clean")
	paint(paper, Vector2(400, 100), Vector2(400, 200), "red")
	check(paper.paint_at(Vector2(400, 150)) == "red", "red over red is still red")
	paint(paper, Vector2(200, 300), Vector2(600, 300), "yellow")
	check(paper.paint_at(Vector2(250, 300)) == "green" and paper.paint_at(Vector2(400, 300)) == "brown", "yellow over blue is green, over purple is brown")
	paint(paper, Vector2(1900, 1070), Vector2(1950, 1100), "red")
	check(paper.paint_at(Vector2(1915, 1075)) == "red", "painting off the edge of the paper is fine")
	paper.wipe()
	await get_tree().create_timer(0.6).timeout  # the wipe fades out over 0.5s
	paint(paper, Vector2(200, 600), Vector2(600, 600), "blue")
	paint(paper, Vector2(400, 500), Vector2(400, 700), "white")
	check(paper.paint_at(Vector2(400, 600)) == "sky blue", "white across blue makes sky blue: " + paper.paint_at(Vector2(400, 600)))
	check(paper.paint_at(Vector2(400, 520)) == "white", "white on bare paper is white")
	paint(paper, Vector2(300, 520), Vector2(500, 520), "black")
	check(paper.paint_at(Vector2(400, 520)) == "grey", "black across white makes grey")
	paint(paper, Vector2(380, 560), Vector2(420, 640), "black")
	check(paper.paint_at(Vector2(400, 600)) == "blue", "black and white cancel back to blue: " + paper.paint_at(Vector2(400, 600)))
	paint(paper, Vector2(380, 560), Vector2(420, 640), "black")
	check(paper.paint_at(Vector2(400, 600)) == "dark blue", "and a second pass of black darkens it, like a second dip: " + paper.paint_at(Vector2(400, 600)))
	# The paper mixes like the blob, one dip per pass of the brush
	paper.wipe()
	await get_tree().create_timer(0.6).timeout  # the wipe fades out over 0.5s
	paint(paper, Vector2(200, 400), Vector2(600, 400), "red")
	for shade in ["white", "black", "white"]:
		paint(paper, Vector2(400, 300), Vector2(400, 500), shade)
	check(paper.paint_at(Vector2(400, 400)) == "pink", "white, black, white over red is pink, as for the blob: " + paper.paint_at(Vector2(400, 400)))
	paint(paper, Vector2(200, 400), Vector2(600, 400), "black")
	check(paper.paint_at(Vector2(400, 400)) == "red" and paper.paint_at(Vector2(250, 400)) == "dark red", "one long black stroke takes one step, however many dabs overlap: %s, %s" % [paper.paint_at(Vector2(400, 400)), paper.paint_at(Vector2(250, 400))])
	paint(paper, Vector2(200, 700), Vector2(600, 700), "white")
	paint(paper, Vector2(400, 600), Vector2(400, 800), "black")
	paint(paper, Vector2(380, 650), Vector2(420, 750), "white")
	check(paper.paint_at(Vector2(400, 700)) == "white", "grey and white make white, as for the blob: " + paper.paint_at(Vector2(400, 700)))
	paint(paper, Vector2(380, 650), Vector2(420, 750), "black")
	paint(paper, Vector2(380, 650), Vector2(420, 750), "black")
	check(paper.paint_at(Vector2(400, 700)) == "black", "and black twice over that makes black: " + paper.paint_at(Vector2(400, 700)))
	paper.wipe()
	await get_tree().create_timer(0.6).timeout  # the wipe fades out over 0.5s
	paint(paper, Vector2(200, 400), Vector2(600, 400), "red")
	paint(paper, Vector2(400, 300), Vector2(400, 500), "blue")
	paper.clear_paper()
	paint(paper, Vector2(400, 300), Vector2(400, 500), "blue")
	check(paper.paint_at(Vector2(400, 400)) == "blue", "after a wipe the paper takes paint even where the brush sat: " + paper.paint_at(Vector2(400, 400)))
	paper.wipe()
	await get_tree().create_timer(0.6).timeout  # the wipe fades out over 0.5s
	paper.colour_set = "printer"
	paint(paper, Vector2(200, 800), Vector2(600, 800), "cyan")
	paint(paper, Vector2(400, 700), Vector2(400, 900), "magenta")
	check(paper.paint_at(Vector2(400, 800)) == "blue", "printer paper: magenta across cyan makes blue: " + paper.paint_at(Vector2(400, 800)))
	paint(paper, Vector2(300, 780), Vector2(500, 820), "yellow")
	check(paper.paint_at(Vector2(400, 800)) == "black", "and yellow over that makes black")
	paint(paper, Vector2(380, 780), Vector2(420, 820), "cyan")
	check(paper.paint_at(Vector2(400, 800)) == "black", "and more ink keeps it black: " + paper.paint_at(Vector2(400, 800)))
	paper.colour_set = "paint"
	paper.wipe()
	await get_tree().create_timer(0.6).timeout  # the wipe fades out over 0.5s
	check(paper.paint_at(Vector2(400, 300)) == "clean", "wiping cleans the paper")
	paper.queue_free()

	# The real studio
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://paint/paint_studio.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var studio = get_tree().current_scene
	var blob = studio.blob
	var canvas = studio.canvas
	check(blob.paint_name == "clean", "the blob starts clean")
	await hold("move_up", 0.4)
	check(canvas.dabs_painted == 0, "a clean blob paints nothing")

	blob.position = studio.puddles["red"].position
	for frame in 5: await get_tree().physics_frame
	check(blob.paint_name == "red", "the red puddle paints the blob red")
	blob.position = Vector2(960, 500)
	for frame in 5: await get_tree().physics_frame
	await hold("move_right", 0.4)
	check(canvas.dabs_painted > 10, "driving a red blob paints: %d dabs" % canvas.dabs_painted)
	check(canvas.paint_at(blob.position + studio.BRUSH_OFFSET) == "red", "in red")
	blob.position = studio.puddles["blue"].position
	for frame in 5: await get_tree().physics_frame
	check(blob.paint_name == "purple", "blue on red mixes purple, like the meadow")
	check(studio.puddles.has("white") and studio.puddles.has("black"), "the studio has white and black puddles")
	blob.position = studio.puddles["white"].position
	for frame in 5: await get_tree().physics_frame
	check(blob.paint_name == "lilac", "white on purple makes lilac: " + blob.paint_name)
	var puddle_spots = studio.puddles.values().map(func(puddle): return puddle.position)
	var closest = 9999.0
	for first in puddle_spots.size():
		for second in range(first + 1, puddle_spots.size()):
			closest = minf(closest, puddle_spots[first].distance_to(puddle_spots[second]))
		closest = minf(closest, puddle_spots[first].distance_to(studio.FOUNTAIN_POSITION))
		closest = minf(closest, puddle_spots[first].distance_to(studio.SPONGE_POSITION))
	check(closest >= 260.0, "puddles, fountain and sponge have room between them: %d" % closest)

	blob.position = studio.sponge.position
	blob.velocity = Vector2.ZERO
	await get_tree().create_timer(2.2).timeout
	check(canvas.dabs_painted == 0, "sitting on the sponge wipes the picture")

	# The printer sheet
	var studio_script = load("res://paint/paint_studio.gd")
	studio_script.colour_set = "printer"
	get_tree().change_scene_to_file("res://paint/paint_studio.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	studio = get_tree().current_scene
	blob = studio.blob
	check(studio.puddles.keys() == ["cyan", "magenta", "yellow", "white", "black"], "the printer sheet has cyan, magenta, yellow, white and black puddles: %s" % [studio.puddles.keys()])
	blob.position = studio.puddles["cyan"].position
	for frame in 5: await get_tree().physics_frame
	blob.position = Vector2(960, 500)
	for frame in 5: await get_tree().physics_frame
	blob.position = studio.puddles["yellow"].position
	for frame in 5: await get_tree().physics_frame
	check(blob.paint_name == "green", "cyan and yellow make green on the printer sheet: " + blob.paint_name)
	await hold("move_up", 0.4)
	check(studio.canvas.paint_at(blob.position + studio.BRUSH_OFFSET) == "green", "and it paints green")
	# Black made from all three inks stays black, whatever ink comes next
	for ink in ["magenta", "cyan"]:
		blob.position = Vector2(960, 500)
		for frame in 5: await get_tree().physics_frame
		blob.position = studio.puddles[ink].position
		for frame in 5: await get_tree().physics_frame
	check(blob.paint_name == "black", "cyan, yellow, magenta and cyan again is still black: " + blob.paint_name)
	blob.position = Vector2(960, 300)
	for frame in 5: await get_tree().physics_frame
	studio.canvas.clear_paper()
	studio.canvas.paint_line(Vector2(800, 300), Vector2(1100, 300), PaintMixing.bits_of("yellow", "printer"))
	await hold("move_right", 0.3)
	check(studio.canvas.paint_at(blob.position + studio.BRUSH_OFFSET) == "black", "and paints black over yellow paper: " + studio.canvas.paint_at(blob.position + studio.BRUSH_OFFSET))
	studio_script.colour_set = "paint"
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://paint_check.json"))
