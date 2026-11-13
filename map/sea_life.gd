class_name SeaLife
extends Node2D
## Everything alive on the world map's sea: twelve boats always sailing their
## lanes, and every 20 to 40 seconds the whale or the dolphins (taking turns)
## coming up for a few seconds, one at a time, somewhere away from the pin.
## Nothing here can be pointed at or picked; it only sits under the land.

const SHORTEST_WAIT: float = 20.0
const LONGEST_WAIT: float = 40.0
const SLOWEST_BOAT: float = 12.0
const FASTEST_BOAT: float = 18.0
## A creature never comes up this close to the pin or the hint arrow.
const KEEP_AWAY: float = 250.0
## When every spot is too near the pin, look again this soon.
const SECONDS_TO_LOOK_AGAIN: float = 2.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Returns the points (the pin, the hint arrow) a creature mustn't come up near.
var avoid_points: Callable = func() -> Array: return []
## Returns true while nothing new should come up (say, mid-zoom).
var is_held: Callable = func() -> bool: return false
var boats: Array[SeaBoat] = []
var creature: SeaCreature = null
var next_kind: SeaCreature.Kind = SeaCreature.Kind.WHALE
var seconds_to_next: float = 0.0


func _init() -> void:
	rng.randomize()


func _ready() -> void:
	for lane in SeaLifeData.LANES:
		var heading: float = 1.0 if rng.randf() < 0.5 else -1.0
		var boat: SeaBoat = SeaBoat.make(lane, rng.randf_range(SLOWEST_BOAT, FASTEST_BOAT), rng.randf(), heading, rng.randf() * TAU)
		add_child(boat)
		boats.append(boat)
	seconds_to_next = rng.randf_range(SHORTEST_WAIT, LONGEST_WAIT)


func _process(delta: float) -> void:
	if creature != null or is_held.call():
		return
	seconds_to_next -= delta
	if seconds_to_next > 0.0:
		return
	var spots: Array[Vector2] = open_spots()
	if spots.is_empty():
		seconds_to_next = SECONDS_TO_LOOK_AGAIN
		return
	bring_up(next_kind, spots[rng.randi() % spots.size()])


## The spots far enough from everything in avoid_points.
func open_spots() -> Array[Vector2]:
	var avoid: Array = avoid_points.call()
	var open: Array[Vector2] = []
	for spot in SeaLifeData.SPOTS:
		var is_clear: bool = true
		for point in avoid:
			if spot.distance_to(point) < KEEP_AWAY:
				is_clear = false
		if is_clear:
			open.append(spot)
	return open


func bring_up(kind: SeaCreature.Kind, spot: Vector2) -> void:
	creature = SeaCreature.make(kind, spot)
	add_child(creature)
	creature.finished.connect(creature_gone)
	creature.play()
	next_kind = SeaCreature.Kind.DOLPHINS if kind == SeaCreature.Kind.WHALE else SeaCreature.Kind.WHALE


func creature_gone() -> void:
	creature = null
	seconds_to_next = rng.randf_range(SHORTEST_WAIT, LONGEST_WAIT)
