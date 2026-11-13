extends HillsSuite
# Every paint pot in every level can be reached, from a standing jump right under it and from a running
# jump well back, and dipping in mixes the paint the level promises.

func test_every_pot_can_be_reached(level_index: int, test_parameters := [
	[0],
	[1],
	[2],
	[3],
	[4],
	[5],
	[6],
	[7],
	[8],
	[9],
	[10],
	[11],
	[12],
	[13],
	[14],
	[15],
	[16],
	[17],
	[18],
	[19],
	[20],
	[21],
	[22],
	[23],
	[24],
	[25],
	[26],
	[27],
	[28],
	[29],
	[30],
	[31],
	[32],
	[33],
	[34],
	[35],
	[36],
	[37],
	[38],
	[39],
]) -> void:
	var level_data: Dictionary = Levels.LEVELS[level_index]
	var pot_paints: Array = Levels.pot_paints(level_index)
	for pot_index in pot_paints.size():
		var expected := PaintMixing.mix(level_data.paint, pot_paints[pot_index])
		for approach in ["standing jump", "running jump"]:
			var level := await open_level(level_index)
			var pots := find_pots(level)
			if pots.size() != pot_paints.size():
				check(false, "%s has %d pots, wanted %d" % [level_data.name, pots.size(), pot_paints.size()])
				return
			var reached := await _jump_for(level, pots[pot_index], approach)
			check(reached and level.blob_paint == expected, "%d %s: a %s reaches the %s pot (%s + %s = %s, got %s)" %
				[level_index + 1, level_data.name, approach, pot_paints[pot_index], level_data.paint, pot_paints[pot_index], expected, level.blob_paint])

# A running jump starts well back and climbs any steps on the way, like a child holding right
func _jump_for(level: Node, pot: Node, approach: String) -> bool:
	var blob: Node = level.blob
	var ground: Node = level.ground
	var start_x: float = pot.anchor.x - (0.0 if approach == "standing jump" else 400.0)
	if ground.height_at(start_x) == INF:
		start_x = pot.anchor.x
	blob.position = Vector2(start_x, ground.height_at(start_x) - blob.BODY_RADIUS - 4)
	blob.velocity = Vector2.ZERO
	for frame in 20:
		await get_tree().physics_frame
	var touched := [false]
	pot.touched.connect(func(_pot): touched[0] = true)
	var waited := 0
	var jumps := 0
	while not touched[0] and waited < 360:
		var to_pot: float = pot.position.x - blob.position.x
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(to_pot) > 12:
			Input.action_press("move_right" if to_pot > 0 else "move_left")
		var ground_ahead: float = ground.height_at(blob.position.x + 110)
		var step_ahead: bool = ground_ahead == INF or ground_ahead < ground.height_at(blob.position.x) - 20
		var near_pot: bool = absf(to_pot) < (130 if approach == "running jump" else 30)
		if blob.is_on_floor() and jumps < 6 and (near_pot or (to_pot > 0 and step_ahead)):
			Input.action_press("act")
			jumps += 1
		elif not blob.is_on_floor() and blob.velocity.y > 0:
			Input.action_release("act")
		await get_tree().physics_frame
		waited += 1
	Input.action_release("act")
	Input.action_release("move_left")
	Input.action_release("move_right")
	await get_tree().create_timer(0.1).timeout
	return touched[0]
