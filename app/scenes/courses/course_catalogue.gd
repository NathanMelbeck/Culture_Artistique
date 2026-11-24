extends VBoxContainer

signal course_requested(id: String)
var repository: CourseRepository
var progress_repository: ProgressRepository
var _grid: GridContainer
var _filter: OptionButton
var _courses: Array[Dictionary]

func _ready() -> void:
	_courses = repository.all()
	add_theme_constant_override("separation", 16)
	add_child(AppTheme.eyebrow("COMPRENDRE LES FORMES ET LEURS HISTOIRES"))
	add_child(AppTheme.label("Les cours par période", 43, AppTheme.FOREST, true))
	add_child(AppTheme.paragraph("Des cours rédigés pour apprendre à observer : repères historiques, arts, architecture et mobilier.", 17))
	var row := HBoxContainer.new()
	add_child(row)
	var chapters := 0
	for course in _courses:
		chapters += course["chapters"].size()
	var count := AppTheme.label("%d cours · %d chapitres · Quiz expliqués" % [_courses.size(), chapters], 13, AppTheme.MUTED)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(count)
	_filter = OptionButton.new()
	_filter.name = "CoursePeriodFilter"
	_filter.custom_minimum_size = Vector2(230, 44)
	_filter.add_item("Toutes les périodes")
	for course in _courses:
		_filter.add_item(course["title"])
		_filter.set_item_metadata(_filter.item_count - 1, course.id)
	for group in repository.groups:
		_filter.add_item(group.title)
		_filter.set_item_metadata(_filter.item_count - 1, group.id)
	_filter.item_selected.connect(func(_index: int) -> void: _show_courses())
	row.add_child(_filter)
	var scroll := ScrollContainer.new()
	scroll.name = "CatalogueScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.name = "CourseGrid"
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(_grid)
	resized.connect(_adapt)
	_show_courses()
	_adapt.call_deferred()

func _show_courses() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for index in _courses.size():
		if _filter.selected > 0 and _filter.get_selected_metadata() not in [_courses[index].id, _courses[index].group_id]:
			continue
		var course := _courses[index]
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SURFACE, AppTheme.LINE, 12))
		_grid.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 14)
		panel.add_child(column)
		var image := TextureRect.new()
		image.texture = repository.get_texture(course["cover_media"])
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size.y = 180
		column.add_child(image)
		column.add_child(AppTheme.eyebrow(repository.group_title(course.group_id).to_upper()))
		column.add_child(AppTheme.label(course["title"], 30, AppTheme.FOREST, true))
		column.add_child(AppTheme.label("%d chapitres · %d questions" % [course["chapters"].size(), course["quiz"].size()], 12, AppTheme.MUTED))
		var summary := AppTheme.paragraph(course["summary"], 16)
		summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(summary)
		var progress := progress_repository.get_course(course["id"])
		if progress.has("quiz_best"):
			column.add_child(AppTheme.label("Quiz : %d / %d" % [progress["quiz_best"], progress["quiz_total"]], 12, AppTheme.MUTED))
		var open := Button.new()
		open.name = "Open_" + course["id"]
		open.text = "Ouvrir le cours  →"
		open.custom_minimum_size.y = 46
		open.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		open.pressed.connect(func() -> void: course_requested.emit(course["id"]))
		column.add_child(open)
	_adapt()

func _adapt() -> void:
	if is_instance_valid(_grid):
		_grid.columns = clampi(_grid.get_child_count(), 1, 3) if size.x >= 1050 else 1
