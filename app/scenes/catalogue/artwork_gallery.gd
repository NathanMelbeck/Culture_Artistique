class_name ArtworkGallery
extends VBoxContainer

signal course_requested(period: String, chapter: String)
var repository: CourseRepository
var course_period := ""
var _grids: Array[GridContainer] = []

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	resized.connect(_fit)

func display(works: Array, grouped: bool) -> void:
	_grids.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if grouped:
		for category in repository.artworks.categories:
			var section := works.filter(func(w): return w.category == category)
			if not section.is_empty():
				add_child(AppTheme.label(repository.artworks.categories[category], 25, AppTheme.FOREST, true))
				_add_grid(section)
	elif not works.is_empty():
		_add_grid(works)
	_fit()

func _add_grid(works: Array) -> void:
	var grid := GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	add_child(grid)
	_grids.append(grid)
	for work in works:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SURFACE, AppTheme.LINE, 10))
		grid.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 7)
		panel.add_child(column)
		var photo := TextureButton.new()
		photo.name = "Artwork_" + work.id
		photo.texture_normal = load(work.thumbnail)
		photo.ignore_texture_size = true
		photo.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		photo.custom_minimum_size.y = 148
		photo.tooltip_text = work.title
		photo.accessibility_name = "Ouvrir la notice · " + work.title
		photo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		photo.pressed.connect(open_detail.bind(work))
		column.add_child(photo)
		column.add_child(AppTheme.eyebrow(work.kind.to_upper()))
		var title := AppTheme.quiet_button(work.title)
		title.alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.pressed.connect(open_detail.bind(work))
		column.add_child(title)
		column.add_child(AppTheme.paragraph(work.date + " · " + work.provenance, 14))

func _fit() -> void:
	for grid in _grids:
		grid.columns = clampi(int((size.x + 16) / 260), 1, mini(4, grid.get_child_count()))

func open_detail(work: Dictionary) -> void:
	var detail := preload("res://scenes/catalogue/artwork_detail.gd").new()
	detail.repository = repository
	detail.work = work
	detail.course_period = course_period
	detail.course_requested.connect(course_requested.emit)
	add_child(detail)
	var bounds := get_viewport_rect().size - Vector2(40, 60)
	detail.popup_centered(Vector2i(minf(850, bounds.x), minf(800, bounds.y)))
