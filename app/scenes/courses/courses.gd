extends VBoxContainer

signal destination_requested(route: String)
const CATALOGUE = preload("res://scenes/courses/course_catalogue.gd")
const READER = preload("res://scenes/courses/course_reader.gd")
const QUIZ = preload("res://scenes/courses/course_quiz.gd")
var repository: CourseRepository
var progress_repository: ProgressRepository
var view_state: Dictionary = {}
var mode := "catalogue"
var selected_id := ""
var _child: Control
var _reader_state: Dictionary = {}
var _quiz_session: QuizSession

func _ready() -> void:
	selected_id = view_state.get("course", "")
	_reader_state = view_state.get("reader", {})
	_quiz_session = view_state.get("quiz_session", null)
	if view_state.get("mode", "catalogue") == "catalogue" or repository.find(selected_id).is_empty():
		_show_catalogue()
	elif view_state.get("mode") == "quiz" and _quiz_session != null:
		_show_quiz()
	else:
		_show_reader()

func _replace(script: Script) -> Control:
	if is_instance_valid(_child):
		if mode == "reader":
			_reader_state = _child.get_view_state()
		remove_child(_child)
		_child.queue_free()
	_child = VBoxContainer.new()
	_child.set_script(script)
	_child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_child.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return _child

func _show_catalogue() -> void:
	var page := _replace(CATALOGUE)
	mode = "catalogue"
	page.repository = repository
	page.progress_repository = progress_repository
	page.course_requested.connect(_open_course)
	add_child(page)

func _open_course(id: String) -> void:
	if repository.find(id).is_empty():
		return
	if id != selected_id:
		_reader_state = {}
		_quiz_session = null
	selected_id = id
	_show_reader()

func _show_reader(chapter_id: String = "") -> void:
	var page := _replace(READER)
	mode = "reader"
	page.repository = repository
	page.course = repository.find(selected_id)
	page.chapter_index = _reader_state.get("chapter", 0)
	page.scroll_position = _reader_state.get("scroll", 0)
	if not chapter_id.is_empty():
		for index in page.course["chapters"].size():
			if page.course["chapters"][index]["id"] == chapter_id:
				page.chapter_index = index
				page.scroll_position = 0
	page.quiz_resume_available = _quiz_session != null
	page.catalogue_requested.connect(_show_catalogue)
	page.quiz_requested.connect(_show_quiz)
	add_child(page)

func _show_quiz() -> void:
	var page := _replace(QUIZ)
	mode = "quiz"
	page.repository = repository
	page.progress_repository = progress_repository
	page.course = repository.find(selected_id)
	if _quiz_session == null:
		_quiz_session = QuizSession.new(page.course.get("quiz", []))
	page.session = _quiz_session
	page.reader_requested.connect(_show_reader)
	page.chapter_requested.connect(_show_reader)
	page.restart_requested.connect(_restart_quiz)
	add_child(page)

func _restart_quiz() -> void:
	_quiz_session = null
	_show_quiz()

func get_view_state() -> Dictionary:
	if mode == "reader":
		_reader_state = _child.get_view_state()
	return {"mode": mode, "course": selected_id, "reader": _reader_state, "quiz_session": _quiz_session}
