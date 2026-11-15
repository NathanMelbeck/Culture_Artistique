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
	await click("NextChapter")
	check(browser._child.chapter_index == 1 and app.progress_repository.is_read("egypte", "nil-reperes"), "Continuer marque le chapitre lu et ouvre le suivant")
	await click("Chapter_architecture")
	check(browser._child.chapter_index == 2, "Le sommaire ouvre directement un chapitre")
	await click("Enlarge_egypte-temple")
	var dialogs := app.find_children("*", "AcceptDialog", true, false)
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
	for course in app.course_repository.all():
		browser._open_course(course["id"])
		await frames()
		for index in course["chapters"].size():
			browser._child.show_chapter(index)
			await frames(3)
			if app.find_child("CourseChapterTitle", true, false) != null:
				chapters_rendered += 1
	check(chapters_rendered == 18, "Les 18 chapitres sont construits avec le même lecteur")
	browser._open_course("grece")
	await frames()
	await click("Chapter_ordres")
	await capture("grece-ordres.png")
	await click("Chapter_synthese")
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
	check(app.progress_repository.get_course("grece").get("quiz_best") == 3, "Le meilleur résultat est conservé séparément des chapitres lus")
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
	await click("RevisionNav")
	check(app.navigation.current_route == "revision" and app.find_child("RevisionPageImage", true, false) != null, "Les fiches restent indépendantes et accessibles")
	print("COURSES RESULT: %d failures" % failures)
	app.queue_free()
	await frames()
	quit(1 if failures else 0)
