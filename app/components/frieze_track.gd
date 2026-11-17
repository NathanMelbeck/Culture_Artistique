class_name FriezeTrack
extends HBoxContainer

func _ready() -> void:
	add_theme_constant_override("separation", 18)
	resized.connect(queue_redraw)

func _draw() -> void:
	if get_child_count() == 0:
		return
	draw_line(Vector2(0, 30), Vector2(size.x, 30), AppTheme.BRONZE, 2, true)
	for child in get_children():
		if child is Control:
			draw_circle(Vector2(child.position.x + child.size.x / 2, 30), 4, AppTheme.BRONZE, true, -1, true)
