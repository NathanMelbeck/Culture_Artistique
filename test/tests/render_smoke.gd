extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("RENDER: loading scene")
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	print("RENDER: scene ready")
	root.size = Vector2i(1440, 900)
	root.position = Vector2i(80, 80)
	root.show()
	for frame in 6:
		await process_frame
	print("RENDER: first frames processed")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs")
	root.get_texture().get_image().save_png("res://docs/course.png")
	app.navigate("quiz")
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/quiz.png")
	app.navigate("timeline")
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/timeline.png")
	print("RENDER: 3 screenshots saved")
	var license_file := FileAccess.open("res://docs/GODOT-LICENSE.txt", FileAccess.WRITE)
	license_file.store_string(Engine.get_license_text())
	license_file.store_string("\n\nTHIRD-PARTY COMPONENTS\n\n" + JSON.stringify(Engine.get_license_info(), "\t"))
	license_file.close()
	quit()
