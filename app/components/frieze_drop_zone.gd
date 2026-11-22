extends Button

signal card_hovered(point: Vector2)
signal card_dropped(id: String, point: Vector2)
var session: FriezeSession

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("session") != session.get_instance_id() or session.phase != "placement":
		return false
	var id: String = data.get("id", "")
	var slot := session.placed_slot(id)
	if (id not in session.hand and slot.is_empty()) or session.locked(slot): return false
	card_hovered.emit(at)
	return true

func _drop_data(at: Vector2, data: Variant) -> void:
	if _can_drop_data(at,data): card_dropped.emit(data.id,at)
