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
