class_name AppTheme
extends RefCounted

const IVORY := Color("f8f6ef")
const FOREST := Color("243d37")
const SURFACE := Color("fffef8")
const SAGE := Color("e9ecdf")
const BRONZE := Color("a16543")
const MUTED := Color("607267")
const LINE := Color("dcded2")
const LIGHT_TEXT := Color("d7e1d3")
const BODY_FONT = preload("res://assets/fonts/Manrope.ttf")
const TITLE_FONT = preload("res://assets/fonts/Lora.ttf")

static func box(color: Color, border: Color = Color.TRANSPARENT, radius: int = 8, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func create() -> Theme:
	var result := Theme.new()
	var body := FontVariation.new()
	body.base_font = BODY_FONT
	body.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 450.0}
	result.default_font = body
	for control_type in ["Label", "Button", "TextEdit"]:
		result.set_font("font", control_type, body)
	result.default_font_size = 15
	result.set_color("font_color", "Label", FOREST)
	result.set_color("font_color", "Button", FOREST)
	result.set_color("font_hover_color", "Button", FOREST)
	result.set_color("font_pressed_color", "Button", FOREST)
	result.set_color("font_focus_color", "Button", FOREST)
	result.set_stylebox("normal", "Button", box(SURFACE, LINE))
	result.set_stylebox("hover", "Button", box(SAGE, Color("aab9a7")))
	result.set_stylebox("pressed", "Button", box(Color("dce2d2"), FOREST))
	result.set_stylebox("disabled", "Button", box(Color("eeeee8"), LINE))
	result.set_color("font_disabled_color", "Button", Color("89968b"))
	var focus := box(Color.TRANSPARENT, BRONZE, 8, 2)
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	result.set_stylebox("focus", "Button", focus)
	result.set_constant("separation", "VBoxContainer", 16)
	result.set_constant("separation", "HBoxContainer", 16)
	return result

static func label(value: String, font_size: int = 15, color: Color = FOREST, serif: bool = false) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	if serif:
		item.add_theme_font_override("font", TITLE_FONT)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

static func paragraph(value: String, font_size: int = 16, color: Color = MUTED) -> Label:
	var item := label(value, font_size, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_constant_override("line_spacing", 7)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

static func eyebrow(value: String) -> Label:
	return label(value, 11, BRONZE)

static func margin(amount: int) -> MarginContainer:
	var item := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		item.add_theme_constant_override("margin_" + side, amount)
	return item

static func spacer(height: float = 0.0, expand: bool = false) -> Control:
	var item := Control.new()
	item.custom_minimum_size.y = height
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		item.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return item

static func divider() -> HSeparator:
	var item := HSeparator.new()
	var style := StyleBoxLine.new()
	style.color = LINE
	style.thickness = 1
	item.add_theme_stylebox_override("separator", style)
	return item

static func quiet_button(value: String) -> Button:
	var item := Button.new()
	item.text = value
	item.custom_minimum_size.y = 44
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.add_theme_stylebox_override("normal", box(Color.TRANSPARENT, Color.TRANSPARENT, 6, 0))
	item.add_theme_color_override("font_color", MUTED)
	return item
