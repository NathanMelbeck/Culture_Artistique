extends VBoxContainer

signal destination_requested(route: String)
signal course_requested(period: String, chapter: String)

const PAGE_SIZE := 12
var repository: CourseRepository
var view_state: Dictionary = {}
var _filters: Dictionary = {}
var _pickers: Dictionary = {}
var _order := "oldest"
var _page := 0
var _query := LineEdit.new()
var _count: Label
var _gallery := ArtworkGallery.new()
var _scroll := ScrollContainer.new()
var _previous: Button
var _next: Button
var _page_label: Label
var _sort: OptionButton
var _more := AppTheme.quiet_button("Plus de filtres")

func _ready() -> void:
	size_flags_vertical = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	add_child(AppTheme.label("Catalogue", 40, AppTheme.FOREST, true))
	_filters = view_state.get("filters", {}).duplicate()
	_order = view_state.get("order", "oldest")
	_page = view_state.get("page", 0)
	_query.name = "ArtworkSearch"
	_query.placeholder_text = "Rechercher une œuvre, un artiste, une technique…"
	_query.clear_button_enabled = true
	_query.add_theme_stylebox_override("normal", AppTheme.box(AppTheme.SURFACE, AppTheme.LINE))
	_query.add_theme_stylebox_override("focus", AppTheme.box(AppTheme.SURFACE, AppTheme.BRONZE))
	_query.add_theme_color_override("font_color", AppTheme.FOREST)
	_query.add_theme_color_override("font_placeholder_color", AppTheme.MUTED)
	_query.add_theme_color_override("caret_color", AppTheme.FOREST)
	_query.text = view_state.get("query", "")
	_query.custom_minimum_size.y = 40
	_query.text_changed.connect(func(_value): _refresh(true))
	add_child(_query)
	var row := HFlowContainer.new()
	add_child(row)
	var periods := {}
	for course in repository.all():
		periods[course.period_id] = course.title
	_add_filter(row, "periods", "Période", periods)
	_add_filter(row, "category", "Catégorie", repository.artworks.categories)
	_add_filter(row, "kind", "Type", _values("kind"))
	_add_filter(row, "provenance", "Provenance", _values("provenance"))
	_more.name = "MoreFilters"
	_more.toggle_mode = true
	row.add_child(_more)
	var advanced := HFlowContainer.new()
	add_child(advanced)
	_add_filter(advanced, "materials", "Matériau", _values("materials"))
	_add_filter(advanced, "techniques", "Technique", _values("techniques"))
	_add_filter(advanced, "maker", "Auteurs et ateliers", _values("maker"))
	advanced.visible = _filters.has("materials") or _filters.has("techniques") or _filters.has("maker")
	_more.button_pressed = advanced.visible
	_more.toggled.connect(func(active): advanced.visible = active)
	var summary := HBoxContainer.new()
	add_child(summary)
	_count = AppTheme.label("", 15, AppTheme.MUTED)
	_count.size_flags_horizontal = SIZE_EXPAND_FILL
	summary.add_child(_count)
	var reset := AppTheme.quiet_button("Réinitialiser")
	reset.name = "ResetCatalogue"
	reset.pressed.connect(_reset)
	summary.add_child(reset)
	_sort = OptionButton.new()
	_sort.name = "ArtworkSort"
	_sort.accessibility_name = "Trier les œuvres"
	for pair in [["oldest","Plus anciennes"],["newest","Plus récentes"],["title","Titres de A à Z"]]:
		_sort.add_item(pair[1])
		_sort.set_item_metadata(_sort.item_count - 1, pair[0])
		if pair[0] == _order: _sort.select(_sort.item_count - 1)
	_sort.item_selected.connect(func(i):
		_order = _sort.get_item_metadata(i)
		_refresh(true))
	summary.add_child(_sort)
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)
	_gallery.size_flags_horizontal = SIZE_EXPAND_FILL
	_gallery.repository = repository
	_gallery.course_requested.connect(course_requested.emit)
	_scroll.add_child(_gallery)
	var pager := HBoxContainer.new()
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(pager)
	_previous = AppTheme.quiet_button("← Précédente")
	_previous.pressed.connect(_turn.bind(-1))
	pager.add_child(_previous)
	_page_label = AppTheme.label("", 14, AppTheme.MUTED)
	pager.add_child(_page_label)
	_next = AppTheme.quiet_button("Suivante →")
	_next.pressed.connect(_turn.bind(1))
	pager.add_child(_next)
	_refresh(false)
	_scroll.set_deferred("scroll_vertical", view_state.get("scroll", 0))

func _values(key: String) -> Dictionary:
	var values := {}
	for work in repository.artworks.works:
		var facet: Variant = work.get(key, "")
		for value in (facet if facet is Array else [facet]):
			if value != "" and not (key == "maker" and str(value).begins_with("Commanditaire")):
				values[value] = value
	values.sort()
	return values

func _add_filter(parent: Container, key: String, caption: String, values: Dictionary) -> void:
	var picker := OptionButton.new()
	picker.name = "Filter_" + key
	picker.accessibility_name = caption
	picker.fit_to_longest_item = false
	picker.clip_text = true
	picker.custom_minimum_size = Vector2(176,36)
	picker.add_item(caption)
	picker.set_item_metadata(0, "")
	for value in values:
		picker.add_item(values[value])
		picker.set_item_metadata(picker.item_count - 1, value)
		if _filters.get(key) == value: picker.select(picker.item_count - 1)
	_pickers[key] = picker
	parent.add_child(picker)
	picker.item_selected.connect(func(i):
		if i == 0: _filters.erase(key)
		else: _filters[key] = picker.get_item_metadata(i)
		_refresh(true))

func _reset() -> void:
	_filters.clear()
	_more.button_pressed = false
	for picker in _pickers.values(): picker.select(0)
	_query.text = ""
	_order = "oldest"
	_sort.select(0)
	_refresh(true)

func _turn(step: int) -> void:
	_page += step
	_refresh(false)

func _refresh(first_page: bool) -> void:
	var matches := repository.artworks.select(_filters, _query.text, _order)
	var pages := maxi(1, ceili(float(matches.size()) / PAGE_SIZE))
	_page = 0 if first_page else clampi(_page, 0, pages - 1)
	_count.text = "Aucune œuvre pour cette recherche" if matches.is_empty() else "%d œuvre%s" % [matches.size(), "s" if matches.size() > 1 else ""]
	_gallery.display(matches.slice(_page * PAGE_SIZE, (_page + 1) * PAGE_SIZE), false)
	_previous.get_parent().visible = pages > 1
	_previous.disabled = _page == 0
	_next.disabled = _page == pages - 1
	_page_label.text = "%d / %d" % [_page + 1, pages]
	_scroll.scroll_vertical = 0

func get_view_state() -> Dictionary:
	return {"filters": _filters.duplicate(), "query": _query.text, "order": _order, "page": _page, "scroll": _scroll.scroll_vertical}
