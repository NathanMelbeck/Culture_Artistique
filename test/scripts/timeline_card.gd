extends PanelContainer

signal chosen(card_id: String)
signal dropped(card_id: String, slot_index: int)

var card_id := ""
var slot_index := -1
var accepts_drop := false
var drag_started := false

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for child in find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _get_drag_data(_position: Vector2) -> Variant:
	if card_id.is_empty():
		return null
	drag_started = true
	var preview := Label.new()
	preview.text = "  Déplacer la carte  "
	preview.add_theme_font_size_override("font_size", 22)
	preview.modulate = Color("203938")
	set_drag_preview(preview)
	return {"type": "period", "id": card_id}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return accepts_drop and data is Dictionary and data.get("type") == "period"

func _drop_data(_position: Vector2, data: Variant) -> void:
	dropped.emit(str(data["id"]), slot_index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_started = false
		elif not drag_started:
			chosen.emit(card_id)
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_SPACE]:
		chosen.emit(card_id)
		accept_event()
