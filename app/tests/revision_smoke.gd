extends "res://tests/menu_smoke.gd"

func _run() -> void:
	output_directory = ProjectSettings.globalize_path("res://../docs/validation/revision")
	DirAccess.make_dir_recursive_absolute(output_directory)
	app = load("res://scenes/app_shell.tscn").instantiate()
	root.add_child(app)
	root.size = Vector2i(1440, 1000)
	root.position = Vector2i(20, 20)
	await frames(10)
	await click("RevisionNav")
	check(app.navigation.current_route == "revision", "Le bouton du haut ouvre les fiches dans l’application")
	var reader: Control = app._page
	check(app.revision_repository.all().size() == 17, "Les 17 périodes sont présentes")
	check(reader.selected_id == "egypte", "La première fiche est chargée")
	check(reader._period_buttons.size() == 17, "La liste affiche toutes les périodes avant une recherche")
	var image := app.find_child("RevisionPageImage", true, false) as TextureRect
	check(image.texture != null and image.texture.get_width() == 3000, "La page locale haute définition est chargée")
	check((app.find_child("PreviousPage", true, false) as Button).disabled, "La première page ne permet pas de reculer")
	await capture("revision-1440.png")
	await click("NextPage")
	check(reader.page_index == 1 and (app.find_child("NextPage", true, false) as Button).disabled, "La deuxième page est accessible et termine la fiche")
	await key(KEY_LEFT)
	check(reader.page_index == 0, "Flèche gauche : page précédente")
	await key(KEY_RIGHT)
	check(reader.page_index == 1, "Flèche droite : page suivante")
	for step in 6:
		await click("ZoomIn")
	check(is_equal_approx(reader.zoom_factor, 2.5), "Le zoom permet de lire les détails à 250 %")
	check(image.custom_minimum_size.x > reader._reader_scroll.size.x, "La page agrandie peut défiler horizontalement")
	await capture("revision-zoom.png")
	await click("FitWidth")
	check(is_equal_approx(reader.zoom_factor, 1.0), "Adapter rétablit la largeur du lecteur")
	var search := app.find_child("RevisionSearch", true, false) as LineEdit
	search.text = "regence"
	search.text_changed.emit(search.text)
	await frames()
	check(reader._period_buttons.size() == 1, "La recherche trouve Régence sans accent")
	await click("Period_regence")
	check(reader.selected_id == "regence", "Le choix de période remplace la fiche dans le lecteur")
	search.text = "introuvable"
	search.text_changed.emit(search.text)
	await frames()
	check(reader._period_buttons.is_empty(), "La recherche sans résultat conserve le lecteur utilisable")
	search.text = ""
	search.text_changed.emit("")
	await frames()
	check(reader._period_buttons.size() == 17, "Effacer la recherche réaffiche toutes les périodes")
	await click("NextPage")
	await click("ZoomIn")
	await click("HomeButton")
	await click("RevisionNav")
	reader = app._page
	check(reader.selected_id == "regence" and reader.page_index == 1 and is_equal_approx(reader.zoom_factor, 1.25), "Le retour conserve la fiche, la page et le zoom pendant la session")
	await click("NextSheet")
	check(reader.selected_id == "louis-xv" and reader.page_index == 0, "Fiche suivante suit l’ordre du catalogue")
	await click("PreviousSheet")
	check(reader.selected_id == "regence", "Fiche précédente revient à la période précédente")
	var available_pages := 0
	for sheet in app.revision_repository.all():
		for index in sheet["pages"].size():
			var texture: Texture2D = app.revision_repository.load_page(sheet["id"], index)
			if texture != null and texture.get_width() == sheet["pages"][index]["width"]:
				available_pages += 1
	check(available_pages == 34, "Les 34 pages embarquées sont lisibles par Godot")
	reader._open_sheet("art-deco")
	await frames()
	check((app.find_child("NextSheet", true, false) as Button).disabled, "La dernière fiche termine la navigation")
	root.size = Vector2i(960, 640)
	await frames(10)
	var picker := app.find_child("PeriodPicker", true, false) as OptionButton
	check(picker.visible, "Le sélecteur compact remplace la liste sur une petite fenêtre")
	picker.select(1)
	picker.item_selected.emit(1)
	await frames()
	check(reader.selected_id == "grece", "Le sélecteur compact permet de changer de période")
	await capture("revision-960.png")
	var footer := app.find_child("NextSheet", true, false) as Button
	check(root.get_visible_rect().encloses(footer.get_global_rect()), "La navigation des fiches reste dans la fenêtre à 960 × 640")
	await key(KEY_ESCAPE)
	check(app.navigation.current_route == "home", "Échap quitte la lecture et revient au menu")
	await click("CoursesNav")
	check(app.navigation.current_route == "courses", "Les autres rubriques restent accessibles")
	print("REVISION RESULT: %d failures" % failures)
	app.queue_free()
	await frames()
	quit(1 if failures else 0)
