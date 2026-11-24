class_name CourseFigure
extends VBoxContainer

var media: Dictionary
var texture: Texture2D
var media_id: String
var markers: Array = []
var show_caption := true
var display_height: float = 0.0
var _image: CourseMarkedTexture

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_image = CourseMarkedTexture.new()
	_image.markers = markers
	_image.name = "CourseFigure_" + media_id
	_image.texture = texture
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.tooltip_text = media.get("alt", "")
	if texture != null:
		_image.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_image.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_image.accept_event()
				_open_viewer()
		)
	add_child(_image)
	if not markers.is_empty():
		add_child(AppTheme.eyebrow("REPÈRES SUR L’IMAGE"))
		for index in markers.size():
			var marker: Dictionary = markers[index]
			var legend := CourseBlock.prose("[b]%s · %s[/b] — %s" % [String.chr(65 + index), marker["label"], marker["definition"]], 16)
			legend.name = "FigureLegend_" + str(index + 1)
			add_child(legend)
	if show_caption:
		add_child(AppTheme.paragraph(media.get("caption", ""), 14))
	var attribution: String = media.get("display_credit", "")
	if not attribution.is_empty():
		add_child(AppTheme.paragraph(attribution, 12))
	if media.get("visual_role", "") == "reference_diagram":
		var source := AppTheme.quiet_button("Source et licence  ↗  · Internet requis")
		source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		source.pressed.connect(func() -> void: OS.shell_open(media["source"]))
		add_child(source)
	var enlarge := AppTheme.quiet_button("Agrandir et zoomer  ↗")
	enlarge.name = "Enlarge_" + media_id
	enlarge.disabled = texture == null
	enlarge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	enlarge.pressed.connect(_open_viewer)
	add_child(enlarge)
	resized.connect(_resize_image)
	_resize_image.call_deferred()

func _resize_image() -> void:
	if texture == null:
		_image.custom_minimum_size.y = 140
		return
	if display_height > 0:
		_image.custom_minimum_size.y = display_height
		return
	# Maps and documentary plates use the entire column. Preserve their proportions
	# instead of squeezing portrait images into a short landscape frame.
	var width := minf(size.x, texture.get_width())
	var height := width * texture.get_height() / texture.get_width()
	_image.custom_minimum_size.y = height if media.get("full_width", false) else minf(height, 760)

func _open_viewer() -> void:
	var viewer := CourseImageViewer.new()
	viewer.name = "CourseImageViewer"
	viewer.texture = texture
	viewer.markers = markers
	viewer.caption = media.get("caption", "")
	viewer.title = media.get("title", "Illustration")
	add_child(viewer)
	var available := get_viewport_rect().size - Vector2(40, 60)
	viewer.popup_centered(Vector2i(minf(1160, available.x), minf(850, available.y)))
	if display_height > 0:
		viewer.fit_page.call_deferred()
	else:
		viewer.fit_width.call_deferred()
