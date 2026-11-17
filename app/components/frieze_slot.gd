class_name FriezeSlot
extends FriezeCard

signal card_dropped(card_id: String, slot_id: String)
var slot_id: String

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == "frieze_card" and data.get("session") == session.get_instance_id() and session.can_place(data.get("id", ""), slot_id)

func _drop_data(_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_position, data):
		card_dropped.emit(data["id"], slot_id)

func _get_drag_data(position: Vector2) -> Variant:
	if card_id.is_empty():
		return null
	return super._get_drag_data(position)
