class_name MeadowTask
extends RefCounted
## One task card: what it says, and how it reacts to things happening in the
## meadow. handle() returns "progress", "wrong", "done" or "ignored". Tasks
## come from data/tasks.json, which can be edited without touching code.

const TYPES: Array[String] = ["make", "spell", "collect", "sum", "visit", "rainbow", "change", "join"]
## The biggest number a stack can be.
const BIGGEST_STACK: int = 10
## Wrong letters to put out beside the right one in a change task.
const CHANGE_DECOY_LETTERS: String = "ABDEGHMOPSTU"
## The meadow has 15 free spots and up to 2 can be too near the blob, so 13
## stones and drops is all that's sure to fit.
const MOST_THINGS_IN_THE_GRASS: int = 13
## Wrong-colour drops put out alongside the right ones in a collect task.
const DISTRACTOR_DROP_COUNT: int = 2

var type: String = ""
var text: String = ""
var paint: String = ""
var word: String = ""
var count: int = 0
var question: String = ""
var answer: int = 0
var choices: Array[int] = []
var target: String = ""
## A spell task can bring a thing to life: spell DOG and a dog appears.
var thing: String = ""
## A change task starts from this word and changes one letter: DOG into LOG.
var from_word: String = ""
## A join task: number stacks in the grass to put together into the target.
var stacks: Array[int] = []
var target_number: int = 0

var letters_done: int = 0
var collected: int = 0
## What the task was made from, so a fresh copy can be made to play it again.
var source: Dictionary = {}


## Returns null (and warns) for a task that's missing something or makes no sense.
static func from_dictionary(details: Dictionary) -> MeadowTask:
	var task: MeadowTask = MeadowTask.new()
	task.source = details
	task.type = str(details.get("type", ""))
	task.text = str(details.get("text", ""))
	task.paint = str(details.get("paint", ""))
	task.word = str(details.get("word", "")).to_upper()
	task.count = int(details.get("count", 0))
	task.question = str(details.get("question", ""))
	task.answer = int(details.get("answer", 0))
	for choice in details.get("choices", []):
		task.choices.append(int(choice))
	task.target = str(details.get("target", "")) if details.get("target", "") is String else ""
	task.thing = str(details.get("thing", ""))
	task.from_word = str(details.get("from", "")).to_upper()
	for stack in details.get("stacks", []):
		task.stacks.append(int(stack))
	task.target_number = int(details.get("target", 0)) if details.get("target", 0) is float or details.get("target", 0) is int else 0
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
			if not can_be_made_in_the_meadow(paint):
				return "unknown paint"
			var most_drops: int = MOST_THINGS_IN_THE_GRASS - DISTRACTOR_DROP_COUNT
			if type == "collect" and (count < 1 or count > most_drops):
				return "count must be 1 to %d" % most_drops
		"spell":
			if word == "" or word.length() > MOST_THINGS_IN_THE_GRASS:
				return "word must be 1 to %d letters" % MOST_THINGS_IN_THE_GRASS
			if thing != "" and not ThingDrawings.can_draw(thing):
				return "there's no picture of a %s" % thing
			if thing != "" and thing.to_upper() != word:
				return "the thing must be the word"
		"sum":
			if choices.size() > MOST_THINGS_IN_THE_GRASS:
				return "no more than %d choices" % MOST_THINGS_IN_THE_GRASS
			if not choices.has(answer):
				return "the answer must be one of the choices"
		"change":
			if from_word.length() != word.length() or word == "":
				return "from and word must be the same length"
			if changed_letter_index() == -1:
				return "from and word must differ by exactly one letter"
			if not ThingDrawings.can_draw(from_word.to_lower()) or not ThingDrawings.can_draw(thing) or thing.to_upper() != word:
				return "both words need a picture, and the thing must be the word"
		"join":
			if target_number < 2 or target_number > BIGGEST_STACK:
				return "target must be 2 to %d" % BIGGEST_STACK
			if stacks.size() < 2 or stacks.size() > MOST_THINGS_IN_THE_GRASS:
				return "2 to %d stacks" % MOST_THINGS_IN_THE_GRASS
			for stack in stacks:
				if stack < 1 or stack > BIGGEST_STACK:
					return "stacks must be 1 to %d" % BIGGEST_STACK
				if stack == target_number:
					return "a stack can't already be the target"
			if not some_stacks_make(target_number):
				return "no stacks add up to the target"
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


## The same task with nothing done yet.
func fresh_copy() -> MeadowTask:
	return from_dictionary(source)


## What to write on the stones this task puts in the grass.
func stone_values() -> Array[String]:
	var values: Array[String] = []
	if type == "spell":
		for letter in word:
			values.append(letter)
	elif type == "sum":
		for choice in choices:
			values.append(str(choice))
	elif type == "change":
		var new_letter: String = word[changed_letter_index()]
		var old_letter: String = from_word[changed_letter_index()]
		values.append_array([new_letter, old_letter])
		# The same decoys every time for the same word
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = hash(word)
		while values.size() < 4:
			var decoy: String = CHANGE_DECOY_LETTERS[random.randi_range(0, CHANGE_DECOY_LETTERS.length() - 1)]
			if not values.has(decoy):
				values.append(decoy)
	return values


## True if two or more of the stacks add up to exactly this number.
func some_stacks_make(number: int) -> bool:
	for chosen_mask in range(1, 1 << stacks.size()):
		var total: int = 0
		var chosen_count: int = 0
		for stack_index in stacks.size():
			if chosen_mask & (1 << stack_index):
				total += stacks[stack_index]
				chosen_count += 1
		if chosen_count >= 2 and total == number:
			return true
	return false


## Which letter a change task changes, or -1 if it isn't exactly one.
func changed_letter_index() -> int:
	var changed_index: int = -1
	for letter_index in mini(word.length(), from_word.length()):
		if word[letter_index] != from_word[letter_index]:
			if changed_index != -1:
				return -1
			changed_index = letter_index
	return changed_index


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
		"join":
			if event.kind == "stacks_joined":
				if event.total > target_number:
					return "wrong"
				return "done" if event.total == target_number else "progress"
		"change":
			if event.kind == "stone":
				if event.value != word[changed_letter_index()]:
					return "wrong"
				letters_done = 1
				return "done"
		"visit":
			if event.kind == "visited" and event.target == target:
				return "done"
		"rainbow":
			if event.kind == "rainbow_finished":
				return "done"
	return "ignored"


## The meadow only has red, yellow and blue puddles, so no light or dark paints.
static func can_be_made_in_the_meadow(paint_name: String) -> bool:
	if not PaintMixing.paint_names().has(paint_name) or paint_name == "clean":
		return false
	return PaintMixing.bits_of(paint_name) & PaintMixing.SHADE_BITS == 0
