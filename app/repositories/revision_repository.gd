class_name RevisionRepository
extends RefCounted

const CATALOGUE := "res://content/revision_sheets.json"
var _sheets: Array[Dictionary] = []

func _init() -> void:
	var file := FileAccess.open(CATALOGUE, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.get("sheets", []) is Array:
		return
	for item in parsed.get("sheets", []):
		if item is Dictionary and item.get("id", "") is String and item.get("pages", []) is Array:
			if not item.get("id", "").is_empty() and not item.get("pages", []).is_empty():
				_sheets.append(item)

func all() -> Array[Dictionary]:
	return _sheets.duplicate(true)

func find(id: String) -> Dictionary:
	for sheet in _sheets:
		if sheet.get("id") == id:
			return sheet.duplicate(true)
	return {}

func load_page(id: String, index: int) -> Texture2D:
	var sheet := find(id)
	var pages: Array = sheet.get("pages", [])
	if index < 0 or index >= pages.size() or not pages[index] is Dictionary:
		return null
	var path: String = pages[index].get("path", "")
	if not path.begins_with("res://assets/revision_sheets/") or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func normalize(value: String) -> String:
	var result := value.to_lower()
	for pair in [["é", "e"], ["è", "e"], ["ê", "e"], ["ë", "e"], ["à", "a"], ["â", "a"], ["î", "i"], ["ï", "i"], ["ô", "o"], ["ö", "o"], ["ù", "u"], ["û", "u"], ["ü", "u"], ["ç", "c"], ["œ", "oe"], ["-", " "], ["’", " "]]:
		result = result.replace(pair[0], pair[1])
	return result.strip_edges()

func matches(sheet: Dictionary, query: String) -> bool:
	if query.strip_edges().is_empty():
		return true
	var terms := "%s %s %s" % [sheet.get("title", ""), sheet.get("group", ""), " ".join(sheet.get("aliases", []))]
	return normalize(query) in normalize(terms)
