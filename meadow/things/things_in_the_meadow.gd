class_name ThingsInTheMeadow
extends Node2D
## Everything spelled into life this visit, hopping about. The meadow starts
## empty each time, and never holds more than MOST_AT_ONCE: when one more
## arrives, the one that's been here longest waves goodbye and hops off.
## Sorted by depth with the blob and bushes, so whoever is nearer is drawn
## in front. Things stop only on clear grass and never walk through the
## rainbow, puddles, fountain or bushes, nor near a stone or number stack, so
## they never hide anything the blob needs.

const MOST_AT_ONCE: int = 6
## How near a thing may come to a stone or number stack.
const CLEAR_DISTANCE_FROM_STONES: float = 110.0
## How finely a path is checked for places to keep clear.
const PATH_CHECK_STEP: float = 20.0
## Places things shouldn't stop on or walk through: the rainbow, puddles,
## fountain, bushes.
var places_to_keep_clear: Array[Dictionary] = []
## The meadow's layer of letter stones and number stacks, which come and go.
var stones_to_keep_clear_of: Node2D


func _init() -> void:
	y_sort_enabled = true


func bring_to_life(thing_name: String, at: Vector2) -> SpelledThing:
	var staying: Array[SpelledThing] = things_staying()
	if staying.size() >= MOST_AT_ONCE:
		staying[0].wave_goodbye()
	var thing: SpelledThing = SpelledThing.new()
	thing.thing_name = thing_name
	thing.position = at
	thing.is_good_spot = is_good_spot
	thing.is_clear_path = is_clear_path
	add_child(thing)
	thing.pop_in()
	return thing


## Oldest first.
func things_staying() -> Array[SpelledThing]:
	var staying: Array[SpelledThing] = []
	for child in get_children():
		if child is SpelledThing and not child.is_leaving:
			staying.append(child)
	return staying


func keep_clear_of(centre: Vector2, radius: float) -> void:
	places_to_keep_clear.append({"centre": centre, "radius": radius})


func is_good_spot(spot: Vector2) -> bool:
	for place in all_places_to_keep_clear():
		if spot.distance_to(place.centre) < place.radius:
			return false
	return true


## The fixed places plus every stone and number stack still in the meadow.
func all_places_to_keep_clear() -> Array[Dictionary]:
	var places: Array[Dictionary] = places_to_keep_clear.duplicate()
	if stones_to_keep_clear_of != null:
		for stone in stones_to_keep_clear_of.get_children():
			var is_leaving: bool = stone.get("is_leaving") == true
			if stone is Node2D and not is_leaving:
				places.append({"centre": stone.position, "radius": CLEAR_DISTANCE_FROM_STONES})
	return places


## A straight walk from one spot to another goes through no place to keep
## clear. A place the walk starts inside doesn't count, so a thing that
## finds a stone has appeared under it can still walk away.
func is_clear_path(from: Vector2, to: Vector2) -> bool:
	var steps: int = maxi(1, ceili(from.distance_to(to) / PATH_CHECK_STEP))
	for place in all_places_to_keep_clear():
		if from.distance_to(place.centre) < place.radius:
			continue
		for step in range(1, steps + 1):
			if from.lerp(to, step / float(steps)).distance_to(place.centre) < place.radius:
				return false
	return true


func find_staying(thing_name: String) -> SpelledThing:
	for thing in things_staying():
		if thing.thing_name == thing_name:
			return thing
	return null


## Somewhere clear for a thing to stand, away from the given spot.
func good_spot_away_from(away_from: Vector2) -> Vector2:
	for attempt in 60:
		var spot: Vector2 = Vector2(randf_range(SpelledThing.MEADOW_AREA.position.x, SpelledThing.MEADOW_AREA.end.x),
			randf_range(SpelledThing.MEADOW_AREA.position.y, SpelledThing.MEADOW_AREA.end.y))
		if is_good_spot(spot) and spot.distance_to(away_from) > 250.0:
			return spot
	return Vector2(300, 420)


## The thing for one word becomes the thing for another, on the spot.
func change_thing(from_name: String, to_name: String) -> SpelledThing:
	var old_thing: SpelledThing = find_staying(from_name)
	var at: Vector2 = old_thing.position if old_thing != null else Vector2(300, 420)
	if old_thing != null:
		old_thing.queue_free()
		remove_child(old_thing)
	return bring_to_life(to_name, at)
