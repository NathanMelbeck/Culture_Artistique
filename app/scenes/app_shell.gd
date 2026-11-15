extends Control

const HOME := preload("res://scenes/main_menu/main_menu.tscn")
const SECTION := preload("res://scenes/section_preview/section_preview.tscn")
const CREDITS := preload("res://scenes/credits/credits.tscn")
const REVISION := preload("res://scenes/revision_sheets/revision_sheets.tscn")
var navigation := NavigationService.new()
var media_repository := MediaRepository.new()
var revision_repository := RevisionRepository.new()
var _revision_state: Dictionary = {}
var _page: Control
var _page_host: VBoxContainer
var _scroll: ScrollContainer
var _header_margin: MarginContainer
var _body_margin: MarginContainer
var _footer_margin: MarginContainer
var _nav_buttons: Dictionary = {}
var _home_button: Button
var _back_button: Button
var _offline: Label
var _scroll_positions: Dictionary = {}

func _ready() -> void:
	theme = AppTheme.create()
	_build_shell()
	navigation.route_changed.connect(_show_route)
	resized.connect(_adapt)
	_adapt()
	_show_route("home")

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = AppTheme.IVORY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)
	_header_margin = AppTheme.margin(0)
	layout.add_child(_header_margin)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 96
	_header_margin.add_child(header)
	_home_button = AppTheme.quiet_button("")
	_home_button.name = "HomeButton"
	_home_button.tooltip_text = "Culture Artistique — Retour au menu"
	_home_button.custom_minimum_size = Vector2(230, 70)
	_home_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_home_button.pressed.connect(navigation.go_home)
	header.add_child(_home_button)
	var brand := HBoxContainer.new()
	brand.position = Vector2(0, 12)
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_button.add_child(brand)
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/icons/brand.svg")
	logo.custom_minimum_size = Vector2(36, 42)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand.add_child(logo)
	var brand_text := AppTheme.label("C U L T U R E\nA R T I S T I Q U E", 12)
	brand_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand.add_child(brand_text)
	var nav := HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 18)
	header.add_child(nav)
	for item in [["courses", "Cours"], ["revision", "Fiche"], ["games", "Jeux"], ["credits", "Crédits"]]:
		var button := AppTheme.quiet_button(item[1])
		button.name = item[0].capitalize() + "Nav"
		button.custom_minimum_size.x = 78
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(navigation.navigate.bind(item[0]))
		_nav_buttons[item[0]] = button
		nav.add_child(button)
	_offline = AppTheme.label("●  Disponible hors ligne", 12, AppTheme.MUTED)
	_offline.custom_minimum_size.x = 230
	_offline.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_offline)
	layout.add_child(AppTheme.divider())
	_scroll = ScrollContainer.new()
	_scroll.name = "PageScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	layout.add_child(_scroll)
	_body_margin = AppTheme.margin(0)
	_body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_margin.add_theme_constant_override("margin_top", 28)
	_body_margin.add_theme_constant_override("margin_bottom", 24)
	_scroll.add_child(_body_margin)
	_page_host = VBoxContainer.new()
	_page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_host.add_theme_constant_override("separation", 24)
	_body_margin.add_child(_page_host)
	_back_button = AppTheme.quiet_button("←  Accueil")
	_back_button.name = "BreadcrumbHome"
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back_button.pressed.connect(navigation.go_home)
	_page_host.add_child(_back_button)
	layout.add_child(AppTheme.divider())
	_footer_margin = AppTheme.margin(0)
	layout.add_child(_footer_margin)
	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 56
	_footer_margin.add_child(footer)
	var signature := AppTheme.label("CULTURE ARTISTIQUE · UN REGARD SUR LES ÉPOQUES", 10, AppTheme.MUTED)
	signature.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(signature)
	var quit_button := AppTheme.quiet_button("Quitter")
	quit_button.name = "QuitButton"
	quit_button.add_theme_font_size_override("font_size", 12)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	footer.add_child(quit_button)

func _show_route(route: String) -> void:
	var was_keyboard := false
	if is_instance_valid(_page):
		if navigation.current_route != "revision" and _page.has_method("get_view_state"):
			_revision_state = _page.get_view_state()
		_scroll_positions[_page.name] = _scroll.scroll_vertical
		was_keyboard = get_viewport().gui_get_focus_owner() != null
		_page_host.remove_child(_page)
		_page.queue_free()
	_back_button.visible = route not in ["home", "revision"]
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if route == "revision" else ScrollContainer.SCROLL_MODE_AUTO
	if route == "home":
		_page = HOME.instantiate()
		_page.media_repository = media_repository
	elif route == "credits":
		_page = CREDITS.instantiate()
		_page.media_repository = media_repository
	elif route == "revision":
		_page = REVISION.instantiate()
		_page.repository = revision_repository
		_page.view_state = _revision_state
	else:
		_page = SECTION.instantiate()
		_page.route = route
	_page.name = route
	_page.destination_requested.connect(navigation.navigate)
	_page_host.add_child(_page)
	for key in _nav_buttons:
		var button: Button = _nav_buttons[key]
		button.add_theme_color_override("font_color", AppTheme.FOREST if key == route else AppTheme.MUTED)
		button.add_theme_stylebox_override("normal", AppTheme.box(AppTheme.SAGE if key == route else Color.TRANSPARENT, Color.TRANSPARENT, 6, 0))
	_restore_view.call_deferred(was_keyboard)

func _restore_view(with_focus: bool) -> void:
	await get_tree().process_frame
	_scroll.scroll_vertical = _scroll_positions.get(_page.name, 0)
	if with_focus:
		if navigation.current_route == "home":
			var first := _page.find_child("CoursesCard", true, false) as Button
			if first != null:
				first.grab_focus()
		elif navigation.current_route == "revision":
			_nav_buttons["revision"].grab_focus()
		else:
			_back_button.grab_focus()

func _adapt() -> void:
	var side := maxi(28, int((size.x - 1312) / 2))
	for container in [_header_margin, _body_margin, _footer_margin]:
		container.add_theme_constant_override("margin_left", side)
		container.add_theme_constant_override("margin_right", side)
	_offline.custom_minimum_size.x = 170 if size.x < 1200 else 230

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and navigation.current_route != "home":
		navigation.go_home()
		get_viewport().set_input_as_handled()
