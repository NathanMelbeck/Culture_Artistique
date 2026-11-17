extends VBoxContainer

signal destination_requested(route: String)
const CARD := preload("res://components/destination_card.tscn")
var media_repository: MediaRepository
var _hero: BoxContainer
var _cards: GridContainer
var _title: Label
var _art: VBoxContainer
var _intro: VBoxContainer
var _photo: TextureRect

func _ready() -> void:
	_build_hero()
	var row := HBoxContainer.new()
	row.add_child(AppTheme.label("CHOISISSEZ VOTRE PARCOURS", 11))
	var line := AppTheme.divider()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(line)
	add_child(row)
	_cards = GridContainer.new()
	_cards.columns = 3
	_cards.add_theme_constant_override("h_separation", 18)
	_cards.add_theme_constant_override("v_separation", 18)
	add_child(_cards)
	_add_card("courses", "Les cours", "Des civilisations aux styles : comprendre les formes et leurs histoires.", "01 / APPRENDRE", "book", true)
	_add_card("games", "Les jeux", "Quiz, cartes et frises pour transformer vos découvertes en connaissances.", "02 / S’ENTRAÎNER", "game")
	_add_card("credits", "Les crédits", "Le projet, les sources et les personnes qui le font vivre.", "03 / DÉCOUVRIR", "info")
	var note := AppTheme.paragraph("À votre rythme, sans compte et sans connexion. Seuls les liens vers des sites externes nécessitent Internet.", 13)
	note.name = "OfflineNote"
	add_child(note)
	resized.connect(_adapt)
	get_viewport().size_changed.connect(_adapt)
	_adapt.call_deferred()

func _build_hero() -> void:
	_hero = BoxContainer.new()
	_hero.add_theme_constant_override("separation", 48)
	add_child(_hero)
	_intro = VBoxContainer.new()
	_intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_intro.size_flags_stretch_ratio = 1.48
	_intro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_intro.add_theme_constant_override("separation", 20)
	_hero.add_child(_intro)
	_intro.add_child(AppTheme.eyebrow("LE SAVOIR PREND FORME"))
	_title = AppTheme.label("L’histoire se lit aussi\ndans les détails.", 66, AppTheme.FOREST, true)
	_title.name = "HeroTitle"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_constant_override("line_spacing", -3)
	_intro.add_child(_title)
	_intro.add_child(AppTheme.paragraph("Explorez les époques, apprenez à reconnaître les styles\net exercez votre regard, à votre rythme.", 17))
	_intro.add_child(AppTheme.spacer(4))
	var benefits := HBoxContainer.new()
	benefits.add_theme_constant_override("separation", 30)
	_intro.add_child(benefits)
	for item in [["book", "Des cours illustrés"], ["game", "Des jeux pour retenir"]]:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 8)
		benefits.add_child(pair)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/icons/%s.svg" % item[0])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(19, 19)
		pair.add_child(icon)
		pair.add_child(AppTheme.label(item[1], 12, AppTheme.MUTED))
	_art = VBoxContainer.new()
	_art.name = "Artwork"
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.add_theme_constant_override("separation", 12)
	_hero.add_child(_art)
	var media := media_repository.get_media("home-cabinet")
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", AppTheme.box(Color("eeeee8"), AppTheme.LINE, 12))
	_art.add_child(frame)
	_photo = TextureRect.new()
	_photo.name = "MuseumPhotograph"
	_photo.texture = media_repository.get_texture("home-cabinet")
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo.custom_minimum_size.y = 332
	_photo.tooltip_text = media.get("alt", "")
	frame.add_child(_photo)
	if _photo.texture == null:
		frame.add_child(AppTheme.paragraph("Photographie indisponible. Les autres rubriques restent accessibles."))
	var caption := AppTheme.paragraph(media.get("caption", ""), 12)
	caption.name = "ArtworkCaption"
	_art.add_child(caption)
	var source := AppTheme.quiet_button("The Met · Domaine public · Crédits  →")
	source.custom_minimum_size.y = 32
	source.name = "ArtworkSource"
	source.alignment = HORIZONTAL_ALIGNMENT_LEFT
	source.add_theme_font_size_override("font_size", 11)
	source.add_theme_stylebox_override("normal", AppTheme.box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 0))
	source.tooltip_text = "Voir les crédits de la photographie (hors ligne)"
	source.pressed.connect(func() -> void: destination_requested.emit("credits"))
	_art.add_child(source)

func _add_card(route: String, heading: String, description: String, kicker: String, icon: String, featured: bool = false) -> void:
	var card := CARD.instantiate()
	card.name = route.capitalize() + "Card"
	card.route = route
	card.heading = heading
	card.description = description
	card.kicker = kicker
	card.icon_path = "res://assets/icons/%s.svg" % icon
	card.featured = featured
	card.pressed.connect(func() -> void: destination_requested.emit(route))
	_cards.add_child(card)

func _adapt() -> void:
	if not is_inside_tree():
		return
	if not is_instance_valid(_hero):
		return
	var compact := size.x < 1000
	var short_window := get_viewport_rect().size.y < 950
	_hero.vertical = compact
	_intro.size_flags_stretch_ratio = 1.48 if not compact else 1.0
	_intro.add_theme_constant_override("separation", 14 if short_window else 20)
	_title.add_theme_font_size_override("font_size", 52 if short_window else (58 if size.x < 1220 else 66))
	_cards.columns = 1 if compact else 3
	_photo.custom_minimum_size.y = 250 if compact else (210 if short_window else 300)
	for card in _cards.get_children():
		card.custom_minimum_size.y = 230
