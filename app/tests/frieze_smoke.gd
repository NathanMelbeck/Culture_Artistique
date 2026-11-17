extends "res://tests/menu_smoke.gd"

func click(node_name: String) -> void:
	var control := app.find_child(node_name, true, false) as Control
	if control != null:
		var ancestor := control.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer:
				ancestor.ensure_control_visible(control)
				await frames(2)
			ancestor = ancestor.get_parent()
	await super.click(node_name)

func drag_card(source: Control, target: Control) -> void:
	var start := source.get_global_rect().get_center()
	var finish := target.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = start
	Input.parse_input_event(move)
	await frames(2)
	var press := InputEventMouseButton.new()
	press.position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	await frames(2)
	for step in range(1, 15):
		var motion := InputEventMouseMotion.new()
		motion.position = start.lerp(finish, step / 14.0)
		motion.relative = (finish - start) / 14.0
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await frames(1)
	var release := InputEventMouseButton.new()
	release.position = finish
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	await frames(8)

func drag_at_edge(source: Control, board: ScrollContainer) -> void:
	var start := source.get_global_rect().get_center()
	var finish := board.get_global_rect().end - Vector2(12, board.size.y / 2)
	var press := InputEventMouseButton.new()
	press.position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	var initial := InputEventMouseMotion.new()
	initial.position = start
	Input.parse_input_event(initial)
	Input.parse_input_event(press)
	await frames(2)
	for step in range(1, 15):
		var motion := InputEventMouseMotion.new()
		motion.position = start.lerp(finish, step / 14.0)
		motion.relative = (finish - start) / 14.0
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await frames(1)
	await create_timer(0.2).timeout
	var cancel := InputEventMouseMotion.new()
	cancel.position = Vector2(500, 110)
	cancel.relative = cancel.position - finish
	cancel.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(cancel)
	await frames(2)
	var release := InputEventMouseButton.new()
	release.position = cancel.position
	release.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(release)
	await frames(6)

func _run() -> void:
	output_directory = ProjectSettings.globalize_path("res://../docs/validation/frieze")
	DirAccess.make_dir_recursive_absolute(output_directory)
	app = load("res://scenes/app_shell.tscn").instantiate()
	app.progress_repository = ProgressRepository.new("")
	root.add_child(app)
	root.size = Vector2i(1440, 1000)
	root.position = Vector2i(20, 20)
	await frames(12)
	await create_timer(0.15).timeout
	await click("GamesNav")
	check(app.find_child("OpenFrieze", true, false) != null, "Les jeux donnent accès au premier jeu de frise")
	await capture("jeux-1440.png")
	await click("OpenFrieze")
	if app.find_child("StartFrieze", true, false) == null:
		await capture("failure-open-game.png")
		print("MODE AFTER OPEN: ", app._page.mode)
		check(false, "Le bouton du catalogue ouvre la sélection")
		quit(1)
		return
	check((app.find_child("StartFrieze", true, false) as Button).disabled, "Une sélection vide ne permet pas de démarrer")
	await click("SelectPeriod_egypte")
	await click("SelectPeriod_rome")
	check((app.find_child("SelectPeriod_grece", true, false) as CheckBox).button_pressed and app._page.repository.resolve_periods(app._page.anchors).size() == 3, "Choisir les extrémités inclut visiblement la Grèce")
	await capture("selection-automatique.png")
	await click("SelectPeriod_grece")
	check((app.find_child("SelectPeriod_grece", true, false) as CheckBox).button_pressed, "Une période intermédiaire obligatoire reste cochée")
	await click("Group_antiquite")
	await click("StartFrieze")
	var games: Control = app._page
	check(games.session.phase == "start" and app.find_children("Boundary_*", "Button", true, false).size() == 5, "La première question propose cinq dates et aucune carte")
	var wrong := 0
	for value in games.session.boundary_choices():
		if int(value) != int(games.session.start_period["start"]):
			wrong = int(value)
			break
	await click("Boundary_" + str(wrong))
	check(games.session.phase == "start" and (app.find_child("Boundary_" + str(wrong), true, false) as Button).disabled, "Une mauvaise date se retente sans passer à l’étape suivante")
	await capture("borne-reessayer.png")
	await click("Boundary_" + str(int(games.session.start_period["start"])))
	check(games.session.phase == "end" and games.session.hand.is_empty(), "La seconde question demande la fin avant de distribuer")
	await click("Boundary_" + str(int(games.session.end_period["end"])))
	check(games.session.phase == "placement" and games.session.hand.size() == 7 and games.session.draw_pile.size() == games.session.events.size() - 7, "La main de sept cartes et la pioche sont affichées")
	check(app.find_child("ValidateFrieze", true, false) == null, "Le bouton de validation est absent tant que des cartes restent à poser")
	var dates_hidden := true
	for card in app.find_children("HandCard_*", "Button", true, false):
		dates_hidden = dates_hidden and not card.text.contains("J.-C.")
	check(dates_hidden, "Les faces des cartes ne révèlent aucune date")
	await capture("frise-main-1440.png")
	var first: String = games.session.hand[0]
	await drag_card(app.find_child("HandCard_" + first, true, false), app.find_child("FriezeSlot_egy-unification", true, false))
	check(games.session.placements.get("egy-unification") == first and games.session.hand.size() == 7 and games.session.draw_pile.size() == games.session.events.size() - 8, "Le vrai glisser-déposer place une carte et complète automatiquement la main")
	var second: String = games.session.hand[0]
	await drag_card(app.find_child("HandCard_" + second, true, false), app.find_child("FriezeSlot_egy-kemeni", true, false))
	await drag_card(app.find_child("FriezeSlot_egy-unification", true, false), app.find_child("FriezeSlot_egy-kemeni", true, false))
	check(games.session.placements.get("egy-unification") == second and games.session.placements.get("egy-kemeni") == first, "Le vrai glisser-déposer échange deux cartes déjà placées")
	await drag_card(app.find_child("HandCard_" + games.session.hand[0], true, false), app.find_child("FriezeProgress", true, false))
	check(games.session.placements.size() == 2 and games.session.hand.size() == 7, "Un dépôt hors des emplacements ne perd aucune carte")
	var edge_board := app.find_child("FriezeBoardScroll", true, false) as ScrollContainer
	await drag_at_edge(app.find_child("HandCard_" + games.session.hand[0], true, false), edge_board)
	check(edge_board.scroll_horizontal > 0 and games.session.placements.size() == 2, "Maintenir une carte au bord fait défiler la frise sans la placer")
	edge_board.scroll_horizontal = 0
	var keyboard_card: String = games.session.hand[0]
	(app.find_child("HandCard_" + keyboard_card, true, false) as Button).grab_focus()
	await key(KEY_SPACE)
	check(games.selected_card == keyboard_card and root.gui_get_focus_owner() == app.find_child("HandCard_" + keyboard_card, true, false), "Espace sélectionne une carte et conserve le focus")
	(app.find_child("FriezeSlot_egy-hatshepsout", true, false) as Button).grab_focus()
	await key(KEY_ENTER)
	check(games.session.placements.get("egy-hatshepsout") == keyboard_card, "Entrée associe la carte sélectionnée à la date au clavier")
	var discard: String = games.session.hand[0]
	await click("HandCard_" + discard)
	await click("DiscardFriezeCard")
	check(discard in games.session.draw_pile and discard not in games.session.hand and games.session.hand.size() == 7, "La défausse sélectionnée retourne dans la pioche et reçoit une remplaçante")
	await click("HomeButton")
	await click("GamesNav")
	games = app._page
	check(games.session.placements.size() == 3 and games.session.phase == "placement", "Retourner au menu puis aux jeux conserve la partie")
	root.size = Vector2i(960, 640)
	await frames(10)
	var hand := app.find_child("FriezeHandPanel", true, false) as Control
	check(root.get_visible_rect().encloses(hand.get_global_rect()), "La main reste entièrement dans la petite fenêtre")
	var cards_fit := true
	for card in app.find_children("HandCard_*", "Button", true, false):
		cards_fit = cards_fit and hand.get_global_rect().encloses(card.get_global_rect())
	check(cards_fit, "Les sept cartes restent dans les limites de la main à 960 × 640")
	var board := app.find_child("FriezeBoardScroll", true, false) as ScrollContainer
	check(board.size.y >= 160 and board.get_h_scroll_bar().max_value > board.size.x, "La frise conserve sa hauteur et défile horizontalement")
	await capture("frise-main-960.png")
	# Complete most associations correctly and leave a deliberate exchange for correction.
	while not games.session.hand.is_empty():
		var id: String = games.session.hand[0]
		games.session.place(id, id)
	for event in games.session.events:
		if games.session.placements.get(event["id"]) != event["id"]:
			games.session.place(event["id"], event["id"])
	games.session.place("egy-unification", games.session.events[-1]["id"])
	games._refresh()
	await frames(6)
	check(app.find_child("ValidateFrieze", true, false) != null and root.get_visible_rect().encloses((app.find_child("ValidateFrieze", true, false) as Control).get_global_rect()), "Toutes les cartes posées font apparaître un bouton Valider accessible")
	await click("ValidateFrieze")
	check(games.session.phase == "result" and games.session.score() == games.session.events.size() - 2, "La validation compte les réponses correctes et les deux erreurs voulues")
	var red := app.find_child("FriezeSlot_egy-unification", true, false) as Button
	var green := app.find_child("FriezeSlot_egy-kemeni", true, false) as Button
	check(red.text.begins_with("✕ ") and green.text.begins_with("✓ ") and red.get_theme_color("font_color") != green.get_theme_color("font_color"), "Les réponses sont distinguées par une couleur et un symbole")
	await capture("correction-960.png")
	await click("ReviewFriezeCourse")
	check(app.navigation.current_route == "courses" and app._page.mode == "reader", "La correction ouvre le cours associé dans l’application")
	await click("GamesNav")
	games = app._page
	check(games.session.phase == "result" and games.session.score() == games.session.events.size() - 2, "La correction reste disponible après la relecture du cours")
	await click("ReplayFrieze")
	check(games.session.phase == "start" and games.session.placements.is_empty() and games.session.hand.is_empty(), "Rejouer remet les bornes et toutes les cartes à zéro")
	root.size = Vector2i(1280, 720)
	await frames(8)
	await capture("bornes-1280.png")
	await click("ChangePeriods")
	await click("ClearPeriods")
	await click("SelectPeriod_egypte")
	await click("StartFrieze")
	await click("Boundary_-4000")
	await click("Boundary_-400")
	check(games.session.phase == "placement" and games.session.hand.size() == 5 and games.session.draw_pile.is_empty() and app.find_children("HandCard_*", "Button", true, false).size() == 5, "La sélection Égypte seule suit les bornes de la fiche et affiche cinq cartes sans pioche")
	await capture("egypte-bornes-fiche.png")
	print("FRIEZE UI RESULT: %d failures" % failures)
	app.queue_free()
	await frames()
	quit(1 if failures else 0)
