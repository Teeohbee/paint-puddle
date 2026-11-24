extends GameSuite
# "Paint the rainbow in order": a pot out of turn wobbles and stays empty, so the stripes go on red first.
# Other rainbow cards take the pots in any order.

var meadow

func open_meadow_on(card: Dictionary) -> void:
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await frames(4)
	meadow = get_tree().current_scene
	meadow.task_runner.current_task = MeadowTask.from_dictionary(card)

func pour(paint_name: String) -> void:
	meadow.blob.paint_name = paint_name
	meadow.on_pot_entered(meadow.rainbow.pot_for(paint_name))

func test_a_pot_out_of_turn_stays_empty() -> void:
	await open_meadow_on({"type": "rainbow", "in_order": true, "text": "Paint it in order"})
	pour("orange")
	check(not meadow.rainbow.pot_for("orange").is_filled, "orange before red stays empty")
	pour("red")
	pour("orange")
	check(meadow.rainbow.pot_for("red").is_filled and meadow.rainbow.pot_for("orange").is_filled, "red then orange both fill")
	pour("blue")
	check(not meadow.rainbow.pot_for("blue").is_filled, "skipping yellow and green isn't allowed")

func test_a_stripe_painted_before_the_card_is_skipped_over() -> void:
	await open_meadow_on({"type": "spell", "word": "RED", "text": "Spell RED."})
	pour("red")
	pour("yellow")
	meadow.task_runner.current_task = MeadowTask.from_dictionary({"type": "rainbow", "in_order": true, "text": "Paint it in order"})
	pour("orange")
	check(meadow.rainbow.pot_for("orange").is_filled, "orange is next when red and yellow are done")
	pour("green")
	check(meadow.rainbow.pot_for("green").is_filled, "then green")

func test_an_ordinary_rainbow_takes_any_order() -> void:
	await open_meadow_on({"type": "rainbow", "text": "Paint the whole rainbow!"})
	pour("purple")
	check(meadow.rainbow.pot_for("purple").is_filled, "purple first is fine")
