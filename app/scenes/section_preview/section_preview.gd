extends VBoxContainer

signal destination_requested(route: String)
var route := "courses"

func _ready() -> void:
	var courses := route == "courses"
	add_child(AppTheme.eyebrow("COURS" if courses else "JEUX"))
	add_child(AppTheme.label("Les cours arrivent bientôt." if courses else "À vous de jouer, bientôt.", 46, AppTheme.FOREST, true))
	add_child(AppTheme.paragraph("Les cours seront organisés par époque, civilisation et domaine artistique." if courses else "Retrouvez ici les quiz, le jeu Timeline et les frises à compléter.", 18))
	add_child(AppTheme.spacer(24))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SAGE, AppTheme.LINE, 12))
	add_child(panel)
	var inset := AppTheme.margin(24)
	panel.add_child(inset)
	var column := VBoxContainer.new()
	inset.add_child(column)
	column.add_child(AppTheme.label("Une première porte ouverte", 28, AppTheme.FOREST, true))
	column.add_child(AppTheme.paragraph("Le menu est prêt. Cette rubrique sera construite lors des prochaines étapes du projet.", 16))
	var back := Button.new()
	back.name = "BackHome"
	back.text = "←  Retour au menu"
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.y = 48
	back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back.pressed.connect(func() -> void: destination_requested.emit("home"))
	add_child(back)
