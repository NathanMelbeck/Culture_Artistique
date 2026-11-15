extends VBoxContainer

signal chapter_requested(id: String)
signal reader_requested
signal restart_requested
var course: Dictionary
var repository: CourseRepository
var progress_repository: ProgressRepository
var session: QuizSession
var _scroll: ScrollContainer
var _content: VBoxContainer

func _ready() -> void:
	if session == null:
		session = QuizSession.new(course.get("quiz", []))
	var back := AppTheme.quiet_button("←  Revenir au cours : " + course["title"])
	back.name = "QuizBackToCourse"
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: reader_requested.emit())
	add_child(back)
	_scroll = ScrollContainer.new()
	_scroll.name = "CourseQuizScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)
	var inset := AppTheme.margin(8)
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(inset)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 18)
	inset.add_child(_content)
	_render()

func _render() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if session.finished:
		_show_result()
		return
	var question := session.current()
	_content.add_child(AppTheme.eyebrow("VÉRIFIER MES CONNAISSANCES / %s" % course["title"].to_upper()))
	_content.add_child(AppTheme.label("Question %d / %d" % [session.index + 1, session.questions.size()], 13, AppTheme.MUTED))
	var title := AppTheme.label(question["prompt"], 31, AppTheme.FOREST, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(title)
	if question.has("media"):
		_content.add_child(CourseBlock.build({"type": "image", "media": question["media"]}, repository))
	var choices: Array = question["choices"]
	for index in choices.size():
		var button := Button.new()
		button.name = "Answer_" + str(index)
		button.text = "%s  %s" % [char(65 + index), choices[index]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 56
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_answer.bind(index))
		if session.selected != -1:
			button.disabled = true
			if index == int(question["correct"]):
				button.text = "✓  " + button.text
				button.add_theme_stylebox_override("disabled", AppTheme.box(AppTheme.SAGE, Color("8b9f85")))
				button.add_theme_color_override("font_disabled_color", AppTheme.FOREST)
			elif index == session.selected:
				button.text = "×  " + button.text
				button.add_theme_stylebox_override("disabled", AppTheme.box(Color("f1e6da"), AppTheme.BRONZE))
				button.add_theme_color_override("font_disabled_color", AppTheme.FOREST)
		_content.add_child(button)
	if session.selected != -1:
		var correct: bool = session.selected == int(question["correct"])
		var feedback := CourseBlock.build({"type": "callout", "title": "Bonne réponse" if correct else "Comprendre la correction", "text": question["explanation"]}, repository)
		feedback.name = "AnswerExplanation"
		_content.add_child(feedback)
		var review := AppTheme.quiet_button("Relire le chapitre correspondant  →")
		review.name = "ReviewQuestionChapter"
		review.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		review.pressed.connect(func() -> void: chapter_requested.emit(question["chapter"]))
		_content.add_child(review)
	var next := Button.new()
	next.name = "QuizNext"
	next.text = "Voir le résultat  →" if session.index == session.questions.size() - 1 else "Question suivante  →"
	next.custom_minimum_size.y = 46
	next.size_flags_horizontal = Control.SIZE_SHRINK_END
	next.disabled = session.selected == -1
	next.pressed.connect(func() -> void:
		session.advance()
		_render()
		_scroll.scroll_vertical = 0
	)
	_content.add_child(next)

func _answer(index: int) -> void:
	if session.selected != -1:
		return
	session.answer(index)
	_render()
	await get_tree().process_frame
	var feedback := _content.find_child("AnswerExplanation", true, false) as Control
	if feedback != null:
		_scroll.ensure_control_visible(feedback)
	var next := _content.find_child("QuizNext", true, false) as Button
	if next != null:
		next.grab_focus()

func _show_result() -> void:
	progress_repository.save_quiz(course["id"], session.score, session.questions.size())
	_content.add_child(AppTheme.eyebrow("VÉRIFICATION TERMINÉE / %s" % course["title"].to_upper()))
	var score := AppTheme.label("%d / %d réponses justes" % [session.score, session.questions.size()], 39, AppTheme.FOREST, true)
	score.name = "QuizResult"
	score.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(score)
	_content.add_child(CourseBlock.prose("Les chapitres lus et les réponses justes sont deux informations distinctes. Reprenez les notions qui vous ont posé problème, puis essayez à nouveau.", 18))
	if session.mistakes.is_empty():
		_content.add_child(CourseBlock.build({"type": "callout", "title": "Les liens sont compris", "text": "Toutes les réponses sont justes. Continuez à les justifier en observant les œuvres et leurs notices."}, repository))
	else:
		_content.add_child(AppTheme.label("À retravailler", 28, AppTheme.FOREST, true))
		for chapter_id in session.mistakes:
			for chapter in course["chapters"]:
				if chapter["id"] == chapter_id:
					var review := AppTheme.quiet_button(chapter["title"] + "  →")
					review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					review.pressed.connect(func() -> void: chapter_requested.emit(chapter_id))
					_content.add_child(review)
	var retry := Button.new()
	retry.name = "QuizRetry"
	retry.text = "Recommencer le quiz"
	retry.custom_minimum_size.y = 48
	retry.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	retry.pressed.connect(func() -> void: restart_requested.emit())
	_content.add_child(retry)
	var best := progress_repository.get_course(course["id"])
	_content.add_child(AppTheme.label("Meilleur résultat enregistré : %d / %d" % [best.get("quiz_best", 0), session.questions.size()], 13, AppTheme.MUTED))
