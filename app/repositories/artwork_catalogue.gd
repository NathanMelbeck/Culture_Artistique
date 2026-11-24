class_name ArtworkCatalogue
extends RefCounted

const PATH := "res://content/catalogue/works.json"
var categories: Dictionary
var works: Array
var _search_text: Dictionary = {}

func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	categories = data.categories
	works = data.works
	for work in works:
		var words := PackedStringArray([work.title, work.date, work.origin, work.provenance, work.kind, categories[work.category], work.observation, work.get("maker", "")])
		words.append_array(work.periods)
		words.append_array(work.materials)
		words.append_array(work.techniques)
		_search_text[work.id] = normalized(" ".join(words))

static func normalized(value: String) -> String:
	var result := value.to_lower().strip_edges()
	for pair in [["éèêë","e"],["àâä","a"],["îï","i"],["ôö","o"],["ùûü","u"],["ç","c"],["œ","oe"],["’","'"],["–","-"]]:
		for letter in pair[0]:
			result = result.replace(letter, pair[1])
	return result

func select(filters: Dictionary, query: String = "", order: String = "") -> Array:
	var matches := []
	var tokens := normalized(query).split(" ", false)
	for work in works:
		var accepted := true
		for key in filters:
			var facet: Variant = work.get(key, "")
			if facet is Array and filters[key] not in facet or facet is String and filters[key] != facet:
				accepted = false
				break
		if accepted:
			for token in tokens:
				if token not in _search_text[work.id]:
					accepted = false
					break
		if accepted:
			matches.append(work)
	if order != "":
		matches.sort_custom(func(a, b):
			if order == "title" or a.sort_year == b.sort_year:
				return a.title.naturalnocasecmp_to(b.title) < 0
			return a.sort_year < b.sort_year if order == "oldest" else a.sort_year > b.sort_year
		)
	return matches
