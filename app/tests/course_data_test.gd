extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, description: String) -> void:
	print(("PASS: " if value else "FAIL: ") + description)
	if not value:
		failures += 1

func _run() -> void:
	var repository := CourseRepository.new()
	var all_quizzes_ok := true
	for course in repository.all():
		var quiz := QuizSession.new(course["quiz"])
		quiz.advance()
		all_quizzes_ok = all_quizzes_ok and quiz.index == 0
		while not quiz.finished:
			quiz.answer(int(quiz.current()["correct"]))
			quiz.answer(int(quiz.current()["correct"]))
			quiz.advance()
		all_quizzes_ok = all_quizzes_ok and quiz.score == course["quiz"].size()
	check(all_quizzes_ok, "Les trois quiz calculent le résultat sans double comptage ni passage sans réponse")
	var path := "user://course-validation-%s.json" % Time.get_ticks_usec()
	var progress := ProgressRepository.new(path)
	progress.save_quiz("egypte", 3, 4)
	progress.save_quiz("egypte", 1, 4)
	var restored := ProgressRepository.new(path)
	check(not restored.get_course("egypte").has("read"), "Aucun statut de lecture n’est exposé")
	check(restored.get_course("egypte").get("quiz_best") == 3, "Une tentative moins bonne ne remplace pas le meilleur score")
	check(not FileAccess.file_exists(path + ".tmp"), "Le remplacement du fichier de progression termine son écriture")
	var invalid := FileAccess.open(path, FileAccess.WRITE)
	invalid.store_string('{"version":1,"courses":{"egypte":{"read":42,"quiz_best":"invalide"}}}')
	invalid.close()
	var corrupted := ProgressRepository.new(path)
	check(not corrupted.get_course("egypte").has("read") and not corrupted.get_course("egypte").has("quiz_best"), "Des champs de progression invalides sont ignorés sans faire planter le lecteur")
	var legacy_file := FileAccess.open(path, FileAccess.WRITE)
	legacy_file.store_string('{"version":1,"courses":{"egypte":{"read":["nil-reperes"],"quiz_best":2,"quiz_total":4}}}')
	legacy_file.close()
	var legacy := ProgressRepository.new(path)
	legacy.save_quiz("egypte", 3, 4)
	var legacy_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(not legacy.get_course("egypte").has("read") and legacy_disk["courses"]["egypte"]["read"] == ["nil-reperes"], "Les anciens statuts sont ignorés sans effacer les données existantes")
	# Only this unique test file is removed. Real progress is never touched.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("COURSE DATA RESULT: %d failures" % failures)
	quit(1 if failures else 0)
