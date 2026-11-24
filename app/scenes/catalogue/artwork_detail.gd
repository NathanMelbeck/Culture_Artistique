extends Window

signal course_requested(period: String, chapter: String)
var repository: CourseRepository
var work: Dictionary
var course_period := ""

func _ready() -> void:
	name = "ArtworkDetail"
	title = work.title
	transient = true
	exclusive = true
	min_size = Vector2i(400, 350)
	close_requested.connect(queue_free)
	var inset := AppTheme.margin(18)
	add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := VBoxContainer.new()
	inset.add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	column.add_child(AppTheme.eyebrow(repository.artworks.categories[work.category].to_upper() + "  /  " + work.kind))
	column.add_child(CourseBlock.prose("[b]" + work.title + "[/b]", 28))
	column.add_child(CourseBlock.prose(work.date + " · " + work.origin, 17))
	var media := repository.get_media(work.media)
	var figure := CourseFigure.new()
	figure.media_id = work.media
	figure.media = media
	figure.texture = repository.get_texture(work.media)
	figure.display_height = 265
	figure.show_caption = false
	column.add_child(figure)
	column.add_child(AppTheme.eyebrow(work.status_label.to_upper()))
	column.add_child(CourseBlock.prose(work.observation))
	if work.has("maker"):
		column.add_child(CourseBlock.prose(work.maker, 16))
	var techniques := PackedStringArray(work.materials + work.techniques)
	column.add_child(AppTheme.paragraph(" · ".join(techniques), 15))
	if work.has("materials_note"):
		column.add_child(AppTheme.paragraph(work.materials_note, 14))
	var url: String = work.get("source_url", media.source)
	if url.begins_with("https://"):
		var source := AppTheme.quiet_button("Voir la source  ↗")
		source.tooltip_text = url
		source.pressed.connect(func(): OS.shell_open(url))
		column.add_child(source)
	for period in work.periods:
		var chapter: String = work.course_chapters[period]
		if period == course_period and chapter == "catalogue":
			continue
		var link := AppTheme.quiet_button("Revoir dans le cours · " + str(repository.find(period).title))
		link.name = "ArtworkCourse_" + period
		link.pressed.connect(func():
			hide()
			course_requested.emit(period, chapter)
			queue_free())
		column.add_child(link)
	var close := AppTheme.quiet_button("Fermer la notice")
	close.name = "CloseArtwork"
	close.pressed.connect(queue_free)
	layout.add_child(close)
	close.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
