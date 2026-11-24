class_name CourseRepository
extends RefCounted

const CATALOGUE := "res://content/courses/catalogue.json"
const MEDIA := "res://content/course_media.json"
var _courses: Array[Dictionary] = []
var groups: Array = []
var artworks := ArtworkCatalogue.new()
var _media: Dictionary = {}

func _init() -> void:
	_media = _read(MEDIA)
	var catalogue := _read(CATALOGUE)
	groups = catalogue.get("groups", [])
	for path in catalogue.get("courses", []):
		var course := _read(path)
		if not course.get("id", "").is_empty() and not course.get("chapters", []).is_empty():
			_courses.append(course)

func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}

func all() -> Array[Dictionary]:
	return _courses.duplicate(true)

func group_title(id: String) -> String:
	for group in groups:
		if group.id == id:
			return group.title
	return ""

func find(id: String) -> Dictionary:
	for course in _courses:
		if course.get("id") == id:
			return course.duplicate(true)
	return {}

func get_media(id: String) -> Dictionary:
	return _media.get(id, {}).duplicate(true)

func get_texture(id: String) -> Texture2D:
	var path: String = get_media(id).get("path", "")
	if not path.begins_with("res://assets/courses/") or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
