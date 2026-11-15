extends Control

const Card = preload("res://scripts/timeline_card.gd")
const INK := Color("203938")
const MUTED := Color("6a756e")
const PAPER := Color("f7f3eb")
const ACCENT := Color("a34f36")
const LINE := Color("deded3")
const GREEN := Color("39705c")

var catalog: Dictionary = {}
var lessons: Array = []
var progress: Dictionary = {"read": [], "quiz_done": false, "quiz_best": 0, "timeline_done": false}
var save_path := "user://progress.json"
var save_error := ""
var active_page := "courses"
var lesson_index := 0
var quiz_index := 0
var quiz_score := 0
var quiz_answer := -1
var quiz_finished := false
var placements: Array = ["", "", ""]
var selected_card := ""
var timeline_message := ""
var timeline_success := false
var page: VBoxContainer
var progress_text: Label
var serif: SystemFont

func _ready() -> void:
	# Une distribution portable conserve ses résultats à côté de l'exécutable.
	# En développement, le dossier du projet évite d'écrire près du moteur installé.
	var data_dir := OS.get_executable_path().get_base_dir().path_join("data")
	if not ProjectSettings.globalize_path("res://").begins_with(OS.get_executable_path().get_base_dir()):
		data_dir = ProjectSettings.globalize_path("res://.local")
	save_path = data_dir.path_join("progress.json")
	if "--self-test" in OS.get_cmdline_user_args():
		save_path = "res://tests/.test-progress.json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/catalog.json"))
	if not parsed is Dictionary or not parsed.has("lessons"):
		push_error("Catalogue absent ou invalide.")
		return
	catalog = parsed
	lessons = catalog["lessons"]
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "DejaVu Serif"])
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 18
	theme = ui_theme
	_load_progress()
	render()
	get_window().show()
	if "--verify-build" in OS.get_cmdline_user_args():
		_verify_distribution.call_deferred()

func _verify_distribution() -> void:
	# Vérification du paquet livré, depuis son propre dossier et sans source externe.
	var valid := lessons.size() == 3
	for lesson in lessons:
		valid = valid and ResourceLoader.exists(str(lesson["image"]))
	save_path = OS.get_executable_path().get_base_dir().path_join("data/verification.json")
	_save_progress()
	valid = valid and save_error.is_empty() and FileAccess.file_exists(save_path)
	print("PORTABLE: catalogue=%d, images locales, sauvegarde=%s" % [lessons.size(), str(valid)])
	get_tree().quit(0 if valid else 1)

func _style(color: Color, radius: int = 12, padding: int = 18, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	if border.a > 0:
		box.set_border_width_all(1)
		box.border_color = border
	return box

func _label(text: String, font_size: int = 18, color: Color = INK, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return label

func _title(text: String, font_size: int = 44) -> Label:
	var label := _label(text, font_size)
	label.add_theme_font_override("font", serif)
	return label

func _vbox(spacing: int = 16) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", spacing)
	return box

func _hbox(spacing: int = 16) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", spacing)
	return box

func _button(text: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_pressed_color", Color.WHITE if primary else INK)
	button.add_theme_stylebox_override("normal", _style(INK if primary else Color.WHITE, 9, 14, Color.TRANSPARENT if primary else LINE))
	button.add_theme_stylebox_override("hover", _style(Color("345550") if primary else Color("eee7db"), 9, 14))
	button.add_theme_stylebox_override("pressed", _style(Color("456a60") if primary else Color("e2d7c5"), 9, 14))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 9, 0, ACCENT))
	button.pressed.connect(callback)
	return button

func _panel(color: Color = Color.WHITE, padding: int = 22) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color, 14, padding, LINE))
	return panel

func _spacer(parent: Control) -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

func render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := ColorRect.new()
	background.color = PAPER
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var layout := _hbox(0)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	_build_sidebar(layout)
	var margins := MarginContainer.new()
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margins.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 28)
	layout.add_child(margins)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	page = _vbox(22)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	var header := _hbox()
	header.add_child(_label("CULTURE ARTISTIQUE   /   BMA ÉBÉNISTERIE", 14, MUTED))
	var spring := Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spring)
	header.add_child(_label("●  Disponible hors ligne", 15, GREEN))
	page.add_child(header)
	match active_page:
		"courses": _build_course()
		"quiz": _build_quiz()
		"timeline": _build_timeline()
	page.add_child(_label("PROTOTYPE GODOT  •  Illustrations schématiques originales  •  Sauvegarde sur cet ordinateur", 13, MUTED, true))
	if not save_error.is_empty():
		page.add_child(_label(save_error, 16, ACCENT, true))

func _build_sidebar(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 238
	panel.add_theme_stylebox_override("panel", _style(INK, 0, 24))
	parent.add_child(panel)
	var column := _vbox(16)
	panel.add_child(column)
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/icon.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(58, 58)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(logo)
	var brand := _label("Atelier\ndes Époques", 30, Color("f4e9d6"))
	brand.add_theme_font_override("font", serif)
	column.add_child(brand)
	column.add_child(_label("REGARDER. COMPRENDRE.\nRECONNAÎTRE.", 12, Color("a8bdb0")))
	var gap := Control.new()
	gap.custom_minimum_size.y = 30
	column.add_child(gap)
	var entries := [["courses", "01   Les cours"], ["quiz", "02   Quiz visuel"], ["timeline", "03   La frise"]]
	for entry in entries:
		var nav := _button(str(entry[1]), navigate.bind(str(entry[0])))
		nav.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nav.add_theme_color_override("font_color", Color("fff6e5"))
		nav.add_theme_color_override("font_hover_color", Color.WHITE)
		nav.add_theme_stylebox_override("normal", _style(Color("3e5851") if active_page == entry[0] else INK, 8, 14))
		nav.add_theme_stylebox_override("hover", _style(Color("49665b"), 8, 14))
		column.add_child(nav)
	_spacer(column)
	column.add_child(_label("VOTRE PARCOURS", 12, Color("a8bdb0")))
	var completed: int = progress["read"].size() + int(progress["quiz_done"]) + int(progress["timeline_done"])
	progress_text = _label("%d / 5 activités" % completed, 24, Color("f4e9d6"))
	column.add_child(progress_text)
	var bar := ProgressBar.new()
	bar.max_value = 5
	bar.value = completed
	bar.show_percentage = false
	bar.custom_minimum_size.y = 6
	bar.add_theme_stylebox_override("background", _style(Color("486057"), 3, 0))
	bar.add_theme_stylebox_override("fill", _style(Color("e9bc85"), 3, 0))
	column.add_child(bar)
	column.add_child(_label("Progression enregistrée\nlocalement, sans compte.", 14, Color("a8bdb0")))

func navigate(destination: String) -> void:
	active_page = destination
	render()

func _build_course() -> void:
	page.add_child(_title("Apprendre à regarder."))
	page.add_child(_label("Trois étapes pour relier les époques, les formes et le mobilier.", 20, MUTED, true))
	var tabs := _hbox(12)
	for i in lessons.size():
		var lesson: Dictionary = lessons[i]
		var done := "  ✓" if lesson["id"] in progress["read"] else ""
		var tab := _button("%02d  %s%s" % [i + 1, lesson["title"], done], _select_lesson.bind(i), i == lesson_index)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tab)
	page.add_child(tabs)
	var data: Dictionary = lessons[lesson_index]
	var row := _hbox(24)
	page.add_child(row)
	var text_panel := _panel()
	text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_panel.size_flags_stretch_ratio = 1.6
	row.add_child(text_panel)
	var text_column := _vbox(14)
	text_panel.add_child(text_column)
	text_column.add_child(_label("LE COURS  /  %02d" % (lesson_index + 1), 13, ACCENT))
	text_column.add_child(_title(str(data["title"]), 32))
	text_column.add_child(_label(str(data["dates"]), 15, MUTED, true))
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.selection_enabled = true
	body.text = str(data["body"])
	body.add_theme_color_override("default_color", INK)
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_font_size_override("bold_font_size", 18)
	text_column.add_child(body)
	var done: bool = data["id"] in progress["read"]
	text_column.add_child(_button("✓  Cours marqué comme lu" if done else "Marquer ce cours comme lu", mark_read, not done))
	var visual_column := _vbox(16)
	visual_column.custom_minimum_size.x = 320
	visual_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(visual_column)
	visual_column.add_child(_art_panel(data, 245))
	var clues := _panel(Color("ebe6d9"), 18)
	visual_column.add_child(clues)
	var clues_content := _vbox(8)
	clues.add_child(clues_content)
	clues_content.add_child(_label("LES INDICES À OBSERVER", 12, ACCENT))
	clues_content.add_child(_label(str(data["clues"]), 18, INK, true))
	visual_column.add_child(_button("S'entraîner avec les images →", navigate.bind("quiz"), true))
	var source := _button("Ouvrir la référence ↗  ·  Internet", _open_reference.bind(str(data["source_url"])))
	source.tooltip_text = str(data["source_title"]) + " — ouvre le navigateur externe."
	visual_column.add_child(source)

func _art_panel(data: Dictionary, image_height: int, show_caption: bool = true) -> PanelContainer:
	var panel := _panel(Color("efe8dd"), 14)
	var column := _vbox(10)
	panel.add_child(column)
	var image := TextureRect.new()
	image.texture = load(str(data["image"]))
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size.y = image_height
	column.add_child(image)
	if show_caption:
		column.add_child(_label(str(data["object"]), 20, INK, true))
		column.add_child(_label(str(data["caption"]), 14, MUTED, true))
	return panel

func _select_lesson(index: int) -> void:
	lesson_index = index
	render()

func mark_read() -> void:
	var id: String = lessons[lesson_index]["id"]
	if id not in progress["read"]:
		progress["read"].append(id)
	_save_progress()
	render()

func _build_quiz() -> void:
	page.add_child(_title("L'œil fait la différence."))
	page.add_child(_label("Repère un détail, choisis une réponse, puis découvre l'explication.", 20, MUTED, true))
	if quiz_finished:
		var result := _panel()
		page.add_child(result)
		var column := _vbox(18)
		result.add_child(column)
		column.add_child(_label("SESSION TERMINÉE", 14, ACCENT))
		column.add_child(_title("%d / 3 bonnes réponses" % quiz_score, 38))
		column.add_child(_label("Les indices aident à décrire un meuble. Pour identifier une pièce réelle, il faut croiser forme, construction, provenance et matériaux.", 22, INK, true))
		column.add_child(_label("Meilleur résultat enregistré : %d / 3" % int(progress["quiz_best"]), 18, GREEN))
		column.add_child(_button("Recommencer le quiz", restart_quiz, true))
		column.add_child(_button("Passer à la frise →", navigate.bind("timeline")))
		return
	var data: Dictionary = lessons[quiz_index]
	page.add_child(_label("QUESTION %02d / 03    •    OBSERVER LES FORMES" % (quiz_index + 1), 14, ACCENT))
	var row := _hbox(24)
	page.add_child(row)
	var art := _art_panel(data, 320, false)
	art.custom_minimum_size.x = 400
	row.add_child(art)
	var column := _vbox(16)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	column.add_child(_label(str(data["question"]), 28, INK, true))
	column.add_child(_label("Illustration schématique, sans valeur d'attribution.", 14, MUTED, true))
	for i in data["options"].size():
		var option := _button("%s   %s" % [char(65 + i), data["options"][i]], answer_quiz.bind(i))
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option.custom_minimum_size.y = 62
		if quiz_answer >= 0:
			option.disabled = true
			var correct: bool = i == int(data["answer"])
			option.add_theme_stylebox_override("disabled", _style(Color("e1ece2") if correct else Color("ebe7df"), 9, 14, GREEN if correct else LINE))
			option.add_theme_color_override("font_disabled_color", GREEN if correct else MUTED)
		column.add_child(option)
	if quiz_answer >= 0:
		var correct: bool = quiz_answer == int(data["answer"])
		column.add_child(_label("✓ Bien observé !" if correct else "À retenir pour la prochaine fois", 22, GREEN if correct else ACCENT, true))
		column.add_child(_label(str(data["explanation"]), 18, INK, true))
		column.add_child(_button("Voir mon résultat →" if quiz_index == 2 else "Question suivante →", next_question, true))

func answer_quiz(index: int) -> void:
	if quiz_answer >= 0 or quiz_finished or index < 0 or index >= lessons[quiz_index]["options"].size():
		return
	quiz_answer = index
	if index == int(lessons[quiz_index]["answer"]):
		quiz_score += 1
	render()

func next_question() -> void:
	if quiz_answer < 0 or quiz_finished:
		return
	if quiz_index == lessons.size() - 1:
		quiz_finished = true
		progress["quiz_done"] = true
		progress["quiz_best"] = maxi(int(progress["quiz_best"]), quiz_score)
		_save_progress()
	else:
		quiz_index += 1
		quiz_answer = -1
	render()

func restart_quiz() -> void:
	quiz_index = 0
	quiz_score = 0
	quiz_answer = -1
	quiz_finished = false
	render()

func _build_timeline() -> void:
	page.add_child(_title("Chaque époque à sa place."))
	page.add_child(_label(str(catalog["timeline"]["instruction"]), 20, MUTED, true))
	page.add_child(_label("Glisse les cartes dans les emplacements. Tu peux aussi sélectionner une carte puis cliquer sur un emplacement.", 16, INK, true))
	var heading := _hbox()
	heading.add_child(_label("PLUS ANCIEN", 13, ACCENT))
	var spring := Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spring)
	heading.add_child(_label("PLUS RÉCENT  →", 13, ACCENT))
	page.add_child(heading)
	var slots := _hbox(16)
	page.add_child(slots)
	for index in 3:
		var slot := _timeline_card(str(placements[index]), index)
		slot.accepts_drop = true
		slot.dropped.connect(place_card)
		slot.chosen.connect(_slot_clicked.bind(index))
		slots.add_child(slot)
	page.add_child(_label("CARTES À PLACER" + ("  ·  Carte sélectionnée : " + str(_lesson(selected_card)["title"]) if not selected_card.is_empty() else ""), 14, MUTED, true))
	var bank := _hbox(16)
	page.add_child(bank)
	for id in ["renaissance", "rome", "gothique"]:
		if id not in placements:
			var card := _timeline_card(id, -1)
			card.chosen.connect(_select_card)
			bank.add_child(card)
	var actions := _hbox()
	actions.add_child(_button("Vérifier ma frise", check_timeline, true))
	actions.add_child(_button("Recommencer", reset_timeline))
	page.add_child(actions)
	if not timeline_message.is_empty():
		page.add_child(_label(timeline_message, 20, GREEN if timeline_success else ACCENT, true))
	if timeline_success:
		page.add_child(_label("Les débuts permettent ici de classer les cartes. Le gothique et la Renaissance se chevauchent : la chronologie réelle est faite de transitions.", 18, INK, true))

func _timeline_card(id: String, slot_index: int) -> PanelContainer:
	var card := Card.new()
	card.card_id = id
	card.slot_index = slot_index
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 205 if slot_index >= 0 else 165)
	card.add_theme_stylebox_override("panel", _style(Color("e5ece2") if timeline_success else Color.WHITE, 12, 16, ACCENT if selected_card == id and not id.is_empty() else LINE))
	card.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 12, 0, ACCENT))
	var column := _vbox(8)
	card.add_child(column)
	if slot_index >= 0:
		column.add_child(_label("%02d  /  EMPLACEMENT" % (slot_index + 1), 12, MUTED))
	if id.is_empty():
		_spacer(column)
		var placeholder := _label("+\nDéposer une carte", 22, MUTED)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(placeholder)
		_spacer(column)
	else:
		var data := _lesson(id)
		var image := TextureRect.new()
		image.texture = load(str(data["image"]))
		image.custom_minimum_size.y = 85
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(image)
		column.add_child(_label(str(data["title"]), 23, INK, true))
		if timeline_success:
			column.add_child(_label(str(data["dates"]), 14, GREEN, true))
		else:
			column.add_child(_label("Glisser ou sélectionner" if slot_index < 0 else "Cliquer pour retirer", 13, MUTED))
	return card

func _lesson(id: String) -> Dictionary:
	for lesson in lessons:
		if lesson["id"] == id:
			return lesson
	return {}

func _select_card(id: String) -> void:
	selected_card = id
	render()

func _slot_clicked(id: String, index: int) -> void:
	if not selected_card.is_empty():
		place_card(selected_card, index)
	elif not id.is_empty():
		placements[index] = ""
		timeline_success = false
		timeline_message = ""
		render()

func place_card(id: String, index: int) -> void:
	if index < 0 or index > 2 or _lesson(id).is_empty():
		return
	var previous := placements.find(id)
	var displaced: String = placements[index]
	if previous >= 0:
		placements[previous] = displaced
	placements[index] = id
	selected_card = ""
	timeline_message = ""
	timeline_success = false
	render()

func check_timeline() -> void:
	if "" in placements:
		timeline_success = false
		timeline_message = "Il reste des emplacements vides : place les trois cartes avant de vérifier."
	elif placements == catalog["timeline"]["order"]:
		timeline_success = true
		timeline_message = "✓ Bien joué ! Rome antique → Gothique → Renaissance."
		progress["timeline_done"] = true
		_save_progress()
	else:
		timeline_success = false
		timeline_message = "Pas encore. Cherche d'abord l'Antiquité, puis compare les débuts des deux styles suivants."
	render()

func reset_timeline() -> void:
	placements = ["", "", ""]
	selected_card = ""
	timeline_message = ""
	timeline_success = false
	render()

func _save_progress() -> void:
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		save_error = "La progression ne peut pas être enregistrée dans ce dossier."
		push_warning(save_error)
		return
	file.store_string(JSON.stringify(progress, "\t"))
	file.close()
	save_error = ""

func _load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return
	var data: Variant = parser.data
	if not data is Dictionary:
		return
	if data.get("read") is Array:
		for id in data["read"]:
			if id is String and not _lesson(id).is_empty() and id not in progress["read"]:
				progress["read"].append(id)
	for key in ["quiz_done", "timeline_done"]:
		if data.get(key) is bool:
			progress[key] = data[key]
	if data.get("quiz_best") is float or data.get("quiz_best") is int:
		progress["quiz_best"] = clampi(int(data["quiz_best"]), 0, lessons.size())

func _open_reference(url: String) -> void:
	if url.begins_with("https://"):
		OS.shell_open(url)
