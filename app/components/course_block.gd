class_name CourseBlock
extends RefCounted

static func prose(value: String, size: int = 18, color: Color = AppTheme.FOREST) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = value
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", size)
	label.add_theme_font_size_override("bold_font_size", size)
	label.add_theme_color_override("default_color", color)
	label.add_theme_constant_override("line_separation", 7)
	var normal := FontVariation.new()
	normal.base_font = AppTheme.BODY_FONT
	normal.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 450.0}
	var bold := FontVariation.new()
	bold.base_font = AppTheme.BODY_FONT
	bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700.0}
	label.add_theme_font_override("normal_font", normal)
	label.add_theme_font_override("bold_font", bold)
	return label

static func build(block: Dictionary, repository: CourseRepository) -> Control:
	match block.get("type", ""):
		"paragraph":
			return prose(block.get("text", ""))
		"heading":
			var heading := AppTheme.label(block.get("text", ""), 29, AppTheme.FOREST, true)
			heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			return heading
		"key_points":
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation", 12)
			for point in block.get("items", []):
				column.add_child(prose("•  " + point, 17))
			return column
		"callout":
			var panel := PanelContainer.new()
			panel.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SAGE, AppTheme.LINE, 10))
			var inset := AppTheme.margin(8)
			panel.add_child(inset)
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation", 12)
			inset.add_child(column)
			column.add_child(AppTheme.eyebrow(block.get("title", "À retenir").to_upper()))
			column.add_child(prose(block.get("text", ""), 17))
			return panel
		"image":
			return _figure(block.get("media", ""), repository)
	return AppTheme.paragraph("Bloc de cours indisponible.")

static func _figure(id: String, repository: CourseRepository) -> Control:
	var media := repository.get_media(id)
	var texture := repository.get_texture(id)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", AppTheme.box(Color("eeeee8"), AppTheme.LINE, 10))
	column.add_child(frame)
	var image := TextureRect.new()
	image.name = "CourseFigure_" + id
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size.y = minf(360.0, float(texture.get_height())) if texture != null else 140.0
	image.tooltip_text = media.get("alt", "")
	frame.add_child(image)
	if texture == null:
		frame.add_child(AppTheme.paragraph("Illustration indisponible ; le texte du cours reste accessible."))
	column.add_child(AppTheme.paragraph(media.get("caption", ""), 13))
	var bottom := HBoxContainer.new()
	column.add_child(bottom)
	var credit := AppTheme.paragraph("Support fourni · page %s" % media.get("source_page", "?"), 11)
	credit.tooltip_text = media.get("credit", "") + "\n" + media.get("rights", "")
	bottom.add_child(credit)
	var enlarge := AppTheme.quiet_button("Agrandir l’image  ↗")
	enlarge.name = "Enlarge_" + id
	enlarge.disabled = texture == null
	enlarge.add_theme_font_size_override("font_size", 12)
	enlarge.pressed.connect(func() -> void:
		var dialog := AcceptDialog.new()
		dialog.title = media.get("title", "Illustration du cours")
		var available := column.get_viewport_rect().size - Vector2(80, 100)
		var content := VBoxContainer.new()
		var full := TextureRect.new()
		full.texture = texture
		full.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		full.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		full.custom_minimum_size = Vector2(minf(980.0, available.x), minf(560.0, available.y - 120.0))
		content.add_child(full)
		content.add_child(AppTheme.paragraph(media.get("caption", ""), 13))
		dialog.add_child(content)
		column.add_child(dialog)
		dialog.confirmed.connect(dialog.queue_free)
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered()
	)
	bottom.add_child(enlarge)
	return column
