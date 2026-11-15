class_name CourseFigure
extends VBoxContainer

var media: Dictionary
var texture: Texture2D
var media_id: String
var _image: TextureRect

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_image = TextureRect.new()
	_image.name = "CourseFigure_" + media_id
	_image.texture = texture
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.tooltip_text = media.get("alt", "")
	add_child(_image)
	add_child(AppTheme.paragraph(media.get("caption", ""), 14))
	var attribution: String = media.get("display_credit", "")
	if not attribution.is_empty():
		add_child(AppTheme.paragraph(attribution, 12))
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
	# Maps and documentary plates use the entire column. Preserve their proportions
	# instead of squeezing portrait images into a short landscape frame.
	var width := minf(size.x, texture.get_width())
	var height := width * texture.get_height() / texture.get_width()
	_image.custom_minimum_size.y = height if media.get("full_width", false) else minf(height, 760)

func _open_viewer() -> void:
	var viewer := CourseImageViewer.new()
	viewer.name = "CourseImageViewer"
	viewer.texture = texture
	viewer.caption = media.get("caption", "")
	viewer.title = media.get("title", "Illustration")
	add_child(viewer)
	var available := get_viewport_rect().size - Vector2(40, 60)
	viewer.popup_centered(Vector2i(minf(1160, available.x), minf(850, available.y)))
	viewer.fit_width.call_deferred()
