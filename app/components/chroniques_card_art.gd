extends RefCounted

const BACK := preload("res://assets/frieze/marquetry.png")
const FACE := preload("res://assets/frieze/plain.png")
const GOLD := preload("res://assets/frieze/gilding.svg")

static func layer(parent: Control, artwork: Texture2D) -> TextureRect:
	var layer_texture := TextureRect.new()
	layer_texture.texture = artwork
	layer_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(layer_texture)
	layer_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer_texture
