extends VBoxContainer

signal destination_requested(route: String)
var repository: RevisionRepository
var view_state: Dictionary = {}
var selected_id := ""
var page_index := 0
var zoom_factor := 1.0
var _sheets: Array[Dictionary] = []
var _sidebar: VBoxContainer
var _period_list: VBoxContainer
var _period_picker: OptionButton
var _period_buttons: Dictionary = {}
var _sheet_title: Label
var _page_label: Label
var _zoom_label: Label
var _position_label: Label
var _previous_page: Button
var _next_page: Button
var _previous_sheet: Button
var _next_sheet: Button
var _zoom_out: Button
var _zoom_in: Button
var _reader_scroll: ScrollContainer
var _page_image: TextureRect
var _unavailable: Label
var _body: HBoxContainer
var _heading: HBoxContainer
var _hint: Label

func _ready() -> void:
	_sheets = repository.all()
	_build()
	if _sheets.is_empty():
		_unavailable.text = "Aucune fiche disponible pour le moment."
		_unavailable.show()
		return
	_filter_periods("")
	var initial_id: String = view_state.get("sheet_id", _sheets[0]["id"])
	if repository.find(initial_id).is_empty():
		initial_id = _sheets[0]["id"]
	_open_sheet(initial_id, int(view_state.get("page", 0)), float(view_state.get("zoom", 1.0)))
	resized.connect(_adapt)
	get_viewport().size_changed.connect(_adapt)
	_reader_scroll.resized.connect(_size_page)
	_adapt.call_deferred()
	_restore_scroll.call_deferred()

func _build() -> void:
	var heading := HBoxContainer.new()
	_heading = heading
	add_child(heading)
	var title := AppTheme.label("Fiches de révision", 36, AppTheme.FOREST, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var count := AppTheme.label("%d fiches · Hors ligne" % _sheets.size(), 12, AppTheme.MUTED)
	heading.add_child(count)
	_hint = AppTheme.paragraph("Choisissez une période et retrouvez vos repères, à votre rythme.", 14)
	add_child(_hint)
	_body = HBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 24)
	add_child(_body)
	_sidebar = VBoxContainer.new()
	_sidebar.custom_minimum_size.x = 236
	_body.add_child(_sidebar)
	var search := LineEdit.new()
	search.name = "RevisionSearch"
	search.placeholder_text = "Chercher une période…"
	search.custom_minimum_size.y = 42
	search.add_theme_font_override("font", get_theme_font("font", "Label"))
	search.add_theme_color_override("font_color", AppTheme.FOREST)
	search.add_theme_color_override("font_placeholder_color", AppTheme.MUTED)
	search.add_theme_stylebox_override("normal", AppTheme.box(AppTheme.SURFACE, AppTheme.LINE))
	search.add_theme_stylebox_override("focus", AppTheme.box(AppTheme.SURFACE, AppTheme.BRONZE, 8, 2))
	search.text_changed.connect(_filter_periods)
	_sidebar.add_child(search)
	var sidebar_scroll := ScrollContainer.new()
	sidebar_scroll.name = "PeriodListScroll"
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_scroll.custom_minimum_size.y = 180
	sidebar_scroll.follow_focus = true
	_sidebar.add_child(sidebar_scroll)
	_period_list = VBoxContainer.new()
	_period_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_period_list.add_theme_constant_override("separation", 6)
	sidebar_scroll.add_child(_period_list)
	var reader := VBoxContainer.new()
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reader.add_theme_constant_override("separation", 10)
	_body.add_child(reader)
	_period_picker = OptionButton.new()
	_period_picker.name = "PeriodPicker"
	_period_picker.custom_minimum_size.y = 42
	_period_picker.fit_to_longest_item = false
	_period_picker.tooltip_text = "Choisir une période"
	reader.add_child(_period_picker)
	for sheet in _sheets:
		_period_picker.add_item(sheet["title"])
		_period_picker.set_item_metadata(_period_picker.item_count - 1, sheet["id"])
	_period_picker.item_selected.connect(func(index: int) -> void: _open_sheet(_period_picker.get_item_metadata(index)))
	_sheet_title = AppTheme.label("", 25, AppTheme.FOREST, true)
	_sheet_title.name = "RevisionTitle"
	_sheet_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reader.add_child(_sheet_title)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	reader.add_child(toolbar)
	_previous_page = _button("PreviousPage", "‹", "Page précédente")
	_previous_page.pressed.connect(_turn_page.bind(-1))
	toolbar.add_child(_previous_page)
	_page_label = AppTheme.label("", 12, AppTheme.MUTED)
	_page_label.name = "PageNumber"
	_page_label.custom_minimum_size.x = 94
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toolbar.add_child(_page_label)
	_next_page = _button("NextPage", "›", "Page suivante")
	_next_page.pressed.connect(_turn_page.bind(1))
	toolbar.add_child(_next_page)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(space)
	_zoom_out = _button("ZoomOut", "−", "Réduire")
	_zoom_out.pressed.connect(_change_zoom.bind(-0.25))
	toolbar.add_child(_zoom_out)
	_zoom_label = AppTheme.label("Largeur", 12, AppTheme.MUTED)
	_zoom_label.name = "ZoomValue"
	_zoom_label.custom_minimum_size.x = 56
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toolbar.add_child(_zoom_label)
	_zoom_in = _button("ZoomIn", "+", "Agrandir")
	_zoom_in.pressed.connect(_change_zoom.bind(0.25))
	toolbar.add_child(_zoom_in)
	var fit := _button("FitWidth", "Adapter", "Adapter la page à la largeur du lecteur")
	fit.pressed.connect(func() -> void: _set_zoom(1.0))
	toolbar.add_child(fit)
	var canvas := PanelContainer.new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size.y = 140
	canvas.add_theme_stylebox_override("panel", AppTheme.box(Color("e6e8de"), AppTheme.LINE, 10))
	reader.add_child(canvas)
	_reader_scroll = ScrollContainer.new()
	_reader_scroll.name = "RevisionPageScroll"
	_reader_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reader_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.add_child(_reader_scroll)
	_page_image = TextureRect.new()
	_page_image.name = "RevisionPageImage"
	_page_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_page_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reader_scroll.add_child(_page_image)
	_unavailable = AppTheme.paragraph("Cette page est indisponible. Vous pouvez choisir une autre fiche.", 16)
	_unavailable.hide()
	canvas.add_child(_unavailable)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	add_child(footer)
	_previous_sheet = _button("PreviousSheet", "←  Fiche précédente", "Consulter la fiche précédente")
	_previous_sheet.pressed.connect(_turn_sheet.bind(-1))
	footer.add_child(_previous_sheet)
	_position_label = AppTheme.label("", 12, AppTheme.MUTED)
	_position_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(_position_label)
	_next_sheet = _button("NextSheet", "Fiche suivante  →", "Consulter la fiche suivante")
	_next_sheet.pressed.connect(_turn_sheet.bind(1))
	footer.add_child(_next_sheet)

func _button(node_name: String, caption: String, hint: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(42, 40)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

func _filter_periods(query: String) -> void:
	if not is_instance_valid(_period_list):
		return
	for child in _period_list.get_children():
		_period_list.remove_child(child)
		child.queue_free()
	_period_buttons.clear()
	var last_group := ""
	for sheet in _sheets:
		if not repository.matches(sheet, query):
			continue
		if sheet["group"] != last_group:
			last_group = sheet["group"]
			_period_list.add_child(AppTheme.spacer(6))
			_period_list.add_child(AppTheme.eyebrow(last_group.to_upper()))
		var button := _button("Period_" + sheet["id"], sheet["title"], sheet["title"])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_open_sheet.bind(sheet["id"], 0, 1.0))
		_period_buttons[sheet["id"]] = button
		_period_list.add_child(button)
	if _period_buttons.is_empty():
		_period_list.add_child(AppTheme.paragraph("Aucune période trouvée.\nEssayez un autre nom.", 14))
	_mark_selection()

func _open_sheet(id: String, initial_page: int = 0, initial_zoom: float = 1.0) -> void:
	var sheet := repository.find(id)
	if sheet.is_empty():
		return
	selected_id = id
	page_index = clampi(initial_page, 0, sheet["pages"].size() - 1)
	zoom_factor = clampf(initial_zoom, 1.0, 3.0)
	_sheet_title.text = sheet["title"]
	_sheet_title.tooltip_text = sheet.get("credit", "")
	for index in _period_picker.item_count:
		if _period_picker.get_item_metadata(index) == id:
			_period_picker.select(index)
	_mark_selection()
	_show_page()
	var position := _sheet_index()
	_previous_sheet.disabled = position <= 0
	_next_sheet.disabled = position >= _sheets.size() - 1
	_position_label.text = "Fiche %d / %d" % [position + 1, _sheets.size()]

func _mark_selection() -> void:
	for id in _period_buttons:
		var button: Button = _period_buttons[id]
		var active: bool = id == selected_id
		button.add_theme_stylebox_override("normal", AppTheme.box(AppTheme.FOREST if active else Color.TRANSPARENT, Color.TRANSPARENT, 6, 0))
		button.add_theme_color_override("font_color", AppTheme.SURFACE if active else AppTheme.FOREST)

func _sheet_index() -> int:
	for index in _sheets.size():
		if _sheets[index]["id"] == selected_id:
			return index
	return 0

func _turn_sheet(direction: int) -> void:
	if _sheets.is_empty():
		return
	var index := clampi(_sheet_index() + direction, 0, _sheets.size() - 1)
	_open_sheet(_sheets[index]["id"])

func _turn_page(direction: int) -> void:
	var count: int = repository.find(selected_id).get("pages", []).size()
	if count == 0:
		return
	page_index = clampi(page_index + direction, 0, count - 1)
	_show_page()

func _show_page() -> void:
	_page_image.texture = repository.load_page(selected_id, page_index)
	_unavailable.visible = _page_image.texture == null
	_page_image.visible = _page_image.texture != null
	_reader_scroll.scroll_horizontal = 0
	_reader_scroll.scroll_vertical = 0
	var count: int = repository.find(selected_id).get("pages", []).size()
	_page_label.text = "Page %d / %d" % [page_index + 1, count]
	_previous_page.disabled = page_index <= 0
	_next_page.disabled = page_index >= count - 1
	_update_zoom_buttons()
	_size_page.call_deferred()

func _change_zoom(amount: float) -> void:
	_set_zoom(zoom_factor + amount)

func _set_zoom(value: float) -> void:
	zoom_factor = clampf(value, 1.0, 3.0)
	_update_zoom_buttons()
	_size_page()
	if is_equal_approx(zoom_factor, 1.0):
		_reader_scroll.scroll_horizontal = 0
		_reader_scroll.scroll_vertical = 0

func _update_zoom_buttons() -> void:
	_zoom_label.text = "Largeur" if is_equal_approx(zoom_factor, 1.0) else "%d %%" % roundi(zoom_factor * 100)
	_zoom_out.disabled = zoom_factor <= 1.0
	_zoom_in.disabled = zoom_factor >= 3.0

func _size_page() -> void:
	if not is_instance_valid(_page_image) or _page_image.texture == null:
		return
	# Reserve the scrollbar gutter so fit-width never creates horizontal overflow.
	var width := maxf(1.0, _reader_scroll.size.x - _reader_scroll.get_v_scroll_bar().get_combined_minimum_size().x - 2)
	var ratio := float(_page_image.texture.get_height()) / _page_image.texture.get_width()
	_page_image.custom_minimum_size = Vector2(width * zoom_factor, width * zoom_factor * ratio)

func _adapt() -> void:
	if not is_instance_valid(_sidebar):
		return
	_sidebar.visible = size.x >= 1050
	_period_picker.visible = not _sidebar.visible
	_sheet_title.visible = _sidebar.visible
	var short_window := get_viewport_rect().size.y < 760
	_heading.visible = not short_window
	_hint.visible = not short_window
	_size_page.call_deferred()

func get_view_state() -> Dictionary:
	return {"sheet_id": selected_id, "page": page_index, "zoom": zoom_factor, "x": _reader_scroll.scroll_horizontal, "y": _reader_scroll.scroll_vertical}

func _restore_scroll() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_reader_scroll.scroll_horizontal = int(view_state.get("x", 0))
	_reader_scroll.scroll_vertical = int(view_state.get("y", 0))

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is OptionButton:
		return
	if event.keycode == KEY_RIGHT:
		_turn_page(1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_LEFT:
		_turn_page(-1)
		get_viewport().set_input_as_handled()
