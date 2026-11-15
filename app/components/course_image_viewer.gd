class_name CourseImageViewer
extends Window

var texture: Texture2D
var caption: String
var _scroll: ScrollContainer
var _image: TextureRect
var _percentage: Label
var _scale := 1.0
var _mode := "width"

func _ready() -> void:
	transient = true
	exclusive = true
	wrap_controls = false
	unresizable = false
	min_size = Vector2i(500, 350)
	var inset := AppTheme.margin(12)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(inset)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	inset.add_child(column)
	var toolbar := HBoxContainer.new()
	column.add_child(toolbar)
	for item in [["ZoomOut", "−", _zoom.bind(0.8)], ["ZoomIn", "+", _zoom.bind(1.25)], ["FitWidth", "Largeur", fit_width], ["FitPage", "Vue entière", fit_page], ["ActualSize", "100 %", _actual_size]]:
		var button := AppTheme.quiet_button(item[1])
		button.name = item[0]
		button.pressed.connect(item[2])
		toolbar.add_child(button)
	_percentage = AppTheme.label("", 13, AppTheme.MUTED)
	_percentage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(_percentage)
	var close := AppTheme.quiet_button("Fermer")
	close.name = "CloseImageViewer"
	close.pressed.connect(queue_free)
	toolbar.add_child(close)
	_scroll = ScrollContainer.new()
	_scroll.name = "ImageZoomScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	_image = TextureRect.new()
	_image.name = "ZoomedCourseImage"
	_image.texture = texture
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_scroll.add_child(_image)
	column.add_child(AppTheme.paragraph(caption, 13))
	close_requested.connect(queue_free)
	size_changed.connect(_refit.call_deferred)
	window_input.connect(func(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			queue_free()
	)

func fit_width() -> void:
	_mode = "width"
	_set_scale((_scroll.size.x - 20) / texture.get_width())

func fit_page() -> void:
	_mode = "page"
	_set_scale(minf((_scroll.size.x - 20) / texture.get_width(), (_scroll.size.y - 20) / texture.get_height()))

func _actual_size() -> void:
	_mode = "manual"
	_set_scale(1)

func _zoom(factor: float) -> void:
	_mode = "manual"
	_set_scale(_scale * factor)

func _refit() -> void:
	if not is_instance_valid(_scroll):
		return
	if _mode == "width":
		fit_width()
	elif _mode == "page":
		fit_page()

func _set_scale(value: float) -> void:
	_scale = clampf(value, 0.05, 4)
	_image.custom_minimum_size = texture.get_size() * _scale
	_image.size = _image.custom_minimum_size
	_percentage.text = "%d %%" % roundi(_scale * 100)
