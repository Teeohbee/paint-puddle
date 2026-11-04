class_name ThingsInTheMeadow
extends Node2D
## Everything spelled into life this visit, hopping about. The meadow starts
## empty each time, and never holds more than MOST_AT_ONCE: when one more
## arrives, the one that's been here longest waves goodbye and hops off.
## Drawn under everything else, so it never hides a stone, pot or puddle.

const MOST_AT_ONCE: int = 6
## Places things shouldn't stop on: the rainbow, puddles, fountain, bushes.
var places_to_keep_clear: Array[Dictionary] = []


func bring_to_life(thing_name: String, at: Vector2) -> SpelledThing:
	var staying: Array[SpelledThing] = things_staying()
	if staying.size() >= MOST_AT_ONCE:
		staying[0].wave_goodbye()
	var thing: SpelledThing = SpelledThing.new()
	thing.thing_name = thing_name
	thing.position = at
	thing.is_good_spot = is_good_spot
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
	for place in places_to_keep_clear:
		if spot.distance_to(place.centre) < place.radius:
			return false
	return true
