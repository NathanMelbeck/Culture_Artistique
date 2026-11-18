extends Button

signal dropped(card: String, slot: String)
signal returned(card: String)
var session: FriezeSession
var card_id := ""
var slot_id := ""
var hand_target := false

func _get_drag_data(_at: Vector2) -> Variant:
	if hand_target or card_id.is_empty() or session.phase != "placement" or session.locked(session.placed_slot(card_id)):
		return null
	var ghost := Control.new()
	var copy := duplicate(0) as Button
	copy.position = Vector2(-size.x * 0.5, -24)
	copy.rotation = 0
	copy.modulate.a = 0.9
	ghost.add_child(copy)
	set_drag_preview(ghost)
	return {"session": session.get_instance_id(), "id": card_id}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("session") != session.get_instance_id():
		return false
	var id: String = data.get("id", "")
	if hand_target:
		var source := session.placed_slot(id)
		return not source.is_empty() and not session.locked(source) and session.hand.size() < session.HAND_LIMIT
	return not slot_id.is_empty() and session.can_place(id, slot_id)

func _drop_data(at: Vector2, data: Variant) -> void:
	if not _can_drop_data(at, data):
		return
	if hand_target:
		returned.emit(data.id)
	else:
		dropped.emit(data.id, slot_id)
