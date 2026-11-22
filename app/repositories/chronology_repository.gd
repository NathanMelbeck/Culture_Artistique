class_name ChronologyRepository
extends RefCounted

const PATH := "res://content/games/chronology.json"
var periods: Array = []
var events: Array = []
var groups: Array = []

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		var file := FileAccess.open(PATH, FileAccess.READ)
		if file == null:
			return
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Dictionary:
			return
		data = parsed
	periods = data.get("periods", []).duplicate(true)
	events = data.get("events", []).duplicate(true)
	groups = data.get("groups", []).duplicate(true)
	periods.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["order"] < b["order"])

func find_period(id: String) -> Dictionary:
	for period in periods:
		if period["id"] == id:
			return period.duplicate(true)
	return {}

func resolve_periods(anchors: Array) -> Array:
	if anchors.is_empty():
		return []
	var first := periods.size()
	var last := -1
	for id in anchors:
		if find_period(id).is_empty():
			return []
		for index in periods.size():
			if periods[index]["id"] == id:
				first = mini(first, index)
				last = maxi(last, index)
	return periods.slice(first, last + 1).duplicate(true)

func events_for(selection: Array) -> Array:
	var result: Array = []
	for event in events:
		for period in selection:
			# Style boundaries come from the revision sheet. Keep historical event
			# dates intact and include only events entirely within that style.
			if period["id"] in event["periods"] and event["year"] >= period["start"] and event.get("year_end", event["year"]) <= period["end"]:
				result.append(event.duplicate(true))
				break
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["year"] == b["year"]:
			return a["id"] < b["id"]
		return a["year"] < b["year"]
	)
	return result

func boundary_cards_for(selection: Array, include_outer := false) -> Array:
	var result: Array = []
	if selection.is_empty():
		return result
	var first := int(selection[0]["start"])
	var last := int(selection[0]["end"])
	for period in selection:
		first = mini(first, int(period["start"]))
		last = maxi(last, int(period["end"]))
	for period in selection:
		for boundary in ["start", "end"]:
			var year := int(period[boundary])
			# Both outer dates were already found before dealing. Exclude every
			# period marker matching either date, including shared boundaries.
			if not include_outer and year in [first, last]:
				continue
			var beginning: bool = boundary == "start"
			result.append({
				"id": "period-boundary-" + period["id"] + "-" + boundary,
				"kind": "period_boundary",
				"boundary": boundary,
				"periods": [period["id"]],
				"year": year,
				"title": ("Début de la période : " if beginning else "Fin de la période : ") + period["title"],
				"explanation": period["start_note" if beginning else "end_note"],
				"source": {"kind": "revision_sheet", "sheet_id": period["bounds_source"]["sheet_id"], "title": "Fiche de révision — " + period["title"]}
			})
	return result

func cards_for(selection: Array) -> Array:
	var result := events_for(selection)
	result.append_array(boundary_cards_for(selection))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["year"] == b["year"]:
			return a["id"] < b["id"]
		return a["year"] < b["year"]
	)
	return result

static func date_label(year: int, approximate: bool = false) -> String:
	var digits := str(absi(year))
	if digits.length() > 3:
		digits = digits.left(digits.length() - 3) + " " + digits.right(3)
	return ("vers " if approximate else "") + digits + (" av. J.-C." if year < 0 else " ap. J.-C.")

static func event_date(event: Dictionary) -> String:
	if event.has("year_end") and int(event["year_end"]) != int(event["year"]):
		return ("vers " if event.get("approximate", false) else "") + "%s–%s%s" % [absi(int(event["year"])), absi(int(event["year_end"])), " av. J.-C." if event["year"] < 0 else " ap. J.-C."]
	return date_label(int(event["year"]), event.get("approximate", false))

static func same_date(first: Dictionary, second: Dictionary) -> bool:
	return int(first["year"]) == int(second["year"]) and int(first.get("year_end", first["year"])) == int(second.get("year_end", second["year"]))

const RARITIES := {
	"common": ["Commune", Color("#929ba1")], "rare": ["Rare", Color("#419aeb")],
	"epic": ["Épique", Color("#ad73dc")], "legendary": ["Légendaire", Color("#ef973b")]
}

func collection_cards() -> Array:
	var cards := events.duplicate(true)
	cards.append_array(boundary_cards_for(periods, true))
	return cards

# Reserve up to two distinct events for each period. If two periods both need
# a shared card, try moving its current owner to another eligible event.
func reserve_card(period_id: String, candidates: Dictionary, owners: Dictionary, visited: Dictionary) -> bool:
	for id in candidates[period_id]:
		if visited.has(id): continue
		visited[id] = true
		if not owners.has(id) or reserve_card(owners[id], candidates, owners, visited):
			owners[id] = period_id
			return true
	return false

func event_pools(selection: Array) -> Dictionary:
	var pools := {}
	var candidates := {}
	var by_id := {}
	var eligible := {}
	for period in selection:
		pools[period.id] = []
		candidates[period.id] = []
	for card in events_for(selection):
		by_id[card.id] = card
		eligible[card.id] = []
		for period in selection:
			if period.id in card.periods and card.year >= period.start and card.get("year_end", card.year) <= period.end:
				candidates[period.id].append(card.id)
				eligible[card.id].append(period.id)
	var owners := {}
	var ordered_periods := candidates.keys()
	ordered_periods.sort_custom(func(a,b): return candidates[a].size() < candidates[b].size())
	for repetition in 2:
		for id in ordered_periods: reserve_card(id,candidates,owners,{})
	for id in owners:
		pools[owners[id]].append(by_id[id])
	var remaining := by_id.keys().filter(func(id): return not owners.has(id))
	remaining.sort_custom(func(a,b): return eligible[a].size() < eligible[b].size())
	for id in remaining:
		var owner: String = eligible[id][0]
		for candidate in eligible[id]:
			if pools[candidate].size() < pools[owner].size(): owner = candidate
		pools[owner].append(by_id[id])
	return pools

func event_limits(pools: Dictionary) -> Vector2i:
	var limits := Vector2i.ZERO
	for pool in pools.values():
		limits.x += mini(2, pool.size())
		limits.y += pool.size()
	return limits

func build_deck(selection: Array, game_mode: String, requested: int, review: Array = []) -> Array:
	if game_mode == "markers":
		return boundary_cards_for(selection, true)
	var pools := event_pools(selection)
	var limits := event_limits(pools)
	var target := clampi(requested, limits.x, limits.y)
	var active := pools.keys().filter(func(id): return not pools[id].is_empty())
	var average := float(target) / maxi(1, active.size())
	var counts := {}
	var remaining := target
	for id in active:
		counts[id] = mini(pools[id].size(), maxi(2, floori(0.7 * average)))
		remaining -= counts[id]
	# A very sparse period can make the nominal floor infeasible for a small deck.
	while remaining < 0:
		var reducible := active.filter(func(id): return counts[id] > 2)
		if reducible.is_empty(): break
		counts[reducible.pick_random()] -= 1
		remaining += 1
	var allocator := RandomNumberGenerator.new()
	allocator.randomize()
	var ceiling := ceili(1.3 * average)
	while remaining > 0:
		var options := active.filter(func(id): return counts[id] < mini(ceiling, pools[id].size()))
		if options.is_empty():
			var available := active.filter(func(id): return counts[id] < pools[id].size())
			var least: int = counts[available[0]]
			for id in available: least = mini(least, counts[id])
			options = available.filter(func(id): return counts[id] == least)
			counts[options.pick_random()] += 1
		else:
			var weights := PackedFloat32Array()
			for id in options: weights.append(mini(ceiling, pools[id].size()) - counts[id])
			counts[options[allocator.rand_weighted(weights)]] += 1
		remaining -= 1
	var result := []
	var priority := review.duplicate()
	priority.shuffle()
	var included := 0
	for card_id in priority:
		if included >= 2: break
		for id in active:
			if counts[id] == 0: continue
			var index: int = pools[id].find_custom(func(e): return e.id == card_id)
			if index >= 0:
				result.append(pools[id].pop_at(index))
				counts[id] -= 1
				included += 1
				break
	for id in active:
		pools[id].shuffle()
		result.append_array(pools[id].slice(0, counts[id]))
	if game_mode == "classic":
		result.append_array(boundary_cards_for(selection))
	result.sort_custom(func(a,b): return a.year < b.year or (a.year == b.year and a.id < b.id))
	return result

static func accepts_year(card: Dictionary, year: int) -> bool:
	return year != 0 and year >= int(card.get("accepted_from", card.year)) and year <= int(card.get("accepted_to", card.get("year_end", card.year)))
