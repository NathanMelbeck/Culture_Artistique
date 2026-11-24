extends SceneTree

# Vérification réelle des entrées souris/clavier et du redimensionnement.
# À lancer avec un moteur graphique, pas avec --headless (captures GPU).
var failures := 0
var app: Control
var output_directory := ""

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int = 5) -> void:
	for index in count:
		await process_frame

func check(condition: bool, description: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + description)
	if not condition:
		failures += 1

func click(node_name: String) -> void:
	var control := app.find_child(node_name, true, false) as Control
	if control == null:
		check(false, "Contrôle disponible : " + node_name)
		return
	var scroll := app.find_child("PageScroll", true, false) as ScrollContainer
	if scroll.is_ancestor_of(control):
		scroll.ensure_control_visible(control)
		await frames()
	var center := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	Input.parse_input_event(motion)
	await frames(1)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = center
	press.pressed = true
	Input.parse_input_event(press)
	await frames(1)
	var release := press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await frames()

func key(code: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	await frames(1)
	var release := press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await frames()

func capture(filename: String) -> void:
	var focus := root.gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	var mouse := InputEventMouseMotion.new()
	mouse.position = Vector2(500, 100)
	Input.parse_input_event(mouse)
	await frames()
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output_directory.path_join(filename))
	check(result == OK, "Capture : " + filename)

func _run() -> void:
	output_directory = OS.get_environment("MENU_CAPTURE_DIR")
	if output_directory.is_empty():
		output_directory = ProjectSettings.globalize_path("res://../docs/validation/menu")
	DirAccess.make_dir_recursive_absolute(output_directory)
	app = load("res://scenes/app_shell.tscn").instantiate()
	root.add_child(app)
	root.size = Vector2i(1440, 1000)
	root.position = Vector2i(20, 20)
	await frames(10)
	check(app.navigation.current_route == "home", "Démarrage sur le menu")
	var photo := app.find_child("MuseumPhotograph", true, false) as TextureRect
	check(photo != null and photo.texture != null, "La photographie locale est chargée")
	await capture("menu-1440.png")
	for item in [["CoursesCard", "courses"], ["GamesCard", "games"], ["CatalogueCard", "catalogue"], ["CreditsCard", "credits"]]:
		await click(item[0])
		check(app.navigation.current_route == item[1], "La carte ouvre : " + item[1])
		if item[1] == "credits":
			await capture("credits-1440.png")
			await click("Licenses")
			var license_text := app.find_child("LicenseText", true, false) as TextEdit
			check(license_text != null and license_text.text.contains("GODOT ENGINE") and license_text.text.contains("SIL OPEN FONT LICENSE"), "Les licences sont lisibles dans l’application")
			await key(KEY_ESCAPE)
		await click("HomeButton" if item[1] in ["courses", "catalogue"] else "BackHome")
		check(app.navigation.current_route == "home", "Retour au menu depuis " + item[1])
	await click("CoursesNav")
	check(app.navigation.current_route == "courses", "La navigation supérieure ouvre les cours")
	await key(KEY_ESCAPE)
	check(app.navigation.current_route == "home", "Échap revient au menu")
	var card := app.find_child("GamesCard", true, false) as Button
	card.grab_focus()
	await key(KEY_ENTER)
	check(app.navigation.current_route == "games", "Entrée active la carte au clavier")
	await key(KEY_ESCAPE)
	card = app.find_child("CoursesCard", true, false) as Button
	card.grab_focus()
	await key(KEY_TAB)
	var focus := root.gui_get_focus_owner()
	check(focus != null and focus.name == "GamesCard", "Tab passe à la carte suivante")
	await key(KEY_SPACE)
	check(app.navigation.current_route == "games", "Espace active la carte au clavier")
	await key(KEY_ESCAPE)
	await click("ArtworkSource")
	check(app.navigation.current_route == "credits", "Le crédit photo ouvre les sources locales")
	await click("HomeButton")
	check(app.navigation.current_route == "home", "Le logo revient au menu")
	root.size = Vector2i(1280, 900)
	await frames(8)
	var card_copy_fits := true
	for card_name in ["CoursesCard", "GamesCard", "CatalogueCard", "CreditsCard"]:
		var target := app.find_child(card_name, true, false) as Button
		for label in target.find_children("*", "Label", true, false):
			var copy_rect: Rect2 = label.get_global_rect()
			card_copy_fits = card_copy_fits and target.get_global_rect().encloses(copy_rect)
	check(card_copy_fits, "Les textes des quatre cartes restent dans leurs limites à 1280 px")
	await capture("menu-1280.png")
	root.size = Vector2i(960, 640)
	await frames(8)
	var scroll := app.find_child("PageScroll", true, false) as ScrollContainer
	check(scroll.get_h_scroll_bar().max_value <= scroll.size.x + 1, "Aucun débordement horizontal à 960 px")
	await capture("menu-960.png")
	await click("CreditsCard")
	check(app.navigation.current_route == "credits", "Les cartes restent accessibles après redimensionnement et défilement")
	await click("BackHome")
	await capture("menu-960-bottom.png")
	print("MENU RESULT: %d failures" % failures)
	app.queue_free()
	await frames()
	quit(1 if failures else 0)
