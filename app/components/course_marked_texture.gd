class_name CourseMarkedTexture
extends TextureRect

# Coordinates belong to the displayed source (or its crop), never to the window.
# The same numbered pointers therefore follow the picture in the zoom viewer.
var markers: Array = []

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if texture == null or markers.is_empty():
		return
	var factor := minf(size.x / texture.get_width(), size.y / texture.get_height())
	var picture_size := texture.get_size() * factor
	var origin := (size - picture_size) / 2.0
	for index in markers.size():
		var marker: Dictionary = markers[index]
		var point: Array = marker["point"]
		var label_point: Array = marker.get("label_point", point)
		var target := origin + Vector2(point[0], point[1]) * picture_size
		var badge := origin + Vector2(label_point[0], label_point[1]) * picture_size
		draw_line(badge, target, Color.WHITE, 5.0, true)
		draw_line(badge, target, AppTheme.FOREST, 2.0, true)
		draw_circle(target, 3.5, AppTheme.FOREST, true, -1, true)
		draw_circle(badge, 16.0, Color.WHITE, true, -1, true)
		draw_circle(badge, 14.0, AppTheme.FOREST, true, -1, true)
		var number := String.chr(65 + index)
		var font := AppTheme.BODY_FONT
		var text_size := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		draw_string(font, badge + Vector2(-text_size.x / 2.0, 5.5), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
