extends Button

@export var route := "courses"
@export var heading := "Les cours"
@export var description := "Des civilisations aux styles : comprendre les formes et leurs histoires."
@export var kicker := "01 / APPRENDRE"
@export var icon_path := "res://assets/icons/book.svg"
@export var featured := false

func _ready() -> void:
	tooltip_text = heading + " — " + description
	var color := AppTheme.SURFACE if featured else AppTheme.FOREST
	var secondary := AppTheme.LIGHT_TEXT if featured else AppTheme.MUTED
	if featured:
		add_theme_stylebox_override("normal", AppTheme.box(AppTheme.FOREST, AppTheme.FOREST, 12))
		add_theme_stylebox_override("hover", AppTheme.box(Color("304e44"), Color("304e44"), 12))
		add_theme_stylebox_override("pressed", AppTheme.box(Color("1c322c"), Color("1c322c"), 12))
	else:
		add_theme_stylebox_override("normal", AppTheme.box(AppTheme.SURFACE, AppTheme.LINE, 12))
	var inset := AppTheme.margin(28)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inset)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_child(column)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var tag := AppTheme.label(kicker, 11, secondary)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	var symbol := TextureRect.new()
	symbol.texture = load(icon_path)
	symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.custom_minimum_size = Vector2(22, 22)
	symbol.modulate = Color("d7e1d3") if featured else Color.WHITE
	if featured:
		# Une icône blanche utilise la même forme, sans modifier l'illustration d'un objet.
		symbol.self_modulate = Color(4.0, 4.0, 4.0, 1.0)
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(symbol)
	column.add_child(AppTheme.spacer(8, true))
	var title := AppTheme.label(heading, 32, color, true)
	column.add_child(title)
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bottom)
	var copy := AppTheme.paragraph(description, 14, secondary)
	bottom.add_child(copy)
	var arrow := AppTheme.label("→", 24, color)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_child(arrow)
