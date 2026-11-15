extends VBoxContainer

signal catalogue_requested
signal quiz_requested
var repository: CourseRepository
var course: Dictionary
var chapter_index := 0
var scroll_position := 0
var quiz_resume_available := false
var _sidebar: VBoxContainer
var _picker: OptionButton
var _buttons: Array[Button] = []
var _scroll: ScrollContainer
var _blocks: VBoxContainer
var _previous: Button
var _next: Button
var _scroll_margin: MarginContainer
var _chapter_heading: Label

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var header := HBoxContainer.new()
	add_child(header)
	var back := AppTheme.quiet_button("←  Tous les cours")
	back.name = "CourseCatalogueBack"
	back.pressed.connect(func() -> void: catalogue_requested.emit())
	header.add_child(back)
	var context := AppTheme.label("Antiquité / " + course["title"], 13, AppTheme.MUTED)
	context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(context)
	if quiz_resume_available:
		var resume := AppTheme.quiet_button("Retour au quiz  →")
		resume.name = "ResumeCourseQuiz"
		resume.pressed.connect(func() -> void: quiz_requested.emit())
		header.add_child(resume)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	add_child(body)
	_sidebar = VBoxContainer.new()
	_sidebar.custom_minimum_size.x = 235
	body.add_child(_sidebar)
	_sidebar.add_child(AppTheme.label("Dans ce cours", 23, AppTheme.FOREST, true))
	for index in course["chapters"].size():
		var item: Dictionary = course["chapters"][index]
		var button := AppTheme.quiet_button("%02d  %s" % [index + 1, item["title"]])
		button.name = "Chapter_" + item["id"]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.tooltip_text = item["title"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(show_chapter.bind(index))
		_sidebar.add_child(button)
		_buttons.append(button)
	var objective := AppTheme.paragraph("À la fin du parcours, un quiz vous aide à vérifier ce que vous avez compris.", 13)
	_sidebar.add_child(objective)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(content)
	_picker = OptionButton.new()
	_picker.name = "ChapterPicker"
	_picker.fit_to_longest_item = false
	_picker.custom_minimum_size.y = 42
	for index in course["chapters"].size():
		_picker.add_item("%02d / %s" % [index + 1, course["chapters"][index]["title"]])
	_picker.item_selected.connect(show_chapter)
	content.add_child(_picker)
	_scroll = ScrollContainer.new()
	_scroll.name = "CourseReadingScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	content.add_child(_scroll)
	_scroll_margin = AppTheme.margin(4)
	_scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_scroll_margin)
	_blocks = VBoxContainer.new()
	_blocks.name = "CourseBlocks"
	_blocks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_blocks.add_theme_constant_override("separation", 24)
	_scroll_margin.add_child(_blocks)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	add_child(footer)
	_previous = Button.new()
	_previous.name = "PreviousChapter"
	_previous.text = "←  Précédent"
	_previous.custom_minimum_size.y = 44
	_previous.pressed.connect(func() -> void: show_chapter(chapter_index - 1))
	footer.add_child(_previous)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(space)
	_next = Button.new()
	_next.name = "NextChapter"
	_next.custom_minimum_size.y = 44
	_next.pressed.connect(_advance)
	footer.add_child(_next)
	resized.connect(_adapt)
	var initial_scroll := scroll_position
	show_chapter(chapter_index)
	_adapt.call_deferred()
	_restore_scroll.call_deferred(initial_scroll)

func show_chapter(index: int) -> void:
	chapter_index = clampi(index, 0, course["chapters"].size() - 1)
	var chapter: Dictionary = course["chapters"][chapter_index]
	for child in _blocks.get_children():
		_blocks.remove_child(child)
		child.queue_free()
	_blocks.add_child(AppTheme.eyebrow("CHAPITRE %02d / %02d" % [chapter_index + 1, course["chapters"].size()]))
	_chapter_heading = AppTheme.label(chapter["title"], 37, AppTheme.FOREST, true)
	_chapter_heading.name = "CourseChapterTitle"
	_chapter_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blocks.add_child(_chapter_heading)
	_blocks.add_child(CourseBlock.prose(chapter["intro"], 20, AppTheme.MUTED))
	if chapter_index == 0:
		_blocks.add_child(CourseBlock.build({"type": "callout", "title": "Ce que vous allez apprendre", "text": "\n".join(course["objectives"])}, repository))
	for block in chapter["blocks"]:
		_blocks.add_child(CourseBlock.build(block, repository))
	if chapter_index == course["chapters"].size() - 1:
		_add_references()
	_picker.select(chapter_index)
	_previous.disabled = chapter_index == 0
	_next.text = "Vérifier mes connaissances  →" if chapter_index == course["chapters"].size() - 1 else "Continuer  →"
	_scroll.scroll_vertical = 0
	_update_navigation()
	_adapt.call_deferred()

func _add_references() -> void:
	_blocks.add_child(AppTheme.label("Autres ressources", 28, AppTheme.FOREST, true))
	_blocks.add_child(AppTheme.paragraph("Les ressources suivantes ouvrent le navigateur externe. Le cours reste disponible sans connexion.", 14))
	for reference in course.get("references", []):
		var button := AppTheme.quiet_button(reference["title"] + "  ↗")
		button.name = "CourseReference_" + str(_blocks.get_child_count())
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.tooltip_text = reference["title"] + "\nInternet requis · " + reference["url"]
		button.pressed.connect(func() -> void:
			var error := OS.shell_open(reference["url"])
			if error != OK:
				var message := AcceptDialog.new()
				message.dialog_text = "Impossible d’ouvrir le navigateur.\n" + reference["url"]
				add_child(message)
				message.popup_centered()
		)
		_blocks.add_child(button)
		_blocks.add_child(AppTheme.paragraph(reference["note"] + " · Internet requis", 12))

func _advance() -> void:
	if chapter_index == course["chapters"].size() - 1:
		quiz_requested.emit()
	else:
		show_chapter(chapter_index + 1)

func _update_navigation() -> void:
	for index in course["chapters"].size():
		var button := _buttons[index]
		var active: bool = index == chapter_index
		button.add_theme_color_override("font_color", AppTheme.SURFACE if active else AppTheme.FOREST)
		button.add_theme_stylebox_override("normal", AppTheme.box(AppTheme.FOREST if active else Color.TRANSPARENT, Color.TRANSPARENT, 6, 0))

func _adapt() -> void:
	if not is_instance_valid(_sidebar):
		return
	_sidebar.visible = size.x >= 1050
	_picker.visible = not _sidebar.visible
	var reading_width := _scroll.size.x
	var inset := maxi(6, int((reading_width - 850) / 2))
	_scroll_margin.add_theme_constant_override("margin_left", inset)
	_scroll_margin.add_theme_constant_override("margin_right", inset + 6)

func get_view_state() -> Dictionary:
	return {"chapter": chapter_index, "scroll": _scroll.scroll_vertical}

func _restore_scroll(value: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll.scroll_vertical = value
