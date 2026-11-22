class_name ProgressRepository
extends RefCounted

const DEFAULT_PATH := "user://learning_progress.json"
const GOLD_THRESHOLD := 7
var _path: String
var _data: Dictionary = {"version": 1, "courses": {}}

func _init(path: String = DEFAULT_PATH) -> void:
	_path = path
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("courses") is Dictionary:
		_data = parsed

func get_course(id: String) -> Dictionary:
	var value: Variant = _data["courses"].get(id, {})
	if not value is Dictionary:
		return {}
	var result: Dictionary = value.duplicate(true)
	# Reading status is no longer exposed. Preserve legacy fields on disk only.
	result.erase("read")
	for key in ["quiz_best", "quiz_total"]:
		if result.has(key):
			if result[key] is int or result[key] is float:
				result[key] = maxi(0, int(result[key]))
			else:
				result.erase(key)
	return result

func save_quiz(course_id: String, score: int, total: int) -> void:
	var course := get_course(course_id)
	course["quiz_best"] = maxi(int(course.get("quiz_best", 0)), score)
	course["quiz_total"] = total
	var stored: Dictionary = _data["courses"].get(course_id, {}) if _data["courses"].get(course_id, {}) is Dictionary else {}
	stored.merge(course, true)
	_data["courses"][course_id] = stored
	_save()

func _save() -> void:
	if _path.is_empty():
		return
	var temporary := _path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("La progression ne peut pas être enregistrée.")
		return
	file.store_string(JSON.stringify(_data, "  "))
	file.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(_path))
	if error != OK:
		push_warning("La progression n'a pas pu être remplacée : %s" % error_string(error))

func collectible(id: String) -> Dictionary:
	var collection: Variant = _data.get("collection", {})
	var card: Variant = collection.get(id, {}) if collection is Dictionary else {}
	if not card is Dictionary: card = {}
	var normal: bool = card.get("normal") == true
	var points: Variant = card.get("marks", card.get("wins", 0))
	var marks := int(points) if points is int or points is float else 0
	if not card.has("marks") and marks >= 3:
		# Preserve an already awarded legacy gold and supply its base card.
		normal = true
		marks = GOLD_THRESHOLD
	return {"normal":normal, "review":card.get("review") == true,
		"marks":clampi(marks,0,GOLD_THRESHOLD) if normal else 0}

func owned_normals() -> Dictionary:
	var owned := {}
	var collection: Variant = _data.get("collection", {})
	if collection is Dictionary:
		for id in collection:
			if collectible(id).normal: owned[id] = true
	return owned

func _store_card(id: String, card: Dictionary) -> void:
	if not _data.get("collection") is Dictionary: _data.collection = {}
	_data.collection[id] = card

func review_ids() -> Array:
	var collection: Variant = _data.get("collection", {})
	if not collection is Dictionary: return []
	return collection.keys().filter(func(id): return collectible(id).review)

func toggle_review(id: String) -> void:
	var card := collectible(id)
	card.review = not card.review
	_store_card(id, card)
	_save()

static func pack_size(worked: int) -> int:
	if worked <= 0: return 0
	if worked <= 5: return 1
	return 1 + floori(worked / 5.0)

func finish_frieze(game: FriezeSession) -> void:
	if game.rewarded or game.phase != "result": return
	game.rewarded = true
	var unseen := []
	var value := 1 if game.game_mode == "classic" else 2
	for id in game.first_try:
		var card := collectible(id)
		if not card.normal:
			unseen.append(id)
		elif game.normals_at_start.has(id) and game.first_try[id] and card.marks < GOLD_THRESHOLD:
			var gained := mini(value, GOLD_THRESHOLD - int(card.marks))
			card.marks += gained
			game.marks_gained[id] = gained
			_store_card(id, card)
			if card.marks == GOLD_THRESHOLD: game.new_gold.append(id)
	unseen.shuffle()
	game.new_normals = unseen.slice(0, pack_size(game.first_try.size()))
	for id in game.new_normals:
		var card := collectible(id)
		card.normal = true
		_store_card(id, card)
	_save()
