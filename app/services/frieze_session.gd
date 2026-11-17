class_name FriezeSession
extends RefCounted

const HAND_LIMIT := 7
var phase := "start"
var periods: Array
var events: Array
var hand: Array[String] = []
var draw_pile: Array[String] = []
var placements: Dictionary = {}
var wrong_choices: Array[int] = []
var boundary_attempts := {"start": 0, "end": 0}
var start_period: Dictionary
var end_period: Dictionary
var _choices: Dictionary = {}
var _by_id: Dictionary = {}
var _random := RandomNumberGenerator.new()

func _init(selection: Array, cards: Array, seed_value: int = -1) -> void:
	periods = selection.duplicate(true)
	events = cards.duplicate(true)
	if seed_value < 0:
		_random.randomize()
	else:
		_random.seed = seed_value
	if periods.is_empty() or events.is_empty():
		phase = "unavailable"
		return
	start_period = periods[0]
	end_period = periods[0]
	for period in periods:
		if period["start"] < start_period["start"]:
			start_period = period
		if period["end"] > end_period["end"]:
			end_period = period
	for event in events:
		_by_id[event["id"]] = event
		draw_pile.append(event["id"])
	_shuffle(draw_pile)
	_choices["start"] = []
	_choices["end"] = []
	for value in start_period["start_choices"]:
		_choices["start"].append(int(value))
	for value in end_period["end_choices"]:
		_choices["end"].append(int(value))
	_shuffle(_choices["start"])
	_shuffle(_choices["end"])

func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := _random.randi_range(0, index)
		var temporary: Variant = values[index]
		values[index] = values[other]
		values[other] = temporary

func boundary_choices() -> Array:
	return _choices.get(phase, []).duplicate()

func answer_boundary(year: int) -> bool:
	if phase not in ["start", "end"] or year not in _choices[phase]:
		return false
	boundary_attempts[phase] += 1
	var expected := int(start_period["start"] if phase == "start" else end_period["end"])
	if year != expected:
		if year not in wrong_choices:
			wrong_choices.append(year)
		return false
	wrong_choices.clear()
	if phase == "start":
		phase = "end"
	else:
		phase = "placement"
		_fill_hand()
	return true

func event(id: String) -> Dictionary:
	return _by_id.get(id, {}).duplicate(true)

func placed_slot(card_id: String) -> String:
	for slot_id in placements:
		if placements[slot_id] == card_id:
			return slot_id
	return ""

func can_place(card_id: String, slot_id: String) -> bool:
	return phase == "placement" and _by_id.has(slot_id) and (card_id in hand or not placed_slot(card_id).is_empty())

func place(card_id: String, slot_id: String) -> bool:
	if not can_place(card_id, slot_id):
		return false
	var from_slot := placed_slot(card_id)
	if from_slot == slot_id:
		return false
	var displaced: String = placements.get(slot_id, "")
	if from_slot.is_empty():
		var index := hand.find(card_id)
		hand.remove_at(index)
		if not displaced.is_empty():
			hand.insert(index, displaced)
	else:
		placements.erase(from_slot)
		if not displaced.is_empty():
			placements[from_slot] = displaced
	placements[slot_id] = card_id
	_fill_hand()
	return true

func return_to_hand(card_id: String) -> bool:
	if phase != "placement" or hand.size() >= HAND_LIMIT:
		return false
	var slot_id := placed_slot(card_id)
	if slot_id.is_empty():
		return false
	placements.erase(slot_id)
	hand.append(card_id)
	return true

func discard(card_id: String) -> bool:
	if phase != "placement" or card_id not in hand or draw_pile.is_empty():
		return false
	# Draw the replacement first, so the discarded card cannot immediately return.
	var index := hand.find(card_id)
	hand[index] = draw_pile.pop_back()
	draw_pile.append(card_id)
	_shuffle(draw_pile)
	return true

func _fill_hand() -> void:
	while hand.size() < HAND_LIMIT and not draw_pile.is_empty():
		hand.append(draw_pile.pop_back())

func can_validate() -> bool:
	return phase == "placement" and placements.size() == events.size() and hand.is_empty() and draw_pile.is_empty()

func validate() -> bool:
	if not can_validate():
		return false
	phase = "result"
	return true

func slot_correct(slot_id: String) -> bool:
	if not placements.has(slot_id):
		return false
	return ChronologyRepository.same_date(event(slot_id), event(placements[slot_id]))

func score() -> int:
	var count := 0
	for slot_id in placements:
		if slot_correct(slot_id):
			count += 1
	return count
