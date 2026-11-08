extends Node
## Who is playing, chosen up front on the Play menu and kept across every mode.
## One player is the default and needs nothing: any pad or the keyboard works.
## Two players means two explicit pads, in the order they pressed A.

var player_devices: Array[int] = []


func is_two_player() -> bool:
	return player_devices.size() == 2


## The pad for a slot (0 or 1), or -1 when nothing is fixed for it.
func device_of(slot: int) -> int:
	if slot < player_devices.size():
		return player_devices[slot]
	return -1


## Returns false and changes nothing unless these are two different real pads.
func choose_two_players(first_device: int, second_device: int) -> bool:
	if first_device < 0 or second_device < 0 or first_device == second_device:
		return false
	player_devices = [first_device, second_device]
	return true


func choose_one_player() -> void:
	player_devices = []
