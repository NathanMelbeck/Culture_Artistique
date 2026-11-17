extends VBoxContainer

signal destination_requested(route: String)
signal course_requested(course_id: String, chapter_id: String)
var repository: ChronologyRepository
var view_state: Dictionary = {}
var session: FriezeSession
var mode := "catalogue"
var anchors: Array = []
var selected_card := ""
var selected_result := ""
var _content: VBoxContainer
var _board: ScrollContainer
var _board_position := 0
var _message := ""
var _refresh_queued := false
var _pointer_position := Vector2.ZERO
const GOOD := Color("256343")
const BAD := Color("a33435")

func _ready() -> void:
	mode = view_state.get("mode", "catalogue")
	anchors = view_state.get("anchors", [])
	session = view_state.get("session", null)
	selected_card = view_state.get("selected", "")
	selected_result = view_state.get("result", "")
	_board_position = view_state.get("scroll", 0)
	add_theme_constant_override("separation", 8)
	_content = VBoxContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	add_child(_content)
	resized.connect(_adapt)
	_render()

func get_view_state() -> Dictionary:
	return {"mode": mode, "anchors": anchors.duplicate(), "session": session, "selected": selected_card, "result": selected_result, "scroll": _board.scroll_horizontal if is_instance_valid(_board) else _board_position}

func _refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_render.call_deferred()

func _render() -> void:
	_refresh_queued = false
	var focused := get_viewport().gui_get_focus_owner()
	var focus_name: String = str(focused.name) if is_instance_valid(focused) and is_ancestor_of(focused) else ""
	if is_instance_valid(_board):
		_board_position = _board.scroll_horizontal
	_board = null
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if mode == "catalogue":
		_catalogue()
	elif mode == "setup" or session == null:
		_setup()
	elif session.phase in ["start", "end"]:
		_boundary()
	elif session.phase in ["placement", "result"]:
		_play()
	else:
		_content.add_child(AppTheme.paragraph("Aucun événement disponible pour cette sélection."))
		_content.add_child(_button("Changer de sélection", "ChangePeriods", _show_setup))
	if not focus_name.is_empty():
		_restore_focus.call_deferred(focus_name)
	_adapt()

func _adapt() -> void:
	if not is_inside_tree():
		return
	var height := 156 if get_viewport_rect().size.y >= 800 else 116
	for slot in find_children("FriezeSlot_*", "Button", true, false):
		slot.custom_minimum_size.y = height

func _restore_focus(node_name: String) -> void:
	var control := find_child(node_name, true, false) as Control
	if control != null:
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
	card.add_child(_button("Choisir les périodes  →", "OpenFrieze", _show_setup, true))
	column.add_child(AppTheme.paragraph("Les quiz de chaque période restent accessibles à la fin des cours. La frise fonctionne entièrement hors ligne.", 14))

func _show_setup() -> void:
	mode = "setup"
	selected_card = ""
	selected_result = ""
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
	var count := repository.events_for(selection).size()
	var summary := AppTheme.paragraph("Sélectionnez au moins une période." if count == 0 else "%d période(s) · %d événements · 7 cartes maximum en main" % [selection.size(), count], 16, AppTheme.FOREST)
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
	var cards := repository.events_for(selection)
	if cards.is_empty():
		return
	session = FriezeSession.new(selection, cards)
	mode = "play"
	selected_card = ""
	selected_result = ""
	_board_position = 0
	_message = ""
	_refresh()

func _period_names() -> String:
	var names := PackedStringArray()
	for period in session.periods:
		names.append(period["title"])
	return " · ".join(names)

func _boundary() -> void:
	var row := _heading("Frise à remplir", "← Périodes", _show_setup, "ChangePeriods")
	row.add_child(AppTheme.label("ÉTAPE %d / 3" % (1 if session.phase == "start" else 2), 12, AppTheme.BRONZE))
	var column := _scroll_column()
	column.add_child(AppTheme.paragraph(_period_names(), 14))
	var first := session.phase == "start"
	column.add_child(AppTheme.label("Retrouver le début" if first else "Retrouver la fin", 34, AppTheme.FOREST, true))
	var question := "À quelle date débute la période la plus ancienne de votre sélection ?" if first else "Quelle est la borne de fin la plus tardive parmi ces périodes ?"
	column.add_child(AppTheme.paragraph(question, 19, AppTheme.FOREST))
	column.add_child(AppTheme.paragraph("Période de référence : " + (session.start_period["title"] if first else session.end_period["title"]), 14))
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SAGE, AppTheme.LINE, 12))
	var line := HBoxContainer.new()
	var begin := AppTheme.label("Début à retrouver" if first else ChronologyRepository.date_label(int(session.start_period["start"]), session.start_period.get("start_approximate", false)), 16)
	line.add_child(begin)
	var rule := AppTheme.divider()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(rule)
	line.add_child(AppTheme.label("Fin à retrouver", 16))
	frame.add_child(line)
	column.add_child(frame)
	var choices := HFlowContainer.new()
	choices.add_theme_constant_override("h_separation", 12)
	choices.add_theme_constant_override("v_separation", 12)
	var approximate: bool = session.start_period.get("start_approximate", false) if first else session.end_period.get("end_approximate", false)
	for value in session.boundary_choices():
		var year := int(value)
		var answer := _button(ChronologyRepository.date_label(year, approximate), "Boundary_" + str(year), _answer_boundary.bind(year))
		answer.custom_minimum_size = Vector2(190, 52)
		answer.add_theme_stylebox_override("normal", AppTheme.box(AppTheme.SURFACE, AppTheme.LINE, 8))
		answer.disabled = year in session.wrong_choices
		choices.add_child(answer)
	column.add_child(choices)
	var feedback := AppTheme.paragraph(_message if not _message.is_empty() else "Cinq propositions. En cas d’erreur, réessayez : aucun essai n’est perdu.", 15, AppTheme.BRONZE)
	feedback.name = "BoundaryFeedback"
	column.add_child(feedback)
	column.add_child(AppTheme.paragraph("Les bornes reprennent le découpage des styles dans vos fiches de révision. Elles se distinguent des dates historiques des événements.", 13))

func _answer_boundary(year: int) -> void:
	var previous := session.phase
	if session.answer_boundary(year):
		_message = "Début trouvé. Retrouvez maintenant la borne de fin." if previous == "start" else ""
	else:
		_message = "Ce n’est pas la borne attendue. Essayez une autre proposition."
	_refresh()

func _play() -> void:
	var result := session.phase == "result"
	var row := _heading("Frise à remplir", "← Périodes", _show_setup, "ChangePeriods")
	var progress := AppTheme.label("%d / %d bien placées" % [session.score(), session.events.size()] if result else "%d / %d cartes posées" % [session.placements.size(), session.events.size()], 14, GOOD if result else AppTheme.MUTED)
	progress.name = "FriezeProgress"
	row.add_child(progress)
	if session.can_validate():
		row.add_child(_button("Valider la frise", "ValidateFrieze", _validate, true))
	if result:
		row.add_child(_button("Rejouer", "ReplayFrieze", _start_game, true))
	var help := "Cliquez sur une carte de la frise pour lire sa correction." if result else "Glissez une carte sur une date, ou sélectionnez puis cliquez. Les espacements ne représentent pas les durées."
	_content.add_child(AppTheme.paragraph(help, 13, AppTheme.FOREST))
	_build_board()
	if result:
		_build_correction()
	else:
		_build_hand()

func _build_board() -> void:
	_board = ScrollContainer.new()
	_board.name = "FriezeBoardScroll"
	_board.custom_minimum_size.y = 168
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_board.follow_focus = true
	_content.add_child(_board)
	var stage := CenterContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.add_child(stage)
	var track := FriezeTrack.new()
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stage.add_child(track)
	_add_bound(track, "DÉBUT", ChronologyRepository.date_label(int(session.start_period["start"]), session.start_period.get("start_approximate", false)))
	for event in session.events:
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 176
		column.add_theme_constant_override("separation", 8)
		track.add_child(column)
		var date := AppTheme.label(ChronologyRepository.event_date(event), 14, AppTheme.FOREST)
		date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(date)
		column.add_child(AppTheme.spacer(8))
		var slot := FriezeSlot.new()
		slot.name = "FriezeSlot_" + event["id"]
		slot.slot_id = event["id"]
		slot.card_id = session.placements.get(event["id"], "")
		slot.session = session
		slot.hand_card = false
		slot.custom_minimum_size = Vector2(176, 116)
		slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		slot.text = "Déposez\nune carte" if slot.card_id.is_empty() else session.event(slot.card_id)["title"]
		slot.selected = not selected_card.is_empty() and slot.card_id == selected_card
		slot.card_dropped.connect(_place)
		slot.pressed.connect(_slot_clicked.bind(event["id"]))
		column.add_child(slot)
		if session.phase == "result":
			var correct := session.slot_correct(event["id"])
			var color := GOOD if correct else BAD
			slot.text = ("✓ " if correct else "✕ ") + slot.text
			slot.add_theme_stylebox_override("normal", AppTheme.box(Color("e3efdf") if correct else Color("f7e5df"), color, 10, 2))
			slot.add_theme_color_override("font_color", color)
	_add_bound(track, "FIN", ChronologyRepository.date_label(int(session.end_period["end"])))
	_restore_board.call_deferred()

func _add_bound(track: HBoxContainer, heading: String, date: String) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 170
	column.add_child(AppTheme.label(date, 14, AppTheme.FOREST))
	column.add_child(AppTheme.spacer(14))
	column.add_child(AppTheme.eyebrow(heading))
	column.add_child(AppTheme.paragraph("Repère de la sélection", 12))
	track.add_child(column)

func _restore_board() -> void:
	if is_instance_valid(_board):
		_board.scroll_horizontal = _board_position

func _build_hand() -> void:
	var panel := PanelContainer.new()
	panel.name = "FriezeHandPanel"
	var style := AppTheme.box(AppTheme.FOREST, AppTheme.FOREST, 14)
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	panel.add_theme_stylebox_override("panel", style)
	_content.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	panel.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var label := AppTheme.label("VOTRE MAIN · %d / 7" % session.hand.size(), 12, AppTheme.IVORY)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var deck := AppTheme.label("PIOCHE · %d" % session.draw_pile.size(), 12, AppTheme.LIGHT_TEXT)
	deck.name = "DrawPileCount"
	row.add_child(deck)
	var discard := _button("Défausser la sélection", "DiscardFriezeCard", _discard)
	discard.add_theme_color_override("font_color", AppTheme.IVORY)
	discard.disabled = selected_card not in session.hand or session.draw_pile.is_empty()
	discard.tooltip_text = "La carte retourne dans la pioche mélangée ; une autre prend sa place." if not session.draw_pile.is_empty() else "Pioche vide : placez ou échangez les cartes restantes."
	row.add_child(discard)
	var hand := FriezeHand.new()
	hand.name = "FriezeHand"
	hand.session = session
	hand.selected_id = selected_card
	hand.card_selected.connect(_select_card)
	hand.card_returned.connect(_return_card)
	column.add_child(hand)
	if session.hand.is_empty():
		hand.add_child(AppTheme.paragraph("Toutes les cartes sont placées. Vous pouvez encore les échanger avant de valider.", 15, AppTheme.IVORY))
	var hint := AppTheme.paragraph(_message if not _message.is_empty() else "Une carte piochée après chaque pose · Défausse remélangée · Vous pouvez échanger les cartes déjà posées", 11, AppTheme.LIGHT_TEXT)
	hint.name = "HandFeedback"
	column.add_child(hint)

func _select_card(id: String) -> void:
	selected_card = "" if selected_card == id else id
	_message = "Carte sélectionnée : choisissez un emplacement, ou défaussez-la pour renouveler votre main."
	_refresh()

func _slot_clicked(id: String) -> void:
	if session.phase == "result":
		selected_result = id
		_refresh()
		return
	if not selected_card.is_empty():
		if session.placements.get(id, "") == selected_card:
			selected_card = ""
			_refresh()
		else:
			_place(selected_card, id)
	elif session.placements.has(id):
		selected_card = session.placements[id]
		_message = "Carte du plateau sélectionnée : choisissez une autre date pour la déplacer ou l’échanger."
		_refresh()

func _place(card_id: String, slot_id: String) -> void:
	if session.place(card_id, slot_id):
		selected_card = ""
		_message = "Carte placée. Les réponses seront vérifiées à la validation finale."
		_refresh()

func _return_card(id: String) -> void:
	if session.return_to_hand(id):
		selected_card = ""
		_message = "Carte reprise en main."
		_refresh()

func _discard() -> void:
	if session.discard(selected_card):
		selected_card = ""
		_message = "Une autre carte a été piochée. La carte défaussée est retournée dans la pioche mélangée."
		_refresh()

func _validate() -> void:
	if not session.validate():
		return
	selected_result = ""
	for event in session.events:
		if not session.slot_correct(event["id"]):
			selected_result = event["id"]
			break
	if selected_result.is_empty():
		selected_result = session.events[0]["id"]
	_message = ""
	_refresh()

func _build_correction() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "FriezeCorrectionScroll"
	scroll.custom_minimum_size.y = 190
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	if selected_result.is_empty():
		selected_result = session.events[0]["id"]
	var actual_id: String = session.placements[selected_result]
	var actual := session.event(actual_id)
	var correct := session.slot_correct(selected_result)
	column.add_child(AppTheme.eyebrow("BIEN PLACÉE" if correct else "À REPLACER DANS LE TEMPS"))
	column.add_child(AppTheme.paragraph(actual["title"], 20, GOOD if correct else BAD))
	var expected := ChronologyRepository.event_date(actual)
	column.add_child(AppTheme.paragraph("Repère attendu : " + expected + ("." if correct else ". Votre emplacement : " + ChronologyRepository.event_date(session.event(selected_result)) + "."), 15, AppTheme.FOREST))
	column.add_child(AppTheme.paragraph(actual["explanation"], 15, AppTheme.FOREST))
	var links := HFlowContainer.new()
	links.add_child(_button("Revoir le cours", "ReviewFriezeCourse", func() -> void: course_requested.emit(actual["course_id"], actual["chapter"])))
	links.add_child(_button("Source · Internet requis ↗", "FriezeSource", func() -> void: OS.shell_open(actual["source"]["url"])))
	column.add_child(links)
	column.add_child(AppTheme.paragraph("Borne de début : " + session.start_period["start_note"] + "\nBorne de fin : " + session.end_period["end_note"], 12))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_pointer_position = event.position

func _process(delta: float) -> void:
	if not is_instance_valid(_board) or not get_viewport().gui_is_dragging():
		return
	var pointer := _board.get_global_transform_with_canvas().affine_inverse() * _pointer_position
	if pointer.y < 0 or pointer.y > _board.size.y:
		return
	if pointer.x < 48:
		_board.scroll_horizontal -= ceili(delta * 650)
	elif pointer.x > _board.size.x - 48:
		_board.scroll_horizontal += ceili(delta * 650)
