extends "res://tests/frieze_smoke.gd"

func _run() -> void:
	output_directory = ProjectSettings.globalize_path("res://../.tmp/medieval-validation")
	DirAccess.make_dir_recursive_absolute(output_directory)
	app = load("res://scenes/app_shell.tscn").instantiate()
	app.progress_repository = ProgressRepository.new("")
	root.add_child(app)
	root.size = Vector2i(1280, 800)
	await frames(8)
	await click("CoursesNav")
	var filter := widget("CoursePeriodFilter") as OptionButton
	for i in filter.item_count:
		if filter.get_item_metadata(i) == "moyen-age":
			filter.select(i)
			filter.item_selected.emit(i)
	await frames()
	check(widget("Open_roman") != null and widget("Open_gothique") != null and widget("Open_rome") == null, "Le filtre Moyen Âge ouvre les deux cours")
	(widget("Open_gothique") as Button).grab_focus()
	await frames()
	await key(KEY_ENTER)
	await click("Chapter_catalogue")
	var gallery := widget("FurnitureGallery") as GridContainer
	check(gallery != null and gallery.get_child_count() >= 5, "Galerie médiévale avec cinq notices illustrées")
	await capture("catalogue-gothique.png")
	await click("CourseRevision")
	check(app._page.selected_id == "gothique", "Lien direct du cours à sa fiche intégrée")
	await click("GamesNav")
	await click("OpenFrieze")
	await click("Group_moyen-age")
	var games: Control = app._page
	var repo: ChronologyRepository = games.repository
	check(repo.resolve_periods(["egypte","gothique"]).size() == 5, "Une sélection entre les deux époques inclut les cinq périodes")
	for id in ["roman","gothique"]:
		var selected := repo.resolve_periods([id])
		check(repo.build_deck(selected,"markers",0).size() == 2 and repo.build_deck(selected,"classic",4).size() == 4 and repo.build_deck(selected,"free",4).size() == 4, "Les trois modes sont disponibles pour " + id)
	await click("StartFrieze")
	var ongoing: FriezeSession = games.session
	await click("Boundary_900")
	await click("QuitFrieze")
	check(games.mode == "catalogue" and games.session == ongoing and app.progress_repository.owned_normals().is_empty(), "Quitter avant la fin conserve la partie sans récompense")
	await click("ResumeFrieze")
	await click("Boundary_1500")
	check(games.session.period_count() == 2 and games.session.hand.size() == 2, "Les deux bornes internes restent à placer")
	while not ongoing.hand.is_empty():
		var id := ongoing.hand[0]
		if not ongoing.place(id,id):
			check(false,"Placement classique de " + id)
			break
	games._refresh()
	await frames()
	await click("ValidateFrieze")
	check(ongoing.phase == "result" and ongoing.rewarded, "Bilan médiéval et attribution de la récompense")
	await capture("bilan-medieval.png")
	await click("ShowSolution")
	var ids := ongoing.events.map(func(card): return card.id)
	games.screen.change_comparison(ids.find("roman-autel-gertrude"))
	await frames()
	await click("ReviewFriezeCourse")
	check(app._page.selected_id == "roman" and app._page._child.course.chapters[app._page._child.chapter_index].id == "mobilier", "La correction mène au chapitre de l’objet")
	await click("GamesNav")
	games = app._page
	games.screen.change_comparison(ids.find("period-boundary-gothique-start"))
	await frames()
	await click("ReviewFriezeSheet")
	check(app._page.selected_id == "gothique", "Un repère corrigé ouvre la fiche correspondante")
	await click("GamesNav")
	games = app._page
	await click("QuitFrieze")
	check(games.mode == "catalogue" and games.session == null, "Quitter depuis la comparaison ferme la partie terminée")
	await click("OpenFrieze")
	await click("Mode_markers")
	await click("StartFrieze")
	ongoing = games.session
	check(ongoing.events.size() == 4, "Les quatre dates du roman et du gothique sont jouables")
	await click("HandCard_"+ongoing.hand[0])
	await click("QuitFromDialog")
	await click("ResumeFrieze")
	check(games.session == ongoing and widget("YearInput") == null, "Reprise après avoir quitté la saisie d’une date")
	while not ongoing.hand.is_empty():
		var id := ongoing.hand[0]
		if not ongoing.assign_year(id, int(ongoing.event(id).year)):
			check(false, "Saisie du repère " + id)
			break
	games._refresh()
	await frames()
	await click("ValidateFrieze")
	await click("ResultCollection")
	check(games.mode == "collection" and games.session == null and not app.progress_repository.owned_normals().is_empty(), "Voir la collection ferme la partie et conserve les cartes gagnées")
	await click("OpenFrieze")
	await click("Mode_free")
	await click("StartFrieze")
	ongoing = games.session
	await click("QuitFrieze")
	await click("ResumeFrieze")
	check(games.session == ongoing and widget("FreeAxis") != null, "Reprise de la frise libre")
	print("MEDIEVAL UI RESULT: %d failures" % failures)
	quit(1 if failures else 0)
