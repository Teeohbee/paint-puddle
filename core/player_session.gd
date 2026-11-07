extends Node
## Who is playing, chosen up front on the Play menu and kept across every mode.
## One player is the default and needs nothing: any pad or the keyboard works.
## Two players means two explicit pads, in the order they pressed A.

## Tells the modes to point their blobs at the pads again.
signal devices_changed

var player_devices: Array[int] = []
## Slots (0 or 1) whose pad has gone and is waiting for an A press on a new one.
var missing_slots: Array[int] = []


func _ready() -> void:
	Input.joy_connection_changed.connect(on_joy_connection_changed)


## Autoloads hear this before any scene does, so the pause menu always finds
## the missing slot already noted.
func on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected:
		report_pad_lost(device)


## False for a pad whose slot is waiting for a replacement. Menus lock to one
## pad, but never to one that has gone.
func is_pad_usable(device: int) -> bool:
	var slot: int = player_devices.find(device)
	return slot < 0 or not missing_slots.has(slot)


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
	missing_slots = []
	return true


func choose_one_player() -> void:
	player_devices = []
	missing_slots = []


## A pad was unplugged or went to sleep. Returns the slot it belonged to and
## starts waiting for a replacement, or -1 when it was nobody's.
func report_pad_lost(device: int) -> int:
	var slot: int = player_devices.find(device)
	if slot < 0 or missing_slots.has(slot):
		return -1
	missing_slots.append(slot)
	missing_slots.sort()
	return slot


func has_missing_pad() -> bool:
	return not missing_slots.is_empty()


## A on a pad nobody else is using (the same id coming back is fine) takes the first waiting slot. Reconnected pads
## often come back under a new id, which is why this waits for a press rather
## than trusting the old number.
func rebind(device: int) -> bool:
	if missing_slots.is_empty() or device < 0:
		return false
	for slot in player_devices.size():
		if not missing_slots.has(slot) and player_devices[slot] == device:
			return false
	var slot: int = missing_slots.pop_front()
	player_devices[slot] = device
	devices_changed.emit()
	return true
