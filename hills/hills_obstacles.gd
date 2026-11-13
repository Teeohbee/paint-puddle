class_name HillsObstacles
extends RefCounted
## Where Medium puts its obstacles. Kept apart from the nodes so it can be
## tested: given the ground and the things already in the level, it returns
## the x of each obstacle. The same level always gets the same answer.
## Obstacles only go on flat ground with a flat run-up behind and room after,
## away from the start, the flag, balloons and pots.

const KEEP_CLEAR_AT_START: float = 700.0
const KEEP_CLEAR_AT_FLAG: float = 500.0
## Flat ground needed on either side of an obstacle: behind it, enough for the
## bump back; ahead of it, enough to land and get going before the next jump.
const FLAT_RUN_UP_BEFORE: float = 200.0
const FLAT_ROOM_AFTER: float = 250.0
const FLAT_TOLERANCE: float = 2.0
const SPACING: float = 700.0
const KEEP_CLEAR_OF_THINGS: float = 110.0
## About one obstacle for every this much level.
const LEVEL_LENGTH_PER_OBSTACLE: float = 1100.0
const SAMPLE_STEP: float = 10.0
const CANDIDATE_STEP: float = 20.0


static func place(ground: HillsGround, level_index: int, things_x: Array[float]) -> Array[float]:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 7919 * (level_index + 1)
	var candidates: Array[float] = []
	var x: float = KEEP_CLEAR_AT_START
	while x <= ground.level_length - KEEP_CLEAR_AT_FLAG:
		if is_good_spot(ground, x, things_x):
			candidates.append(x)
		x += CANDIDATE_STEP
	var wanted: int = int(ground.level_length / LEVEL_LENGTH_PER_OBSTACLE)
	var chosen: Array[float] = []
	while chosen.size() < wanted and not candidates.is_empty():
		var picked: float = candidates.pop_at(random.randi_range(0, candidates.size() - 1))
		var is_far_enough: bool = true
		for other in chosen:
			if absf(other - picked) < SPACING:
				is_far_enough = false
		if is_far_enough:
			chosen.append(picked)
	chosen.sort()
	return chosen


static func is_good_spot(ground: HillsGround, x: float, things_x: Array[float]) -> bool:
	for thing_x in things_x:
		if absf(thing_x - x) < KEEP_CLEAR_OF_THINGS:
			return false
	var here: float = ground.height_at(x)
	if here == INF:
		return false
	var offset: float = -FLAT_RUN_UP_BEFORE
	while offset <= FLAT_ROOM_AFTER:
		var height: float = ground.height_at(x + offset)
		if height == INF or absf(height - here) > FLAT_TOLERANCE:
			return false
		offset += SAMPLE_STEP
	return true
