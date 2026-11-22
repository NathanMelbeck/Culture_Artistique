extends Button

signal dropped(card: String, slot: String)
signal returned(card: String)
signal cancelled(face: Button, from_global: Vector2)
var dragging := false
var drop_ring: Panel
var session: FriezeSession
var card_id := ""
var slot_id := ""
var hand_target := false

func _get_drag_data(_at: Vector2) -> Variant:
	if session == null or hand_target or card_id.is_empty() or session.phase != "placement" or session.locked(session.placed_slot(card_id)):
		return null
	dragging = true
	var ghost := Control.new()
	ghost.scale = get_global_transform().get_scale().abs()
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
	var allowed := not slot_id.is_empty() and session.can_place(id, slot_id)
	if is_instance_valid(drop_ring):
		drop_ring.visible = allowed
	return allowed

func _drop_data(at: Vector2, data: Variant) -> void:
	if not _can_drop_data(at, data):
		return
	if hand_target:
		returned.emit(data.id)
	else:
		dropped.emit(data.id, slot_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_DRAG_END:
		if is_instance_valid(drop_ring):
			drop_ring.hide()
	if what == NOTIFICATION_DRAG_END and dragging:
		dragging = false
		if is_inside_tree() and not get_viewport().gui_is_drag_successful():
			cancelled.emit(self,get_global_mouse_position())
