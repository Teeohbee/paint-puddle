extends GameSuite
# When a splat can hit: not as it leaves the thrower's paws, so a friend right beside them is safe, but
# from about a third of the way on, so someone who steps into its path is splatted.

var party: Node
var one: PaintPlayer
var two: PaintPlayer

func before_test() -> void:
	super()
	PlayerSession.choose_two_players(0, 1)
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	party = get_tree().current_scene
	# The pals and word characters wander at random; park them out of the way
	for pal in party.pals + party.things:
		pal.set_process(false)
		pal.position = Vector2(1850, 60)
	one = party.players[0]
	two = party.players[1]
	one.paint_bits = PaintMixing.bits_of("blue", "paint")
	one.blob.change_paint("blue")
	two.paint_bits = PaintMixing.bits_of("red", "paint")
	two.blob.change_paint("red")
	one.blob.position = Vector2(400, 400)
	one.blob.look.look_direction = Vector2.RIGHT

# Thrown at nobody, so it flies its full 420px to (820, 400); then player two steps in 190px along
func test_someone_stepping_into_the_path_part_way_along_is_hit() -> void:
	two.blob.position = Vector2(400, 900)
	var ball: Node2D = party.throw_splat(one)
	assert_vector(ball.landing_position).override_failure_message("the throw shouldn't be aimed at anyone") \
		.is_equal_approx(Vector2(820, 400), Vector2.ONE)
	two.blob.position = Vector2(590, 400)
	await frames(40)
	check(two.blob.paint_name == "purple", "a splat 45%% of the way along should hit: %s" % two.blob.paint_name)

func test_someone_right_beside_the_thrower_isnt_hit_as_it_leaves() -> void:
	two.blob.position = Vector2(400, 900)
	party.throw_splat(one)
	two.blob.position = Vector2(430, 400)
	await frames(40)
	check(two.blob.paint_name == "red", "a splat leaving the thrower shouldn't hit someone beside them: %s" % two.blob.paint_name)
