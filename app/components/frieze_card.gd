class_name FriezeCard
extends Button

var card_id: String
var session: FriezeSession
var selected := false
var hand_card := true
var home_position := Vector2.ZERO
var card_height := 145.0

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_theme_font_size_override("font_size", 15)
	var normal := AppTheme.box(AppTheme.SURFACE, AppTheme.BRONZE if selected else AppTheme.LINE, 10, 3 if selected else 1)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", AppTheme.box(Color("f1ead9"), AppTheme.BRONZE, 10, 2))
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))

func _hover(entered: bool) -> void:
	if hand_card:
		z_index = 20 if entered else 0
		position = home_position - Vector2(0, 8 if entered else 0)
		size.y = card_height + (8 if entered else 0)

func _get_drag_data(_position: Vector2) -> Variant:
	if session.phase != "placement":
		return null
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(172, 120)
	preview.add_theme_stylebox_override("panel", AppTheme.box(AppTheme.SURFACE, AppTheme.BRONZE, 10, 2))
	preview.add_child(AppTheme.paragraph(text, 15, AppTheme.FOREST))
	set_drag_preview(preview)
	return {"kind": "frieze_card", "id": card_id, "session": session.get_instance_id()}
