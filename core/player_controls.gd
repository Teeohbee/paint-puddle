class_name PlayerControls
extends RefCounted
## Builds actions that listen to one pad, so two people can each drive
## their own blob. The project's own move_* and act actions listen to any pad.

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const ACT_ACTION: StringName = &"act"


## Copies the pad events of move_* into new actions named `<prefix>_move_*`
## that only hear `device`, and returns their names in the same left, right,
## up, down order. With `include_keyboard` the keys work too. A negative
## `device` means no pad at all, for someone playing on the keyboard. Safe to
## call again for the same prefix: it starts the actions afresh.
static func make_pad_actions(prefix: String, device: int, include_keyboard: bool) -> Array[StringName]:
	var made: Array[StringName] = []
	for original_action in MOVE_ACTIONS:
		made.append(copy_action_for_pad(original_action, prefix, device, include_keyboard))
	return made


## The same for the act (jump) button: returns `<prefix>_act`.
static func make_pad_act_action(prefix: String, device: int, include_keyboard: bool) -> StringName:
	return copy_action_for_pad(ACT_ACTION, prefix, device, include_keyboard)


static func copy_action_for_pad(original_action: StringName, prefix: String, device: int, include_keyboard: bool) -> StringName:
	var new_action: StringName = StringName(prefix + "_" + original_action)
	if InputMap.has_action(new_action):
		InputMap.erase_action(new_action)
	InputMap.add_action(new_action)
	for event in InputMap.action_get_events(original_action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			if device < 0:
				continue
			var pad_event: InputEvent = event.duplicate()
			pad_event.device = device
			InputMap.action_add_event(new_action, pad_event)
		elif include_keyboard and event is InputEventKey:
			InputMap.action_add_event(new_action, event.duplicate())
	return new_action
