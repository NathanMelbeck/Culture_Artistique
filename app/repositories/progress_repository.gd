class_name ProgressRepository
extends RefCounted

const DEFAULT_PATH := "user://learning_progress.json"
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
