extends "res://tests/frieze_smoke.gd"

func choose(key: String, value: String) -> void:
	var picker := widget("Filter_" + key) as OptionButton
	for i in picker.item_count:
		if picker.get_item_metadata(i) == value:
			picker.select(i)
			picker.item_selected.emit(i)
			await frames(2)
			return
	check(false, "Filtre disponible : " + key + " / " + value)

func _run() -> void:
	output_directory = ProjectSettings.globalize_path("res://../.tmp/catalogue-validation")
	DirAccess.make_dir_recursive_absolute(output_directory)
	app = load("res://scenes/app_shell.tscn").instantiate()
	app.progress_repository = ProgressRepository.new("")
	root.add_child(app)
	root.size = Vector2i(1280, 800)
	await frames(10)
	await click("CatalogueCard")
	check(app.navigation.current_route == "catalogue", "La carte d’accueil ouvre le catalogue")
	var general: Control = app._page
	var repo: ArtworkCatalogue = app.course_repository.artworks
	check(repo.categories.size() == 6, "Six catégories")
	check(general._gallery.find_children("Artwork_*", "TextureButton", true, false).size() == general.PAGE_SIZE, "Miniatures paginées")
	general._next.pressed.emit()
	await frames()
	check(general._page == 1, "Deuxième page")
	await choose("category", "mobilier")
	await choose("kind", "Sièges")
	await choose("provenance", "France")
	check(general._page == 0, "Les filtres repartent en première page")
	await capture("sieges-francais.png")
	var results := repo.select(general._filters, "", "oldest")
	var last := -99999
	for work in results:
		check(work.sort_year >= last and work.provenance == "France" and work.kind == "Sièges", "Tri et filtres combinés")
		last = work.sort_year
	await choose("periods", "gothique")
	await click("MoreFilters")
	await choose("materials", "Noyer")
	var query := widget("ArtworkSearch") as LineEdit
	query.text = "SIEGE"
	query.text_changed.emit(query.text)
	await frames()
	check(general._gallery.find_children("Artwork_*", "TextureButton", true, false).size() == 1, "Recherche sans accents et filtres cumulés")
	await click("Artwork_gothique-siege-noyer")
	var detail := app.find_child("ArtworkDetail", true, false) as Window
	check(detail != null and detail.visible, "Notice depuis la galerie générale")
	if detail != null:
		var figure := detail.find_child("CourseFigure_gothique-siege-noyer", true, false) as TextureRect
		check(figure != null and figure.texture != null, "Illustration en pleine définition locale")
		detail.find_child("Enlarge_gothique-siege-noyer", true, false).pressed.emit()
		await frames()
		var viewer := detail.find_child("CourseImageViewer", true, false) as Window
		check(viewer != null and viewer.visible, "Zoom dans la notice")
		if viewer != null: viewer.queue_free()
		await frames()
		detail.find_child("ArtworkCourse_gothique", true, false).pressed.emit()
		await frames()
	check(app.navigation.current_route == "courses", "Renvoi au cours de la période")
	await click("Chapter_catalogue")
	var collection := widget("CourseArtworks") as ArtworkGallery
	check(collection.repository.artworks == repo, "Le cours partage la même base")
	check(widget("Artwork_gothique-siege-noyer") != null and widget("Artwork_roman-cathedre-avignon") == null, "La vue du cours filtre par période")
	await click("CatalogueNav")
	general = app._page
	check(general._filters.get("kind") == "Sièges", "Retour au catalogue et à la sélection")
	await click("ResetCatalogue")
	await choose("category", "peinture")
	check(widget("Artwork_rome-peinture") != null, "Peinture et source locale accessibles")
	query = widget("ArtworkSearch")
	query.text = "inexistant"
	query.text_changed.emit(query.text)
	await frames()
	check(general._count.text.contains("Aucune"), "État vide explicite")
	root.size = Vector2i(960, 640)
	await frames()
	await click("ResetCatalogue")
	await capture("catalogue-compact.png")
	check(widget("CatalogueNav").get_global_rect().end.x <= root.size.x and general._scroll.size.y > 150, "Navigation et résultats en petite fenêtre")
	print("CATALOGUE UI RESULT: %d failures" % failures)
	quit(1 if failures else 0)
