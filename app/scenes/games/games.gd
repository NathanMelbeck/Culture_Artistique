extends VBoxContainer

signal immersive_changed(active: bool)
signal destination_requested(route: String)
signal course_requested(course_id: String, chapter_id: String)
signal revision_requested(sheet_id: String)
var progress_repository: ProgressRepository
var game_mode := "classic"
var requested_events := 10
var all_events := false
var collection_filter := 0
var lobby_scroll := 0
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
var review_original := false
var review_all := false
var sound_enabled := true
var resume_anchors: Array = []
var focus_after := ""
var boundary_feedback := ""
var animate_correction := false
var retry_origins: Dictionary = {}
var sound_player := AudioStreamPlayer.new()
const DEAL_SOUND := preload("res://assets/frieze/paper.wav")
const CONFIRM_SOUND := preload("res://assets/frieze/confirm.wav")

func _ready() -> void:
	game_mode = view_state.get("game_mode", "classic")
	requested_events = view_state.get("requested_events", 10)
	all_events = view_state.get("all_events", false)
	if progress_repository == null: progress_repository = ProgressRepository.new()
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
	review_original = view_state.get("review_original", false)
	review_all = view_state.get("review_all", false)
	resume_anchors = view_state.get("resume_anchors", [])
	sound_enabled = view_state.get("sound_enabled", true)
	add_child(sound_player)
	_render()

func _exit_tree() -> void:
	sound_player.stop()
	sound_player.stream = null

func play_sound(confirmed := false) -> void:
	if sound_enabled:
		sound_player.stream = CONFIRM_SOUND if confirmed else DEAL_SOUND
		sound_player.play()

func get_view_state() -> Dictionary:
	return {"game_mode": game_mode, "requested_events": requested_events, "all_events": all_events, "mode": mode, "anchors": anchors.duplicate(), "session": session, "selected": selected_card, "scroll": _board_position, "comparison_index": comparison_index, "review_original": review_original, "review_all": review_all, "sound_enabled": sound_enabled, "resume_anchors": resume_anchors.duplicate()}

func _refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_render.call_deferred()

func _render() -> void:
	_refresh_queued = false
	var focused := get_viewport().gui_get_focus_owner()
	var focus_name: String = str(focused.name) if is_instance_valid(focused) and is_ancestor_of(focused) else ""
	var explicit_focus := focus_after != ""
	if explicit_focus:
		focus_name = focus_after
		focus_after = ""
	if mode == "play" and is_instance_valid(screen) and screen.is_inside_tree() and screen.session == session and screen.can_update_board():
		screen.update_board()
		if not focus_name.is_empty() and (explicit_focus or get_viewport().gui_get_focus_owner() == null):
			_restore_focus(focus_name)
		return
	immersive_changed.emit(mode in ["play", "collection", "setup"])
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if mode == "catalogue":
		_catalogue()
	elif mode in ["setup", "collection"] or session == null:
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
	if not focus_name.is_empty() and not focus_name.begins_with("Boundary_"):
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
	card.add_child(_button("Collection de Chroniques", "OpenCollection", open_collection))
	card.add_child(_button("Choisir les périodes  →", "OpenFrieze", _show_setup, true))
	column.add_child(AppTheme.paragraph("Les quiz de chaque période restent accessibles à la fin des cours. La frise fonctionne entièrement hors ligne.", 14))

func _show_setup() -> void:
	if mode == "play":
		resume_anchors = anchors.duplicate()
	mode = "setup"
	selected_card = ""
	_message = ""
	_refresh()

func _setup() -> void:
	var lobby := preload("res://scenes/games/frieze_lobby.gd").new()
	lobby.controller = self
	lobby.size_flags_vertical = SIZE_EXPAND_FILL
	_content.add_child(lobby)

func open_collection() -> void:
	mode = "collection"
	lobby_scroll = 0
	_refresh()

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
	var cards := repository.build_deck(selection, game_mode, 2147483647 if all_events else requested_events, progress_repository.review_ids())
	if cards.is_empty():
		return
	resume_anchors = anchors.duplicate()
	session = FriezeSession.new(selection, cards, -1, game_mode)
	session.normals_at_start = progress_repository.owned_normals()
	mode = "play"
	selected_card = ""
	_board_position = 0
	_message = ""
	_refresh()


func _place(id: String, slot_id: String) -> void:
	if session.place(id, slot_id):
		play_sound(session.period_status(slot_id) == "correct")
		selected_card = ""
		_message = ""
		_refresh()

func select_card(id: String) -> void:
	if session.game_mode == "markers":
		screen.open_date(id)
		return
	var previous := selected_card
	selected_card = "" if previous == id else id
	screen.select_face(previous, selected_card)

func slot_clicked(slot_id: String) -> void:
	if session.locked(slot_id):
		return
	if selected_card != "":
		_place(selected_card, slot_id)
	elif session.placements.has(slot_id):
		select_card(session.placements[slot_id])

func answer(year: int) -> void:
	var was_start := session.phase == "start"
	var correct := session.answer_boundary(year)
	if correct:
		boundary_feedback = ("Début validé" if was_start else "Fin validée") + " · " + ChronologyRepository.date_label(year)
	play_sound(correct)
	_message = "" if correct else "Ce n’est pas la bonne borne. Essayez une autre carte."
	_refresh()

func validate_board() -> void:
	if session.validate():
		progress_repository.finish_frieze(session)
		play_sound(true)
		review_all = session.wrong_slots.is_empty()
		review_original = false
		comparison_index = 0
		selected_card = ""
		_refresh()
