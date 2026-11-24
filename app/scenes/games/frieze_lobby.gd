extends PanelContainer

const Table = preload("res://scenes/games/chroniques.gd")
const MODES := {
	"classic": ["Frise classique", "Retrouvez les deux bornes, puis associez les cartes aux dates du plateau."],
	"markers": ["Repères de périodes", "Retrouvez de mémoire le début et la fin de chaque période."],
	"free": ["Frise libre", "Déposez chaque événement sur un axe à l’échelle ou saisissez son année."]
}
var controller
var margins := MarginContainer.new()
var column := VBoxContainer.new()
var controls: HFlowContainer
var summary: Label
var start: Button
var quantity: SpinBox
var all_button: Button
var limits := Vector2i.ZERO
var selection: Array

func _ready() -> void:
	add_theme_stylebox_override("panel", AppTheme.box(Table.DARK, Color("#49625c"), 14))
	var felt := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/frieze/table.png")
	atlas.region = Rect2(268,245,1040,410)
	felt.texture = atlas
	felt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	felt.stretch_mode = TextureRect.STRETCH_SCALE
	felt.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(felt)
	add_child(margins)
	resized.connect(fit_margins)
	fit_margins()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margins.add_child(layout)
	var nav := HBoxContainer.new()
	layout.add_child(nav)
	button(nav, "GamesBack", "← Les jeux", func():
		controller.mode = "catalogue"
		controller.lobby_scroll = 0
		controller._refresh())
	var gallery: bool = controller.mode == "collection"
	nav.add_spacer(false)
	title(nav, "C H R O N I Q U E S", 19, Table.GOLD)
	nav.add_spacer(false)
	if gallery:
		button(nav, "OpenFrieze", "Préparer une partie", controller._show_setup)
	else:
		button(nav, "OpenCollection", "Collection", controller.open_collection)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 18)
	scroll.add_child(column)
	title(column, "Collection de Chroniques" if gallery else "Préparer votre frise", 34)
	if gallery:
		collection()
	else:
		controls = HFlowContainer.new()
		setup()
		layout.add_child(controls)
	scroll.set_deferred("scroll_vertical", controller.lobby_scroll)
	scroll.get_v_scroll_bar().value_changed.connect(func(v): controller.lobby_scroll = int(v))

func fit_margins() -> void:
	var side := maxi(18,roundi((size.x-1180)/2))
	for edge in ["margin_left","margin_right"]: margins.add_theme_constant_override(edge,side)
	for edge in ["margin_top","margin_bottom"]: margins.add_theme_constant_override(edge,clampi(roundi(size.y*0.04),8,34))

func title(parent: Control, value: String, px: int, color := Table.CREAM) -> Label:
	var text := AppTheme.label(value, px, color, px >= 22)
	text.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HFlowContainer or parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(text)
	return text

func button(parent: Control, id: String, value: String, callback: Callable, selected := false) -> Button:
	var b := Button.new()
	b.name = id
	b.text = value
	b.custom_minimum_size.y = 40
	b.add_theme_font_size_override("font_size", 17)
	for state in ["font_color","font_focus_color","font_hover_color","font_pressed_color"]:
		b.add_theme_color_override(state, Table.CREAM)
	b.add_theme_color_override("font_disabled_color", Table.MUTED)
	for state in ["normal","hover","pressed"]:
		b.add_theme_stylebox_override(state, AppTheme.box(Color("#34564f") if selected or state != "normal" else Color("#193638"), Table.GOLD if selected else Color("#56716a"), 8))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func setup() -> void:
	var modes := HFlowContainer.new()
	column.add_child(modes)
	for id in MODES:
		button(modes,"Mode_"+id,MODES[id][0],func():
			controller.game_mode = id
			controller._refresh(), controller.game_mode == id)
	title(column, MODES[controller.game_mode][1], 17, Table.MUTED)
	title(column, "Périodes", 24)
	title(column,"Choisissez vos périodes. Celles situées entre deux choix sont incluses automatiquement.",16,Table.MUTED)
	var groups := HFlowContainer.new()
	column.add_child(groups)
	for group in controller.repository.groups:
		button(groups, "Group_"+group.id, group.title, func():
			controller.anchors = group.periods.duplicate()
			controller._refresh())
	selection = controller.repository.resolve_periods(controller.anchors)
	var grid := HFlowContainer.new()
	column.add_child(grid)
	for period in controller.repository.periods:
		var check := CheckBox.new()
		var selected := selection.any(func(p): return p.id == period.id)
		var auto_added: bool = selected and period.id not in controller.anchors
		check.name = "SelectPeriod_"+period.id
		check.text = period.title + (" · incluse" if auto_added else "")
		check.tooltip_text = "Incluse entre les deux périodes choisies." if auto_added else period.scope
		check.button_pressed = selected
		check.custom_minimum_size = Vector2(235,92)
		for state in ["normal","hover","pressed","hover_pressed"]:
			check.add_theme_stylebox_override(state, AppTheme.box(Color("#e9dfc8") if selected else Color("#1c393b"), Table.COLORS.get(period.id,Table.GOLD) if selected else Color("#50685f"),10))
		for state in ["font_color","font_pressed_color","font_focus_color","font_hover_color","font_hover_pressed_color"]:
			check.add_theme_color_override(state,Table.INK if selected else Table.CREAM)
		var ribbon := ColorRect.new()
		ribbon.mouse_filter = MOUSE_FILTER_IGNORE
		ribbon.color = Table.COLORS.get(period.id,Table.GOLD)
		check.add_child(ribbon)
		ribbon.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
		ribbon.offset_left = 12
		ribbon.offset_right = -12
		ribbon.offset_top = 8
		ribbon.offset_bottom = 11
		check.toggled.connect(controller._toggle_period.bind(period.id))
		grid.add_child(check)
	if not controller._message.is_empty(): title(column,controller._message,15,Table.GOLD)
	limits = controller.repository.event_limits(controller.repository.event_pools(selection))
	if controller.game_mode != "markers":
		var row := HFlowContainer.new()
		column.add_child(row)
		title(row,"Événements à placer",20)
		quantity = SpinBox.new()
		quantity.name = "EventCount"
		quantity.min_value = limits.x
		quantity.max_value = limits.y
		quantity.value = clampi(controller.requested_events, limits.x, limits.y) if not controller.all_events else limits.y
		quantity.editable = not controller.all_events and limits.x != limits.y
		quantity.custom_minimum_size = Vector2(100,40)
		row.add_child(quantity)
		quantity.value_changed.connect(func(v):
			controller.requested_events = int(v)
			update_summary())
		all_button = button(row,"AllEvents","Tous",func():
			controller.all_events = not controller.all_events
			controller._refresh(), controller.all_events)
		title(row,"%d événements disponibles pour ces périodes" % limits.y,16,Table.MUTED)
	summary = title(column, "", 18, Table.GOLD)
	summary.name = "SelectionSummary"
	button(controls,"ClearPeriods","Tout effacer",func():
		controller.anchors.clear()
		controller._message = ""
		controller._refresh())
	start = button(controls,"StartFrieze","Distribuer les cartes  →",controller._start_game,true)
	if controller.session != null and not controller.resume_anchors.is_empty():
		button(controls, "ResumeFrieze", "Reprendre ma partie", controller.resume_game)
	update_summary()

func update_summary() -> void:
	var markers: int = controller.repository.boundary_cards_for(selection,controller.game_mode == "markers").size() if controller.game_mode != "free" else 0
	var n := int(quantity.value) if quantity != null else 0
	start.disabled = n + markers == 0
	if selection.is_empty():
		summary.text = "Sélectionnez au moins une période."
	elif controller.game_mode == "markers":
		summary.text = "%d repères à retrouver de mémoire" % markers
	else:
		summary.text = "%d événements + %d repères = %d cartes à poser" % [n,markers,n+markers]
		if controller.game_mode == "classic": summary.text += "   ·   2 questions de bornes avant la distribution"
	if not start.disabled:
		var worked := n + markers + (2 if controller.game_mode == "classic" else 0)
		var capacity := ProgressRepository.pack_size(worked)
		summary.text += "\nLot de fin de partie · jusqu’à %d %s" % [capacity,"carte normale" if capacity == 1 else "cartes normales"]

func collection() -> void:
	var options := ["Toutes", "Normales acquises", "Dorées acquises", "À revoir"]
	var tabs := HFlowContainer.new()
	column.add_child(tabs)
	for i in options.size():
		button(tabs,"Filter_"+str(i),options[i],func():
			controller.collection_filter = i
			controller.lobby_scroll = 0
			controller._refresh(),controller.collection_filter == i)
	title(column,"Au bilan, le lot révèle des cartes normales parmi celles travaillées. Une normale déjà possédée en début de partie devient dorée à 7 marques. Une première réponse juste vaut 1 marque en classique et 2 en frise libre ou en mode Repères.",17,Table.MUTED)
	var legend := HFlowContainer.new()
	column.add_child(legend)
	for rank in ChronologyRepository.RARITIES.values(): title(legend,"◆ "+rank[0]+"    ",16,rank[1])
	var catalog: Array = controller.repository.collection_cards()
	var playable: Array = controller.repository.events_for(controller.repository.periods).map(func(e): return e.id)
	var shown := 0
	for available in [true,false]:
		var grid := HFlowContainer.new()
		for card in catalog:
			var marker: bool = card.get("kind") == "period_boundary"
			if (marker or card.id in playable) != available: continue
			var owned: Dictionary = controller.progress_repository.collectible(card.id)
			if controller.collection_filter == 1 and not owned.normal: continue
			if controller.collection_filter == 2 and owned.marks < ProgressRepository.GOLD_THRESHOLD: continue
			if controller.collection_filter == 3 and not owned.review: continue
			if grid.get_parent() == null:
				title(column,"Cartes jouables" if available else "Hors des bornes des fiches actuelles",22)
				column.add_child(grid)
			collection_tile(grid,card,owned,marker)
			shown += 1
		if grid.get_parent() == null: grid.free()
	if shown == 0: title(column,"Aucune carte dans cette sélection.",17,Table.MUTED)

func collection_tile(grid: Control, card: Dictionary, owned: Dictionary, marker: bool) -> void:
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(196,278)
	grid.add_child(tile)
	var golden: bool = owned.marks == ProgressRepository.GOLD_THRESHOLD
	if not owned.normal:
		Table.CardArt.layer(tile,Table.CardArt.BACK)
		tile.accessibility_name = "Carte à découvrir"
		return

	Table.CardArt.layer(tile,Table.CardArt.FACE)
	if golden: Table.CardArt.layer(tile,Table.CardArt.GOLD)
	var rank: Array = ChronologyRepository.RARITIES[card.get("rarity","common")]
	var category: String = "Repère de période" if marker else rank[0]
	tile.tooltip_text = card.title + " · " + category
	tile.accessibility_name = tile.tooltip_text
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",4)
	tile.add_child(body)
	body.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	body.offset_left = 16
	body.offset_right = -16
	body.offset_top = 17
	body.offset_bottom = -17
	body.mouse_filter = MOUSE_FILTER_IGNORE
	var stripe := ColorRect.new()
	stripe.color = Table.period_color(card.periods[0]) if marker else rank[1]
	stripe.custom_minimum_size.y = 4
	body.add_child(stripe)
	var detail := Color("#594824")
	title(body,category,14,detail).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if card.has("image"):
		var artwork := TextureRect.new()
		artwork.texture = load(card.image)
		artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		artwork.custom_minimum_size.y = 60
		artwork.tooltip_text = card.image_credit
		body.add_child(artwork)
	var title_area := Control.new()
	title_area.mouse_filter = MOUSE_FILTER_IGNORE
	title_area.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(title_area)
	var caption := title(title_area,card.title,18,Table.INK)
	caption.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	caption.clip_text = true
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_area.resized.connect(func():
		var font := caption.get_theme_font("font")
		var px := 18
		while px > 12 and font.get_multiline_string_size(caption.text,HORIZONTAL_ALIGNMENT_CENTER,title_area.size.x,px).y > title_area.size.y:
			px -= 1
		caption.add_theme_font_size_override("font_size",px))
	title(body,"Normale  ✓",13,detail).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title(body,"✦ Dorée acquise" if golden else "Maîtrise   %d / %d" % [owned.marks,ProgressRepository.GOLD_THRESHOLD],14,detail).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
