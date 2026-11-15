extends "res://tests/menu_smoke.gd"

func click(node_name: String) -> void:
	var target := app.find_child(node_name, true, false) as Control
	if target == null:
		check(false, "Contrôle disponible : " + node_name)
		return
	var ancestor := target.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(target)
			await frames(2)
		ancestor = ancestor.get_parent()
	await super.click(node_name)

func _run() -> void:
	output_directory = ProjectSettings.globalize_path("res://../docs/validation/courses")
	DirAccess.make_dir_recursive_absolute(output_directory)
	app = load("res://scenes/app_shell.tscn").instantiate()
	# Ephemeral state: this test never changes the user's learning progress.
	app.progress_repository = ProgressRepository.new("")
	root.add_child(app)
	root.size = Vector2i(1440, 1000)
	root.position = Vector2i(20, 20)
	await frames(10)
	await click("CoursesNav")
	check(app._page.mode == "catalogue", "Cours ouvre le catalogue de l’Antiquité")
	check(app.course_repository.all().size() == 3, "Les trois cours sont disponibles")
	await capture("catalogue-1440.png")
	var filter := app.find_child("CoursePeriodFilter", true, false) as OptionButton
	filter.select(2)
	filter.item_selected.emit(2)
	await frames()
	check(app.find_child("Open_grece", true, false) != null and app.find_child("Open_egypte", true, false) == null, "La période peut être choisie directement")
	filter.select(0)
	filter.item_selected.emit(0)
	await frames()
	await click("Open_egypte")
	var browser: Control = app._page
	check(browser.mode == "reader" and browser.selected_id == "egypte", "La carte ouvre le cours natif")
	check(app.find_children("*", "RichTextLabel", true, false).size() > 2, "Le cours contient du texte natif sélectionnable")
	await capture("egypte-lecture.png")
	check(app.find_child("MarkChapterRead", true, false) == null, "Le lecteur ne propose plus de marquer comme lu")
	var map := app.find_child("CourseFigure_egypte-nil", true, false) as TextureRect
	check(map.size.x >= 600 and map.size.y > 1000, "La carte du Nil utilise la largeur de lecture et conserve ses proportions")
	await click("Enlarge_egypte-nil")
	var viewer := app.find_child("CourseImageViewer", true, false) as Window
	check(viewer != null, "La carte s’ouvre dans le lecteur de zoom intégré")
	if viewer != null:
		await frames(8)
		var full := viewer.find_child("ZoomedCourseImage", true, false) as TextureRect
		var initial := full.size
		(viewer.find_child("ZoomIn", true, false) as Button).pressed.emit()
		await frames()
		check(full.size.x > initial.x and full.size.y > initial.y, "Le zoom agrandit réellement l’image défilable")
		(viewer.find_child("FitPage", true, false) as Button).pressed.emit()
		await frames()
		var scroll := viewer.find_child("ImageZoomScroll", true, false) as ScrollContainer
		check(full.size.x <= scroll.size.x and full.size.y <= scroll.size.y, "La vue entière tient dans la zone disponible")
		(viewer.find_child("FitWidth", true, false) as Button).pressed.emit()
		await frames()
		check(full.size.y > scroll.size.y and full.size.x >= scroll.size.x - 30, "Le mode largeur rend la carte lisible avec défilement vertical")
		await RenderingServer.frame_post_draw
		check(viewer.get_texture().get_image().save_png(output_directory.path_join("nil-zoom.png")) == OK, "Capture du zoom de la carte")
		(viewer.find_child("CloseImageViewer", true, false) as Button).pressed.emit()
		await frames()

	await click("NextChapter")
	check(browser._child.chapter_index == 1 and app.progress_repository.get_course("egypte").is_empty(), "Continuer change de chapitre sans enregistrer de statut lu")
	await click("Chapter_architecture")
	check(browser._child.chapter_index == 2, "Le sommaire ouvre directement un chapitre")
	await click("Enlarge_egypte-temple")
	var dialogs := app.find_children("CourseImageViewer", "Window", true, false)
	check(dialogs.size() == 1, "L’illustration s’agrandit dans l’application")
	if not dialogs.is_empty():
		dialogs[0].hide()
		dialogs[0].queue_free()
	await frames()
	await click("HomeButton")
	await click("CoursesNav")
	browser = app._page
	check(browser.mode == "reader" and browser._child.chapter_index == 2, "Le cours et son chapitre sont conservés au retour")
	var chapters_rendered := 0
	var figures_readable := true
	var figures_checked := 0
	var expected_figures := 0
	var furniture_examples_rendered := 0
	var furniture_sections_ok := true
	for course in app.course_repository.all():
		browser._open_course(course["id"])
		await frames()
		for index in course["chapters"].size():
			for block in course["chapters"][index]["blocks"]:
				if block["type"] in ["image", "furniture_example"]:
					expected_figures += 1
			browser._child.show_chapter(index)
			await frames(3)
			if app.find_child("CourseChapterTitle", true, false) != null:
				chapters_rendered += 1
			for figure in app.find_children("CourseFigure_*", "TextureRect", true, false):
				figures_checked += 1
				figures_readable = figures_readable and figure.texture != null and figure.size.y >= 250
			if course["chapters"][index].get("section") == "mobilier":
				furniture_sections_ok = furniture_sections_ok and (app.find_child("CourseChapterTitle", true, false) as Label).text == "Le Mobilier"
				var examples := app.find_children("FurnitureExample_*", "VBoxContainer", true, false)
				furniture_examples_rendered += examples.size()
				furniture_sections_ok = furniture_sections_ok and examples.size() >= 4
				if not examples.is_empty():
					var reading := app.find_child("CourseReadingScroll", true, false) as ScrollContainer
					var last: Control = examples[-1]
					reading.scroll_vertical = int(last.position.y + last.size.y - reading.size.y)
					await frames()
					await capture("mobilier-" + course["id"] + "-caracteristiques.png")

			if course["id"] == "egypte" and index == 4:
				var kemeni := app.find_child("CourseFigure_egypte-kemeni", true, false) as TextureRect
				var reading := app.find_child("CourseReadingScroll", true, false) as ScrollContainer
				reading.ensure_control_visible(kemeni)
				await frames()
				await capture("kemeni-preuve.png")
				var found_source := false
				for label in app.find_children("*", "Label", true, false):
					if label.text == "Une preuve conservée : le coffret de Kemeni":
						found_source = true
						reading.ensure_control_visible(label)
						await frames()
						await capture("sources-placage.png")
				check(found_source, "La preuve du placage est présentée directement dans le chapitre")

			if course["id"] == "egypte" and index == 5:
				var chair := app.find_child("CourseFigure_egypte-reniseneb", true, false) as TextureRect
				var reading := app.find_child("CourseReadingScroll", true, false) as ScrollContainer
				reading.ensure_control_visible(chair)
				await frames()
				await capture("reniseneb-criteres.png")

	check(figures_checked == expected_figures and figures_readable, "Toutes les figures des cours ont une texture et une hauteur de lecture suffisante")
	check(furniture_sections_ok and furniture_examples_rendered == 12, "Chaque période affiche Le Mobilier avec quatre exemples commentés et illustrés")
	check(chapters_rendered == 18, "Les 18 chapitres sont construits avec le même lecteur")
	browser._open_course("grece")
	await frames()
	await click("Chapter_ordres")
	await capture("grece-ordres.png")
	await click("Chapter_synthese")
	check((app.find_child("CourseChapterTitle", true, false) as Label).text == "Reconnaître le mobilier grec", "La synthèse donne des critères propres à la période")
	check(app.course_repository.get_media("grece-klismos").is_empty() and app.find_child("CourseFigure_grece-klismos", true, false) == null and app.find_child("CourseFigure_grece-stele-siege", true, false) != null, "La réinterprétation moderne est remplacée par un témoignage grec d’époque")
	await click("NextChapter")
	check(browser.mode == "quiz", "La fin du cours ouvre le quiz de sa période")
	var question: Dictionary = browser._quiz_session.current()
	var wrong: int = (int(question["correct"]) + 1) % question["choices"].size()
	await click("Answer_" + str(wrong))
	check(app.find_child("AnswerExplanation", true, false) != null, "Une erreur reçoit une explication")
	check(browser._quiz_session.score == 0, "Une mauvaise réponse ne donne pas de point")
	await capture("quiz-correction.png")
	await click("ReviewQuestionChapter")
	check(browser.mode == "reader" and browser._child.course["chapters"][browser._child.chapter_index]["id"] == question["chapter"], "La correction renvoie au bon chapitre")
	await click("ResumeCourseQuiz")
	check(browser.mode == "quiz" and browser._quiz_session.selected == wrong, "La réponse est conservée pendant la relecture")
	await click("QuizNext")
	while not browser._quiz_session.finished:
		var answer := int(browser._quiz_session.current()["correct"])
		await click("Answer_" + str(answer))
		await click("QuizNext")
	check(app.find_child("QuizResult", true, false) != null and browser._quiz_session.score == 3, "Le résultat est calculé à partir des réponses réelles")
	check(app.progress_repository.get_course("grece").get("quiz_best") == 3, "Le meilleur résultat du quiz est conservé")
	await capture("quiz-resultat.png")
	await click("QuizRetry")
	check(browser._quiz_session.index == 0 and browser._quiz_session.score == 0, "Recommencer crée une nouvelle tentative")
	root.size = Vector2i(960, 640)
	await frames(8)
	browser._show_reader("ordres")
	await frames(8)
	check((app.find_child("ChapterPicker", true, false) as OptionButton).visible, "Un sélecteur de chapitre est disponible en petite fenêtre")
	var next := app.find_child("NextChapter", true, false) as Button
	check(root.get_visible_rect().encloses(next.get_global_rect()), "Les commandes restent dans la fenêtre à 960 × 640")
	await capture("cours-960.png")
	browser._open_course("egypte")
	await frames(8)
	browser._child.show_chapter(0)
	await frames(8)
	await click("Enlarge_egypte-nil")
	var compact_viewer := app.find_child("CourseImageViewer", true, false) as Window
	check(compact_viewer != null and compact_viewer.size.x <= 960 and compact_viewer.size.y <= 640, "Le zoom reste adapté à une petite fenêtre")
	if compact_viewer != null:
		(compact_viewer.find_child("CloseImageViewer", true, false) as Button).pressed.emit()
		await frames()

	await click("RevisionNav")
	check(app.navigation.current_route == "revision" and app.find_child("RevisionPageImage", true, false) != null, "Les fiches restent indépendantes et accessibles")
	print("COURSES RESULT: %d failures" % failures)
	app.queue_free()
	await frames()
	quit(1 if failures else 0)
