extends VBoxContainer

signal immersive_changed(active: bool)
signal destination_requested(route: String)
signal course_requested(course_id: String, chapter_id: String)
signal revision_requested(sheet_id: String)
var repository: ChronologyRepository
var view_state: Dictionary = {}
var session: FriezeSession
var mode := "catalogue"
var anchors: Array = []
var selected_card := ""
var _content: VBoxContainer
var screen: Control
var _board_position := 0
var _message := ""
var _refresh_queued := false
var comparison_index := 0

func _ready() -> void:
	mode = view_state.get("mode", "catalogue")
	anchors = view_state.get("anchors", [])
	session = view_state.get("session", null)
	selected_card = view_state.get("selected", "")
	_board_position = view_state.get("scroll", 0)
	add_theme_constant_override("separation", 8)
	_content = VBoxContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	add_child(_content)
	comparison_index = view_state.get("comparison_index", 0)
	_render()

func get_view_state() -> Dictionary:
	return {"mode": mode, "anchors": anchors.duplicate(), "session": session, "selected": selected_card, "scroll": _board_position, "comparison_index": comparison_index}

func _refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_render.call_deferred()

func _render() -> void:
	_refresh_queued = false
	var focused := get_viewport().gui_get_focus_owner()
	var focus_name: String = str(focused.name) if is_instance_valid(focused) and is_ancestor_of(focused) else ""
	immersive_changed.emit(mode == "play")
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if mode == "catalogue":
		_catalogue()
	elif mode == "setup" or session == null:
		_setup()
	elif mode == "play":
		screen = preload("res://scenes/games/chroniques.gd").new()
		screen.controller = self
		screen.session = session
		screen.size_flags_vertical = SIZE_EXPAND_FILL
		_content.add_child(screen)
	else:
		_content.add_child(AppTheme.paragraph("Aucune carte disponible pour cette sélection."))
		_content.add_child(_button("Changer de sélection", "ChangePeriods", _show_setup))
	if not focus_name.is_empty():
		_restore_focus.call_deferred(focus_name)
func _restore_focus(node_name: String) -> void:
	var control := find_child(node_name, true, false) as Control
	if control != null and control.is_visible_in_tree() and control.focus_mode != FOCUS_NONE and not (control is BaseButton and control.disabled):
		control.grab_focus()

func _button(text: String, node_name: String, action: Callable, primary: bool = false) -> Button:
	var button := AppTheme.quiet_button(text)
	button.name = node_name
	button.pressed.connect(action)
	if primary:
		button.add_theme_stylebox_override("normal", AppTheme.box(AppTheme.FOREST, AppTheme.FOREST, 8))
		for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(state, AppTheme.IVORY)
		button.add_theme_stylebox_override("hover", AppTheme.box(Color("36564b"), AppTheme.FOREST, 8))
		button.add_theme_stylebox_override("pressed", AppTheme.box(Color("1c302b"), AppTheme.FOREST, 8))
	return button

func _heading(title: String, back_text: String, action: Callable, back_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(_button(back_text, back_name, action))
	var label := AppTheme.label(title, 26, AppTheme.FOREST, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	_content.add_child(row)
	return row

func _scroll_column() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	return column

func _catalogue() -> void:
	_heading("Les jeux", "← Accueil", func() -> void: destination_requested.emit("home"), "BackHome")
	var column := _scroll_column()
	column.add_child(AppTheme.eyebrow("OBSERVER · SITUER · MÉMORISER"))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SAGE, AppTheme.LINE, 14))
	column.add_child(panel)
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 18)
	panel.add_child(card)
	card.add_child(AppTheme.label("Frise à remplir", 38, AppTheme.FOREST, true))
	card.add_child(AppTheme.paragraph("Retrouvez les bornes d’une époque, puis replacez les événements sur leurs dates. Une main de sept cartes, une pioche et votre mémoire pour reconstruire l’histoire.", 19, AppTheme.FOREST))
	card.add_child(AppTheme.paragraph("1 · Choisir les périodes      2 · Retrouver les bornes      3 · Placer les cartes", 15))
	card.add_child(AppTheme.paragraph("Placez d’abord tous les repères de période : leur correction est immédiate. Les événements se débloquent une fois ces repères validés. Les deux bornes déjà trouvées sont exclues du paquet.", 14, AppTheme.FOREST))
	card.add_child(_button("Choisir les périodes  →", "OpenFrieze", _show_setup, true))
	column.add_child(AppTheme.paragraph("Les quiz de chaque période restent accessibles à la fin des cours. La frise fonctionne entièrement hors ligne.", 14))

func _show_setup() -> void:
	mode = "setup"
	selected_card = ""
	_message = ""
	_refresh()

func _setup() -> void:
	_heading("Choisir les périodes", "← Les jeux", func() -> void:
		mode = "catalogue"
		_refresh()
	, "GamesBack")
	var column := _scroll_column()
	column.add_child(AppTheme.paragraph("Choisissez une ou plusieurs périodes. Celles situées entre vos choix sont incluses automatiquement.", 17, AppTheme.FOREST))
	for group in repository.groups:
		column.add_child(_button(group["title"], "Group_" + group["id"], func() -> void:
			anchors = group["periods"].duplicate()
			_refresh()
		))
	var selection := repository.resolve_periods(anchors)
	var ids: Array = []
	for period in selection:
		ids.append(period["id"])
	for period in repository.periods:
		var row := HBoxContainer.new()
		var check := CheckBox.new()
		check.name = "SelectPeriod_" + period["id"]
		check.text = period["title"]
		check.custom_minimum_size = Vector2(210, 46)
		check.button_pressed = period["id"] in ids
		check.toggled.connect(_toggle_period.bind(period["id"]))
		row.add_child(check)
		var automatically_added: bool = period["id"] in ids and period["id"] not in anchors
		var note := AppTheme.paragraph("Ajoutée automatiquement · " + period["scope"] if automatically_added else period["scope"], 14)
		note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(note)
		column.add_child(row)
	var count := repository.cards_for(selection).size()
	var summary := AppTheme.paragraph("Sélectionnez au moins une période." if count == 0 else "%d période(s) · %d repères de période + %d événements · 7 cartes maximum en main" % [selection.size(), repository.boundary_cards_for(selection).size(), repository.events_for(selection).size()], 16, AppTheme.FOREST)
	summary.name = "SelectionSummary"
	column.add_child(summary)
	if not _message.is_empty():
		column.add_child(AppTheme.paragraph(_message, 14, AppTheme.BRONZE))
	var controls := HBoxContainer.new()
	controls.add_child(_button("Tout effacer", "ClearPeriods", func() -> void:
		anchors.clear()
		_message = ""
		_refresh()
	))
	var start := _button("Commencer la frise  →", "StartFrieze", _start_game, true)
	start.disabled = count == 0
	controls.add_child(start)
	_content.add_child(controls)

func _toggle_period(checked: bool, id: String) -> void:
	_message = ""
	if checked and id not in anchors:
		anchors.append(id)
	elif not checked:
		if id in anchors:
			anchors.erase(id)
		else:
			_message = "Cette période reste incluse entre vos deux choix. Modifiez une extrémité pour réduire la sélection."
	_refresh()

func _start_game() -> void:
	var selection := repository.resolve_periods(anchors)
	var cards := repository.cards_for(selection)
	if cards.is_empty():
		return
	session = FriezeSession.new(selection, cards)
	mode = "play"
	selected_card = ""
	_board_position = 0
	_message = ""
	_refresh()


func _place(id: String, slot_id: String) -> void:
	if session.place(id, slot_id):
		selected_card = ""
		_message = ""
		_refresh()

func select_card(id: String) -> void:
	selected_card = "" if selected_card == id else id
	_refresh()

func slot_clicked(slot_id: String) -> void:
	if session.locked(slot_id):
		return
	if selected_card != "":
		_place(selected_card, slot_id)
	elif session.placements.has(slot_id):
		select_card(session.placements[slot_id])

func answer(year: int) -> void:
	_message = "" if session.answer_boundary(year) else "Ce n’est pas la bonne borne. Essayez une autre carte."
	_refresh()

func validate_board() -> void:
	if session.validate():
		comparison_index = 0
		selected_card = ""
		_refresh()
