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
		"column_example":
			return _column_example(block, repository)
		"annotated_image":
			return _figure(block.get("media", ""), repository, block)
		"furniture_example":
			return _furniture_example(block, repository)
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
		"source":
			return _source(block)
		"image":
			return _figure(block.get("media", ""), repository, block)
	return AppTheme.paragraph("Bloc de cours indisponible.")

static func _furniture_example(block: Dictionary, repository: CourseRepository) -> Control:
	var column := VBoxContainer.new()
	column.name = "FurnitureExample_" + block.get("id", "")
	column.add_theme_constant_override("separation", 16)
	column.add_child(AppTheme.divider())
	column.add_child(AppTheme.eyebrow(block.get("status_label", "EXEMPLE DE MOBILIER").to_upper()))
	var title := AppTheme.label(block.get("title", ""), 27, AppTheme.FOREST, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	column.add_child(prose(block.get("description", "")))
	column.add_child(_figure(block.get("media", ""), repository))
	column.add_child(AppTheme.eyebrow("CARACTÉRISTIQUES À OBSERVER"))
	for characteristic in block.get("characteristics", []):
		column.add_child(prose("•  " + characteristic, 17))
	var reference: Dictionary = block.get("reference", {})
	column.add_child(_source(reference))
	return column

static func _column_example(block: Dictionary, repository: CourseRepository) -> Control:
	var column := VBoxContainer.new()
	column.name = "ColumnExample_" + block["id"]
	column.add_theme_constant_override("separation", 16)
	column.add_child(AppTheme.divider())
	var heading := AppTheme.label(block["title"], 29, AppTheme.FOREST, true)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)
	column.add_child(prose(block["description"]))
	column.add_child(_figure(block["media"], repository, block))
	column.add_child(AppTheme.eyebrow("POUR RECONNAÎTRE CE TYPE"))
	for cue in block["cues"]:
		column.add_child(prose("•  " + cue, 17))
	return column

static func _figure(id: String, repository: CourseRepository, options: Dictionary = {}) -> Control:
	var figure := CourseFigure.new()
	figure.media_id = id
	figure.media = repository.get_media(id).duplicate(true)
	figure.texture = repository.get_texture(id)
	if options.has("region") and figure.texture != null:
		var region: Array = options["region"]
		var atlas := AtlasTexture.new()
		atlas.atlas = figure.texture
		atlas.region = Rect2(region[0] * figure.texture.get_width(), region[1] * figure.texture.get_height(), region[2] * figure.texture.get_width(), region[3] * figure.texture.get_height())
		figure.texture = atlas
	if options.has("caption"):
		figure.media["caption"] = options["caption"]
		figure.media["alt"] = options.get("alt", options["caption"])
	figure.show_caption = options.get("show_caption", true)
	figure.markers = options.get("markers", [])
	figure.display_height = options.get("display_height", 0.0)
	return figure

static func _source(block: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SAGE, AppTheme.LINE, 10))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(AppTheme.eyebrow("SOURCE DOCUMENTÉE"))
	column.add_child(AppTheme.paragraph(block.get("title", ""), 19))
	column.add_child(prose(block.get("text", ""), 17))
	var button := AppTheme.quiet_button("Consulter la source  ↗  · Internet requis")
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.tooltip_text = block.get("url", "")
	button.pressed.connect(func() -> void: OS.shell_open(block.get("url", "")))
	column.add_child(button)
	return panel
