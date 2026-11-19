class_name ClockCard
extends RefCounted
## One task in a Clock mode deck: read the time the clock shows, or set the
## hands to a time. Saved as one whole number so the deck fits the save the
## same way the Meadow and Map decks do.

## True for a read task (pick the time the clock shows), false for a set
## task (wind the hands to the time).
var is_read: bool
var minutes_of_the_day: int


func _init(card_is_read: bool, card_minutes_of_the_day: int) -> void:
	is_read = card_is_read
	minutes_of_the_day = card_minutes_of_the_day


## The time doubled, plus one for a read card.
func saved_number() -> int:
	var read_flag: int = 1 if is_read else 0
	return minutes_of_the_day * 2 + read_flag


@warning_ignore("integer_division")
static func from_saved_number(saved: int) -> ClockCard:
	return ClockCard.new(saved % 2 == 1, saved / 2)
