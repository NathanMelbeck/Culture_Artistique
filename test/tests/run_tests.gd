extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func _run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.save_path = "res://tests/.test-progress.json"
	app.progress = {"read": [], "quiz_done": false, "quiz_best": 0, "timeline_done": false}
	check(app.lessons.size() == 3, "Le catalogue et les trois illustrations se chargent sans réseau")
	for lesson in app.lessons:
		check(ResourceLoader.exists(lesson["image"]), "Illustration locale : " + str(lesson["id"]))
	app.mark_read()
	app.mark_read()
	check(app.progress["read"].size() == 1, "Un cours lu deux fois ne double pas la progression")
	app.navigate("quiz")
	app.next_question()
	check(app.quiz_index == 0, "Impossible de sauter une question sans répondre")
	app.answer_quiz(1)
	check(app.quiz_score == 0, "Une mauvaise réponse ne rapporte pas de point")
	app.answer_quiz(0)
	check(app.quiz_score == 0, "Une question ne peut pas être répondue deux fois")
	app.next_question()
	app.answer_quiz(1)
	app.next_question()
	app.answer_quiz(2)
	app.next_question()
	check(app.quiz_finished and app.quiz_score == 2, "Le quiz se termine avec un résultat de 2 sur 3")
	check(app.progress["quiz_done"] and app.progress["quiz_best"] == 2, "Le résultat est enregistré")
	app.restart_quiz()
	for answer in [2, 0, 0]:
		app.answer_quiz(answer)
		app.next_question()
	check(app.progress["quiz_best"] == 2, "Une nouvelle session ne réduit pas le meilleur score")
	app.navigate("timeline")
	app.check_timeline()
	check(not app.timeline_success and not app.progress["timeline_done"], "Une frise incomplète est refusée")
	app.place_card("renaissance", 0)
	app.place_card("gothique", 1)
	app.place_card("rome", 2)
	app.check_timeline()
	check(not app.timeline_success, "Une chronologie incorrecte est refusée")
	app.place_card("rome", 0)
	check(app.placements == ["rome", "gothique", "renaissance"], "Déplacer vers une case occupée échange les cartes sans doublon")
	app.check_timeline()
	check(app.timeline_success and app.progress["timeline_done"], "La bonne chronologie valide l'activité")
	app.place_card("inconnu", 0)
	check(app.placements[0] == "rome", "Une référence inconnue n'entre pas dans la frise")
	var second_app = load("res://scenes/main.tscn").instantiate()
	root.add_child(second_app)
	await process_frame
	second_app.save_path = app.save_path
	second_app._load_progress()
	check(second_app.progress == app.progress, "Les cours lus et résultats sont restaurés depuis le disque")
	var corrupt := FileAccess.open(app.save_path, FileAccess.WRITE)
	corrupt.store_string("contenu invalide")
	corrupt.close()
	second_app._load_progress()
	check(second_app.progress == app.progress, "Un fichier invalide ne fait pas planter l'application")
	app._save_progress()
	app.free()
	second_app.free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
