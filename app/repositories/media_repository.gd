class_name MediaRepository
extends RefCounted

const MANIFEST := "res://content/media.json"
var _items: Dictionary = {}

func _init() -> void:
	var file := FileAccess.open(MANIFEST, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_items = parsed

func get_media(id: String) -> Dictionary:
	return _items.get(id, {}).duplicate(true)

func get_texture(id: String) -> Texture2D:
	var path: String = get_media(id).get("path", "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
