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
	var read: Array[String] = []
	var raw: Variant = result.get("read", [])
	if raw is Array:
		for chapter in raw:
			if chapter is String and chapter not in read:
				read.append(chapter)
	result["read"] = read
	for key in ["quiz_best", "quiz_total"]:
		if result.has(key):
			if result[key] is int or result[key] is float:
				result[key] = maxi(0, int(result[key]))
			else:
				result.erase(key)
	return result

func mark_read(course_id: String, chapter_id: String) -> void:
	var course := get_course(course_id)
	var chapters: Array = course.get("read", []) if course.get("read", []) is Array else []
	if chapter_id not in chapters:
		chapters.append(chapter_id)
	course["read"] = chapters
	_data["courses"][course_id] = course
	_save()

func is_read(course_id: String, chapter_id: String) -> bool:
	return chapter_id in get_course(course_id).get("read", [])

func save_quiz(course_id: String, score: int, total: int) -> void:
	var course := get_course(course_id)
	course["quiz_best"] = maxi(int(course.get("quiz_best", 0)), score)
	course["quiz_total"] = total
	_data["courses"][course_id] = course
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
