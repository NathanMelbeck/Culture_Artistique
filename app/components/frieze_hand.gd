class_name FriezeHand
extends Control

signal card_selected(id: String)
signal card_returned(id: String)
var session: FriezeSession
var selected_id := ""
var _cards: Array[FriezeCard] = []

func _ready() -> void:
	custom_minimum_size.y = 154
	mouse_filter = Control.MOUSE_FILTER_PASS
	for id in session.hand:
		var card := FriezeCard.new()
		card.name = "HandCard_" + id
		card.card_id = id
		card.session = session
		card.selected = id == selected_id
		card.text = session.event(id)["title"]
		card.tooltip_text = "Glisser vers une date, ou sélectionner puis cliquer sur un emplacement."
		card.pressed.connect(func() -> void: card_selected.emit(id))
		add_child(card)
		_cards.append(card)
	resized.connect(_arrange)
	_arrange.call_deferred()

func _arrange() -> void:
	if _cards.is_empty():
		return
	var width := clampf(size.x / 7.0 + 4, 120, 174)
	var step := minf(width - 6, (size.x - width) / maxf(1, _cards.size() - 1))
	var left := (size.x - (width + step * (_cards.size() - 1))) / 2
	for index in _cards.size():
		var card := _cards[index]
		card.home_position = Vector2(left + step * index, 8)
		card.position = card.home_position
		card.size = Vector2(width, 145)
		card.add_theme_font_size_override("font_size", 13 if width < 140 else 15)
		var normal := card.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		normal.content_margin_left = 10
		normal.content_margin_right = 20
		card.add_theme_stylebox_override("normal", normal)
		var hover := card.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
		hover.content_margin_left = 10
		hover.content_margin_right = 20
		card.add_theme_stylebox_override("hover", hover)

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == "frieze_card" and data.get("session") == session.get_instance_id() and session.phase == "placement" and session.hand.size() < FriezeSession.HAND_LIMIT and not session.placed_slot(data.get("id", "")).is_empty()

func _drop_data(_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_position, data):
		card_returned.emit(data["id"])
