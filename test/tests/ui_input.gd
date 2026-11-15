extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int = 3) -> void:
	for index in count:
		await process_frame

func click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	Input.parse_input_event(motion)
	await frames(1)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = position
	Input.parse_input_event(down)
	await frames(1)
	var up := down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await frames()

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func _run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	root.size = Vector2i(1440, 900)
	await frames(6)
	# Les coordonnées proviennent des contrôles réellement disposés à l'écran.
	var nav: Button
	for node in app.find_children("*", "Button", true, false):
		if node.text == "02   Quiz visuel":
			nav = node
	await click_at(nav.get_global_rect().get_center())
	check(app.active_page == "quiz", "Un clic sur la navigation ouvre le quiz")
	var answer: Button
	for node in app.find_children("*", "Button", true, false):
		if node.text.begins_with("A   "):
			answer = node
	await click_at(answer.get_global_rect().get_center())
	check(app.quiz_answer == 0 and app.quiz_score == 1, "Le clic sur une réponse déclenche la correction")
	app.navigate("timeline")
	await frames()
	var source: Control
	var target: Control
	for node in app.find_children("*", "PanelContainer", true, false):
		if node.get_script() == load("res://scripts/timeline_card.gd"):
			if node.card_id == "rome":
				source = node
			if node.slot_index == 0:
				target = node
	var target_position := target.get_global_rect().get_center()
	await click_at(source.get_global_rect().get_center())
	await click_at(target_position)
	check(app.placements[0] == "rome", "La sélection puis le clic sur une case place la carte")
	# Tester aussi le glisser-déposer natif de Control, sans appeler place_card.
	for node in app.find_children("*", "PanelContainer", true, false):
		if node.get_script() == load("res://scripts/timeline_card.gd"):
			if node.card_id == "gothique":
				source = node
			if node.slot_index == 1:
				target = node
	var start := source.get_global_rect().get_center()
	var finish := target.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = start
	Input.parse_input_event(motion)
	var down := InputEventMouseButton.new()
	down.position = start
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await frames(1)
	for index in range(1, 15):
		var move := InputEventMouseMotion.new()
		move.position = start.lerp(finish, float(index) / 14.0)
		move.relative = (finish - start) / 14.0
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(move)
		await frames(1)
	var up := down.duplicate()
	up.position = finish
	up.pressed = false
	Input.parse_input_event(up)
	await frames()
	check(app.placements[1] == "gothique", "Le glisser-déposer natif transfère la carte vers la case")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/input-test.png")
	print("UI RESULT: %d failures" % failures)
	quit(1 if failures else 0)
