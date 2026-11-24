extends VBoxContainer

signal destination_requested(route: String)
var media_repository: MediaRepository

func _ready() -> void:
	add_child(AppTheme.eyebrow("LES PERSONNES ET LES SOURCES"))
	var title := AppTheme.label("Le savoir se construit à plusieurs.", 46, AppTheme.FOREST, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(title)
	add_child(AppTheme.paragraph("Culture Artistique · Conception et direction pédagogique : Nathan Melbeck\nUne application pour apprendre à regarder les formes et comprendre leur histoire.", 17))
	add_child(AppTheme.divider())
	add_child(AppTheme.label("La photographie du menu", 29, AppTheme.FOREST, true))
	var media := media_repository.get_media("home-cabinet")
	add_child(AppTheme.paragraph(media.get("caption", ""), 17, AppTheme.FOREST))
	add_child(AppTheme.paragraph("%s\n%s\n%s" % [media.get("credit", ""), media.get("license", ""), media.get("modifications", "")], 14))
	_external_link("Voir la notice de l’objet au Met   ↗", media.get("source_url", ""), "MuseumLink")
	_external_link("Conditions Met Open Access   ↗", media.get("rights_url", ""), "RightsLink")
	add_child(AppTheme.label("Les photographies des cours", 29, AppTheme.FOREST, true))
	add_child(AppTheme.paragraph("Les premières photographies de musée des cours d’Antiquité proviennent du Metropolitan Museum of Art, New York, et sont diffusées sous CC0 / Open Access. Chaque exemple indique sa notice, sa datation, son numéro d’inventaire et sa provenance lorsqu’elle est connue. Les originaux et les représentations d’époque sont identifiés ; les parties restaurées sont signalées dans les légendes.", 14))
	add_child(AppTheme.label("Les polices et le moteur", 29, AppTheme.FOREST, true))
	add_child(AppTheme.paragraph("Lora — Cyreal · Manrope — Mikhail Sharanda et contributeurs. Polices distribuées sous SIL Open Font License 1.1.\nLes petites icônes de navigation sont des dessins originaux du projet.\nApplication développée avec Godot Engine, sous licence MIT.", 14))
	var licenses := Button.new()
	licenses.name = "Licenses"
	licenses.text = "Lire les licences et les mentions de Godot"
	licenses.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	licenses.pressed.connect(_show_licenses)
	add_child(licenses)
	add_child(AppTheme.paragraph("Le Cleveland Museum of Art fournit les photographies de ses objets antiques et médiévaux en accès ouvert (CC0). Les notices de chaque catalogue donnent accès aux collections des musées.", 16))
	var back := AppTheme.quiet_button("←  Retour au menu")
	back.name = "BackHome"
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: destination_requested.emit("home"))
	add_child(back)

func _external_link(title: String, url: String, node_name: String) -> void:
	var button := AppTheme.quiet_button(title + "  · Internet requis")
	button.name = node_name
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.tooltip_text = "Ouvre le navigateur externe : " + url
	button.pressed.connect(func() -> void:
		var error := OS.shell_open(url)
		if error != OK:
			var message := AcceptDialog.new()
			message.dialog_text = "Impossible d’ouvrir le navigateur.\n" + url
			add_child(message)
			message.popup_centered()
	)
	add_child(button)

func _show_licenses() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Licences des ressources et du moteur"
	dialog.size = Vector2i(760, 520)
	dialog.min_size = Vector2i(500, 350)
	var text := TextEdit.new()
	text.name = "LicenseText"
	text.editable = false
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.text = "LORA — SIL OPEN FONT LICENSE\n\n" + FileAccess.get_file_as_string("res://assets/fonts/Lora-OFL.txt")
	text.text += "\n\nMANROPE — SIL OPEN FONT LICENSE\n\n" + FileAccess.get_file_as_string("res://assets/fonts/Manrope-OFL.txt")
	text.text += "\n\nGODOT ENGINE\n\n" + Engine.get_license_text()
	text.text += "\n\nCOMPOSANTS TIERS\n\n" + JSON.stringify(Engine.get_license_info(), "  ")
	text.custom_minimum_size = Vector2(700, 420)
	dialog.add_child(text)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
