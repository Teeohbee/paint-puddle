class_name MeadowTask
extends RefCounted
## One task card: what it says, and how it reacts to things happening in the
## meadow. handle() returns "progress", "wrong", "done" or "ignored". Tasks
## come from data/tasks.json, which can be edited without touching code.

const TYPES: Array[String] = ["make", "spell", "collect", "sum", "visit", "rainbow"]
const MOST_STONES: int = 14

var type: String = ""
var text: String = ""
var paint: String = ""
var word: String = ""
var count: int = 0
var question: String = ""
var answer: int = 0
var choices: Array[int] = []
var target: String = ""

var letters_done: int = 0
var collected: int = 0


## Returns null (and warns) for a task that's missing something or makes no sense.
static func from_dictionary(details: Dictionary) -> MeadowTask:
	var task: MeadowTask = MeadowTask.new()
	task.type = str(details.get("type", ""))
	task.text = str(details.get("text", ""))
	task.paint = str(details.get("paint", ""))
	task.word = str(details.get("word", "")).to_upper()
	task.count = int(details.get("count", 0))
	task.question = str(details.get("question", ""))
	task.answer = int(details.get("answer", 0))
	for choice in details.get("choices", []):
		task.choices.append(int(choice))
	task.target = str(details.get("target", ""))
	var problem: String = task.problem()
	if problem != "":
		push_warning("Skipping task %s: %s" % [JSON.stringify(details), problem])
		return null
	return task


func problem() -> String:
	if not TYPES.has(type):
		return "unknown type"
	if text == "":
		return "no text"
	match type:
		"make", "collect":
			if not PaintMixing.COLOURS.has(paint) or paint == "clean":
				return "unknown paint"
			if type == "collect" and (count < 1 or count > MOST_STONES):
				return "count must be 1 to %d" % MOST_STONES
		"spell":
			if word == "" or word.length() > MOST_STONES:
				return "word must be 1 to %d letters" % MOST_STONES
		"sum":
			if not choices.has(answer):
				return "the answer must be one of the choices"
		"visit":
			if target != "fountain" and not target.begins_with("puddle:"):
				return "target must be fountain or puddle:<colour>"
	return ""


static func load_list(path: String) -> Array[MeadowTask]:
	var tasks: Array[MeadowTask] = []
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Array:
		push_warning("Couldn't read the task list %s" % path)
		return tasks
	for details in parser.data:
		if details is Dictionary:
			var task: MeadowTask = from_dictionary(details)
			if task != null:
				tasks.append(task)
	return tasks


## What to write on the stones this task puts in the grass.
func stone_values() -> Array[String]:
	var values: Array[String] = []
	if type == "spell":
		for letter in word:
			values.append(letter)
	elif type == "sum":
		for choice in choices:
			values.append(str(choice))
	return values


func handle(event: Dictionary) -> String:
	match type:
		"make":
			if event.kind == "paint_changed" and event.paint == paint:
				return "done"
		"spell":
			if event.kind == "stone":
				if event.value != word[letters_done]:
					return "wrong"
				letters_done += 1
				return "done" if letters_done == word.length() else "progress"
		"collect":
			if event.kind == "drop":
				if event.paint != paint:
					return "wrong"
				collected += 1
				return "done" if collected == count else "progress"
		"sum":
			if event.kind == "stone":
				return "done" if event.value == str(answer) else "wrong"
		"visit":
			if event.kind == "visited" and event.target == target:
				return "done"
		"rainbow":
			if event.kind == "rainbow_finished":
				return "done"
	return "ignored"
