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
var _opening_pending: Array[String] = []
var _period_cards: Array[String] = []
var periods_completed := false

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
		if event.get("kind") == "period_boundary":
			_opening_pending.append(event["id"])
			_period_cards.append(event["id"])
	_shuffle(draw_pile)
	_prioritize_opening_cards()
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

func _prioritize_opening_cards() -> void:
	var ordinary: Array[String] = []
	var opening: Array[String] = []
	for id in draw_pile:
		if id in _opening_pending:
			opening.append(id)
		else:
			ordinary.append(id)
	# The next card is popped from the end. Retain the shuffled order within
	# each batch, including after a discard, until every boundary was drawn once.
	draw_pile.assign(ordinary)
	draw_pile.append_array(opening)

func _draw_card() -> String:
	var index := draw_pile.size() - 1
	while index >= 0 and period_stage_active() and not is_period_card(draw_pile[index]):
		index -= 1
	if index < 0:
		return ""
	var id: String = draw_pile[index]
	draw_pile.remove_at(index)
	_opening_pending.erase(id)
	return id

func is_period_card(id: String) -> bool:
	return id in _period_cards

func period_stage_active() -> bool:
	return phase == "placement" and not periods_completed

func period_count() -> int:
	return _period_cards.size()

func correct_period_count() -> int:
	var count := 0
	for id in _period_cards:
		var slot_id := placed_slot(id)
		if not slot_id.is_empty() and slot_correct(slot_id):
			count += 1
	return count

func _advance_period_stage() -> void:
	if correct_period_count() == period_count():
		periods_completed = true

func period_status(slot_id: String) -> String:
	var id: String = placements.get(slot_id, "")
	if not is_period_card(id):
		return ""
	return "correct" if slot_correct(slot_id) else "wrong"

func drawable_count() -> int:
	if phase != "placement":
		return 0
	if not period_stage_active():
		return draw_pile.size()
	var count := 0
	for id in draw_pile:
		if is_period_card(id):
			count += 1
	return count

func can_draw() -> bool:
	return phase == "placement" and hand.size() < HAND_LIMIT and drawable_count() > 0

func draw_one() -> bool:
	if not can_draw():
		return false
	hand.append(_draw_card())
	return true

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
		_advance_period_stage()
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
	return phase == "placement" and _by_id.has(slot_id) and (card_id in hand or not placed_slot(card_id).is_empty()) and (not period_stage_active() or is_period_card(card_id))

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
	_advance_period_stage()
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

func can_discard(card_id: String) -> bool:
	return phase == "placement" and card_id in hand and drawable_count() > 0

func discard(card_id: String) -> bool:
	if not can_discard(card_id):
		return false
	# Draw the replacement first, so the discarded card cannot immediately return.
	var index := hand.find(card_id)
	hand[index] = _draw_card()
	draw_pile.append(card_id)
	_shuffle(draw_pile)
	_prioritize_opening_cards()
	return true

func return_wrong_period_to_pile(card_id: String) -> bool:
	if phase != "placement" or not is_period_card(card_id):
		return false
	var slot_id := placed_slot(card_id)
	if slot_id.is_empty() or slot_correct(slot_id):
		return false
	placements.erase(slot_id)
	draw_pile.append(card_id)
	_shuffle(draw_pile)
	_prioritize_opening_cards()
	# Leave the recycled card in the pile. It can be drawn explicitly, or by
	# the normal automatic draw after the next placement; never strand a hand.
	return true

func _fill_hand() -> void:
	while draw_one():
		pass

func can_validate() -> bool:
	return phase == "placement" and periods_completed and correct_period_count() == period_count() and placements.size() == events.size() and hand.is_empty() and draw_pile.is_empty()

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
