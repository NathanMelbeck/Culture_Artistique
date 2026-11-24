extends Control
## Chroniques uses the approved 1600 × 1000 composition as a logical canvas.
## The shell scales it uniformly. All cards, dates, counts and choices are live.
const CARD = preload("res://components/chroniques_card.gd")
const CardArt = preload("res://components/chroniques_card_art.gd")
const GOLD := Color("#ddbb73")
const CREAM := Color("#f3ecd9")
const MUTED := Color("#a9bfba")
const INK := Color("#213336")
const DARK := Color("#10272c")
const GOOD := Color("#83d1aa")
const BAD := Color("#ef8f81")
const CHANGED := Color("#b99cde")
const COLORS := {"egypte": Color("#e5b65e"), "grece": Color("#58bebd"), "rome": CHANGED, "roman": Color("#afca78"), "gothique": Color("#ee96a4")}
const DropZone = preload("res://components/frieze_drop_zone.gd")
var date_dialog: Control
var session: FriezeSession
var controller
var canvas: Control
var scroll: ScrollContainer
var track: Control
var pointer := Vector2.ZERO
var overview_marker: Panel
var first_year := 0
var last_year := 0
var years: Array[int] = []
var count_events: int
var board_active := false
var showing_periods := false
var header_count: Label
var slot_cards: Dictionary = {}
var slot_dates: Dictionary = {}
var hand_cards: Dictionary = {}
var hand_count: Label
var discard_button: Button
var draw_button: Button
var deck_count: Label
var deck_caption: Label
var retained_notice: Label
var next_deal_delay := 0.0
var painted_selection := ""
var deck_art: TextureRect
var validate_button: Button
var muted_mark: Label
var highlighted_date: Button
var date_painters: Dictionary = {}
var mouse_dates := true
var compact := false
var flight_layer := Control.new()
const DECK_POSITION := Vector2(1388,698)


func _ready() -> void:
	var matte := ColorRect.new()
	matte.color = Color("#0a171b")
	add_child(matte)
	matte.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	canvas = Control.new()
	canvas.size = Vector2(1600,1000)
	add_child(canvas)
	resized.connect(_fit)
	count_events = session.events.size() if session.game_mode == "markers" else session.events.size() - session.period_count()
	first_year = int(session.start_period.start)
	last_year = int(session.end_period.end)
	flight_layer.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(flight_layer)
	flight_layer.z_index = 10
	var boundary := session.phase in ["start","end"]
	texture(canvas, "bounds" if boundary else "table", 0,0,1600,1000)
	header()
	if boundary:
		bounds()
	elif session.comparing:
		comparison()
	elif session.phase == "result":
		result()
	else:
		board()
	_fit()
	if controller.boundary_feedback != "":
		var notice := label(canvas,"✓  "+controller.boundary_feedback,485,853 if boundary else 637,630,35,18,GOOD)
		controller.boundary_feedback = ""
		var acknowledgement := notice.create_tween()
		acknowledgement.tween_interval(0.65)
		acknowledgement.tween_property(notice,"modulate:a",0.0,0.2)
		acknowledgement.tween_callback(notice.queue_free)

func _fit() -> void:
	var factor := minf(size.x/1600.0,size.y/1000.0)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - canvas.size * factor) / 2.0
	var smaller := factor > 0 and factor < 0.78
	if compact != smaller:
		compact = smaller
		for caption in canvas.find_children("*","Label",true,false):
			if caption.has_meta("design_font"):
				fit_label(caption)

func position_node(parent: Control, node: Control, x: float,y: float,w: float,h: float) -> void:
	parent.add_child(node)
	node.position = Vector2(x,y)
	node.size = Vector2(w,h)

func picture(parent: Control, resource: Texture2D, x: float,y: float,w: float,h: float, contain := false) -> TextureRect:
	var img := TextureRect.new()
	img.texture = resource
	img.mouse_filter = MOUSE_FILTER_IGNORE
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if contain else TextureRect.STRETCH_SCALE
	position_node(parent,img,x,y,w,h)
	return img

func texture(parent: Control, art: String,x: float,y: float,w: float,h: float) -> TextureRect:
	return picture(parent,load("res://assets/frieze/"+art+".png"),x,y,w,h)

func surface(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var style := AppTheme.box(fill,edge,radius)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_content_margin(side,0)
	return style

func box(parent: Control, x: float,y: float,w: float,h: float,fill: Color,edge := Color.TRANSPARENT,r := 9) -> Panel:
	var p := Panel.new()
	p.mouse_filter = MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel",surface(fill,edge,r))
	position_node(parent,p,x,y,w,h)
	return p

func label(parent: Control, value: String,x: float,y: float,w: float,h: float,px := 16,color := CREAM,serif := false,align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var item := AppTheme.label(value,px,color,serif)
	item.mouse_filter = MOUSE_FILTER_IGNORE
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.clip_text = true
	item.size = Vector2(w,h)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	position_node(parent,item,x,y,w,h)
	item.set_meta("design_font",px)
	fit_label(item)
	return item

func fit_label(item: Label) -> void:
	var px := int(item.get_meta("design_font"))
	var preferred := maxi(px,17) if compact else px
	item.add_theme_font_size_override("font_size",preferred)
	while preferred > 9 and item.get_visible_line_count() < item.get_line_count():
		preferred -= 1
		item.add_theme_font_size_override("font_size",preferred)

func style_button(b: Button, clear := false, primary := false) -> void:
	var normal := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("disabled",surface(DARK,Color("#48645f"),9))
	if clear:
		for state in ["normal","hover","pressed","disabled"]:
			b.add_theme_stylebox_override(state,normal)
	else:
		b.add_theme_stylebox_override("normal",surface(GOLD if primary else Color("#163338"),GOLD if primary else MUTED,9))
		for state in ["hover","pressed"]:
			b.add_theme_stylebox_override(state,surface(Color("#f2d99c") if primary else Color("#39514b"),GOLD,9))
	for state in ["font_color","font_focus_color","font_hover_color","font_pressed_color"]:
		b.add_theme_color_override(state,INK if primary else CREAM)
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND

func action(parent: Control,id: String,title: String,x: float,y: float,w: float,h: float,callback: Callable, primary := false, clear := false) -> Button:
	var b := Button.new()
	b.name = id
	b.text = title
	style_button(b,clear,primary)
	b.pressed.connect(callback)
	position_node(parent,b,x,y,w,h)
	return b

func header() -> void:
	var stage := "ÉVÉNEMENTS"
	var counter := "%d / %d" % [session.placements.size()-session.period_count(),count_events]
	var unit := "événements placés"
	if session.game_mode == "markers":
		counter = "%d / %d" % [session.placements.size(), count_events]
		unit = "repères retrouvés"
	if session.phase in ["start","end"]:
		stage = "LES BORNES"
		counter = "01 / 02" if session.phase == "start" else "02 / 02"
		unit = "début de la frise" if session.phase == "start" else "fin de la frise"
	elif session.period_stage_active():
		stage = "LES REPÈRES"
		counter = "%d / %d" % [session.correct_period_count(),session.period_count()]
		unit = "repères validés"
	elif session.phase == "result":
		stage = "CORRECTION" if session.comparing else "FRISE VALIDÉE"
		counter = "%d / %d" % [count_events-session.wrong_slots.size(), count_events]
		unit = "repères retrouvés" if session.game_mode == "markers" else "événements corrects"
	elif session.retrying:
		stage = "SECONDE CHANCE"
		counter = str(session.events.size()-session.placements.size())
		unit = "cartes à replacer"
	var names := PackedStringArray()
	for p in session.periods:
		names.append(short_name(p))
	label(canvas,stage,570,46,460,28,13,GOLD)
	var subtitle := " · ".join(names)
	if session.period_stage_active(): subtitle = "Placez les débuts et fins de période"
	if session.comparing:
		if session.wrong_slots.is_empty():
			subtitle = "Retrouvez tous vos repères"
		else:
			subtitle = "Comparez votre essai à la solution"
			counter = str(session.wrong_slots.size())
			unit = "cartes corrigées"
	label(canvas,subtitle,570,73,460,29)
	header_count = label(canvas,counter,1150,46,170,35,26,GOLD,true,HORIZONTAL_ALIGNMENT_RIGHT)
	label(canvas,unit,1110,81,210,24,13,MUTED,false,HORIZONTAL_ALIGNMENT_RIGHT)
	if session.phase != "result" or session.comparing:
		action(canvas,"QuitFrieze","Quitter",1042,51,126,47,controller.leave_game)
	if session.comparing:
		action(canvas,"ReviewCollection","Voir la collection",345,890,248,41,controller.leave_game.bind("collection"))
	action(canvas,"ChroniquesHome","",52,49,202,60,func(): controller.destination_requested.emit("home"),false,true).tooltip_text = "Retour au menu"
	action(canvas,"ChangePeriods","",1415,48,54,60,controller._show_setup,false,true).tooltip_text = "Choisir les périodes"
	var sound := action(canvas,"Sound","",1363,48,59,60,toggle_sound,false,true)
	sound.tooltip_text = "Activer ou couper les sons de Chroniques"
	muted_mark = label(canvas,"×",1382,74,30,24,21,BAD)
	muted_mark.visible = not controller.sound_enabled

func toggle_sound() -> void:
	controller.sound_enabled = not controller.sound_enabled
	muted_mark.visible = not controller.sound_enabled
	if controller.sound_enabled:
		controller.play_sound()
	else:
		controller.sound_player.stop()

func short_name(period: Dictionary) -> String:
	return str(period.title).trim_suffix(" antique")

func footer(message: String) -> void:
	label(canvas,"HORS LIGNE",70,943,130,28,11,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,message,205,942,1190,32,14,MUTED)

func bounds() -> void:
	var first := session.phase == "start"
	box(canvas,682,174,236,30,DARK,GOLD,15)
	label(canvas,"01 · LE DÉBUT" if first else "02 · LA FIN",682,174,236,30,13,GOLD)
	label(canvas,"Où commence votre histoire ?" if first else "Jusqu’où va votre histoire ?",200,212,1200,72,44,CREAM,true)
	label(canvas,"Choisissez le début de la période la plus ancienne." if first else "Choisissez la fin de la période la plus récente.",200,281,1200,36,20,MUTED)
	label(canvas,"Borne de style · fiche de révision · " + str(session.start_period.title if first else session.end_period.title),290,316,1020,28,17,GOLD)
	var options := session.boundary_choices()
	for i in options.size():
		var year := int(options[i])
		var b := action(canvas,"Boundary_"+str(year),"",180+i*250,413,242,320,controller.answer.bind(year),false,true)
		texture(b,"choice",0,0,242,320)
		label(b,("−" if year < 0 else "") + str(absi(year)),0,95,242,65,44,CREAM,true)
		label(b,"avant J.-C." if year<0 else "après J.-C.",0,158,242,34,15,MUTED)
		label(b,"DÉBUT DE LA FRISE" if first else "FIN DE LA FRISE",0,207,242,30,12,GOLD)
		var glow := box(b,8,10,226,297,Color.TRANSPARENT,GOLD,16)
		var glow_style := glow.get_theme_stylebox("panel") as StyleBoxFlat
		glow_style.shadow_color = Color("#dbb66a58")
		glow_style.shadow_size = 12
		glow.hide()
		var plaque := box(b,34,249,174,38,GOLD,GOLD,8)
		plaque.hide()
		var hint := label(b,"Touche %d" % (i+1),0,244,242,48,14,MUTED)
		var decorations := b.get_children()
		var rest_y: Array[float] = []
		for item in decorations:
			rest_y.append(item.position.y)
		var raise_card := func(active: bool):
			for index in decorations.size():
				decorations[index].position.y = rest_y[index] - (18 if active else 0)
			glow.visible = active
			plaque.visible = active
			hint.text = "→   Choisir" if active else "Touche %d" % (i+1)
			hint.add_theme_color_override("font_color",INK if active else MUTED)
		date_painters[b] = raise_card
		b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		b.mouse_entered.connect(func():
			if mouse_dates: highlight_date(b)
		)
		b.mouse_exited.connect(func():
			if mouse_dates and highlighted_date == b: highlight_date(null)
		)
		b.focus_entered.connect(func():
			if not mouse_dates: highlight_date(b)
		)
		b.focus_exited.connect(func():
			if not mouse_dates and highlighted_date == b: highlight_date(null)
		)
		if year in session.wrong_choices:
			b.disabled = true
			b.modulate = Color("#aa7770")
			hint.text = "Écartée"
		else:
			fade_in(b,0.12)
	label(canvas,controller._message if controller._message else "Une erreur ? Vous pouvez réessayer.",240,752,1120,42,17,BAD if controller._message else MUTED)
	label(canvas,"La pioche arrive après les deux bonnes réponses." if first else "✓   Début trouvé · "+ChronologyRepository.date_label(first_year),200,821,1200,48,16,MUTED if first else GOOD)
	footer("Choisissez une carte · Souris ou touches 1 à 5")

func highlight_date(card: Button) -> void:
	if highlighted_date == card: return
	if is_instance_valid(highlighted_date):
		date_painters[highlighted_date].call(false)
	highlighted_date = card if card != null and not card.disabled else null
	if highlighted_date != null:
		date_painters[highlighted_date].call(true)

func fade_in(node: Control, duration: float) -> void:
	node.modulate.a = 0.18
	node.create_tween().tween_property(node,"modulate:a",1.0,duration)

static func period_color(id: String) -> Color:
	return COLORS.get(id,Color.from_hsv(fposmod(id.hash()*0.618,1.0),0.45,0.85))

func board() -> void:
	if session.game_mode != "classic":
		alternate_board()
		return
	var periods := session.period_stage_active()
	showing_periods = periods
	board_active = session.phase == "placement"
	if periods:
		label(canvas,"POSEZ LES FONDATIONS",76,142,540,32,14,GOLD,false,HORIZONTAL_ALIGNMENT_LEFT)
		label(canvas,"D’abord les périodes. Ensuite, les événements.",76,177,1120,52,30,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
		label(canvas,"Événements en réserve",1230,158,275,40,17,MUTED)
	else:
		overview()
	scroll = ScrollContainer.new()
	scroll.name = "FriezeBoardScroll"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	position_node(canvas,scroll,108,248,1384,392)
	track = Control.new()
	years.append(first_year)
	for e in session.events:
		years.append(int(e.year))
	years.append(last_year)
	track.custom_minimum_size = Vector2(years.size()*222,365)
	scroll.add_child(track)
	var top := 103 if periods else 135
	box(track,0,top-9,track.custom_minimum_size.x,2,GOLD)
	if not periods:
		for i in session.periods.size():
			var p: Dictionary = session.periods[i]
			var start := years.find(int(p.start))
			var end := years.rfind(int(p.end))
			if start >= 0 and end >= start:
				box(track,111+222*start,i*12+5,maxi(3,222*(end-start)),8,period_color(p.id),Color.TRANSPARENT,4)
	for i in years.size():
		var x := 21+i*222
		if i == 0 or i == years.size()-1:
			label(track,ChronologyRepository.date_label(years[i]),x,top-54,180,38,16,GOLD)
			label(track,"DÉBUT" if i==0 else "FIN",x,top+58,180,50,21,GOLD,true)
			continue
		var event: Dictionary = session.events[i-1]
		var id: String = event.id
		var placed: String = session.placements.get(id,"")
		var date := label(track,ChronologyRepository.event_date(event),x-12,top-57,204,42,17,GOOD if session.locked(id) else CREAM)
		date.name = "FriezeDate_"+id
		slot_dates[id] = date
		var face := make_card(track,placed,Rect2(x,top,180,212),id)
		slot_cards[id] = face
		# The printed date shares the card's action and drop rules, with a single keyboard stop.
		var date_hit := CARD.new()
		date_hit.session = session
		date_hit.slot_id = id
		style_button(date_hit,true)
		date_hit.focus_mode = FOCUS_NONE
		position_node(track,date_hit,x-12,top-57,204,52)
		date_hit.pressed.connect(controller.slot_clicked.bind(id))
		date_hit.dropped.connect(controller._place)
	scroll.scroll_horizontal = controller._board_position
	scroll.set_deferred("scroll_horizontal",controller._board_position)
	scroll.get_h_scroll_bar().value_changed.connect(_scrolled)
	if not periods:
		_scrolled(controller._board_position)
	hand()
	update_validation_button()
	if session.phase == "result": return
	date_zone()
	if not periods:
		label(canvas,"Espacement de lecture · les distances ne représentent pas les durées",85,643,760,27,12,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	footer("Les bons repères se verrouillent. Une carte rouge peut revenir en pioche." if periods else ("Replacez les cartes à revoir, puis validez votre nouvelle tentative." if session.retrying else "Glissez une carte sur une date · Au clavier, sélectionnez une carte puis un emplacement."))

func _scrolled(value: float) -> void:
	controller._board_position = roundi(value)
	if not is_instance_valid(overview_marker) or years.size()<2:
		return
	var low := clampi(floori(value / 222),0,years.size()-1)
	var high := clampi(ceili((value+scroll.size.x)/222)-1,low,years.size()-1)
	var left := inverse_lerp(first_year,last_year,years[low])
	var right := inverse_lerp(first_year,last_year,years[high])
	overview_marker.position.x = 270+930*left
	overview_marker.size.x = maxf(12,930*(right-left))

func overview() -> void:
	label(canvas,"PÉRIODES",74,143,140,36,13,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,str(first_year),170,142,85,26,14,MUTED)
	label(canvas,str(last_year),1210,142,85,26,14,MUTED)
	var lane := minf(20,66.0/session.periods.size())
	for i in session.periods.size():
		var p: Dictionary = session.periods[i]
		var start := inverse_lerp(first_year,last_year,p.start)
		var finish := inverse_lerp(first_year,last_year,p.end)
		var x := 270+930*start
		box(canvas,x,161+i*lane,930*(finish-start),lane-3,period_color(p.id),Color.TRANSPARENT,4)
		label(canvas,short_name(p),1292+i%2*103,142+floori(i/2.0)*35,100,35,15,period_color(p.id))
	overview_marker = box(canvas,270,154,160,75,Color.TRANSPARENT,CREAM,8)
	label(canvas,"VUE RAPPROCHÉE",74,284,180,26,11,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)


func board_skin(id: String, slot: String) -> String:
	if session.locked(slot):
		return "right"
	if controller.selected_card == id:
		return "hover"
	if session.period_status(slot) == "wrong":
		return "wrong"
	return "plain"

func make_card(parent: Control,id: String,area: Rect2,slot := "",review := "") -> Button:
	var b := CARD.new()
	b.session = session
	b.card_id = id
	b.slot_id = slot
	b.name = ("FriezeSlot_"+slot) if slot!="" else ("HandCard_"+id)
	style_button(b,true)
	position_node(parent,b,area.position.x,area.position.y,area.size.x,area.size.y)
	var w := area.size.x
	var h := area.size.y
	if id.is_empty():
		box(b,0,0,w,h,Color("#163536"),Color("#546d66"),12)
		box(b,7,7,w-14,h-14,Color.TRANSPARENT,Color("#294744"),8)
		picture(b,preload("res://assets/frieze/cards.svg"),w/2-13,h/2-29,26,26)
		label(b,"Déposer une carte",0,h/2+5,w,35,13,MUTED)
	else:
		var event := session.event(id)
		var period := session.is_period_card(id)
		var status := session.period_status(slot)
		var skin := board_skin(id, slot)
		if review == "changed": skin = "change"
		if review == "incorrect": skin = "wrong"
		if review == "correct": skin = "right"
		texture(b,skin,0,0,w,h).name = "FaceSkin"
		var golden: bool = controller.progress_repository.collectible(id).marks == ProgressRepository.GOLD_THRESHOLD
		if golden:
			CardArt.layer(b,CardArt.GOLD)
		var rank: Array = ChronologyRepository.RARITIES.get(event.get("rarity","common"))
		box(b,12,13,w-24,5,period_color(event.periods[0]) if period else rank[1],Color.TRANSPARENT,2)
		label(b,"REPÈRE DE PÉRIODE" if period else "ÉVÉNEMENT",6,19,w-12,23,11,Color("#735e38"))
		if event.has("image"):
			box(b,13,44,w-26,66,Color("#e2d9c6"),Color.TRANSPARENT,6)
			picture(b,load(event.image),17,47,w-34,61,true)
			label(b,event.title,9,111,w-18,h-143,16,INK,true)
		else:
			label(b,"◆",0,43,w,36,23,GOLD if status!="wrong" else BAD)
			label(b,event.title,10,78,w-20,h-113,18,INK,true)
		if status == "wrong" and review == "":
			var recycle := action(b,"RecyclePeriod_"+id,"↶ Retour en pioche",9,h-40,w-18,32,func():
				if session.return_wrong_period_to_pile(id):
					controller.selected_card = ""
					controller.focus_after = "DrawFriezeCard"
					controller.play_sound()
					controller._refresh()
			)
			recycle.add_theme_font_size_override("font_size",12)
			recycle.add_theme_stylebox_override("normal",surface(Color("#773c38"),BAD,6))
		else:
			var mark := str(event.get("image_credit","Chroniques")).to_upper()
			if golden: mark = "✦ DORÉE · " + mark
			if review=="changed":
				box(b,15,h-30,w-30,21,Color("#594975"),Color.TRANSPARENT,9)
				label(b,"CARTE CORRIGÉE",15,h-30,w-30,21,10,CREAM)
			elif review in ["correct","incorrect"]:
				var right := review == "correct"
				box(b,12,h-29,w-24,21,Color("#27523d") if right else Color("#773c38"),Color.TRANSPARENT,8)
				label(b,"✓  BIEN PLACÉE" if right else "×  À CORRIGER",12,h-29,w-24,21,11,CREAM)
			elif session.locked(slot):
				picture(b,preload("res://assets/frieze/lock.svg"),w/2-9,h-29,18,18)
			else:
				label(b,mark,5,h-29,w-10,22,10,Color("#60573e"))
		b.tooltip_text = event.title if period else "%s · %s" % [event.title,ChronologyRepository.RARITIES[event.get("rarity","common")][0]]
	if review == "":
		b.dropped.connect(controller._place)
		b.cancelled.connect(func(face: Button, point: Vector2):
			fly(face,canvas.get_global_transform().affine_inverse()*point,center_on_canvas(face))
		)
		if slot != "":
			b.drop_ring = box(b,1,1,w-2,h-2,Color("#ddbb7322"),GOLD,10)
			b.drop_ring.hide()
		if slot!="": b.pressed.connect(controller.slot_clicked.bind(slot))
		else: b.pressed.connect(controller.select_card.bind(id))
	else:
		b.focus_mode = FOCUS_NONE
	return b

func hand() -> void:
	texture(canvas,"tray",0,0,1600,1000)
	var zone := CARD.new()
	zone.hand_target = true
	zone.session = session
	zone.name = "FriezeHandPanel"
	style_button(zone,true)
	zone.focus_mode = FOCUS_NONE
	position_node(canvas,zone,55,671,1490,259)
	zone.returned.connect(func(id: String):
		if session.return_to_hand(id):
			controller.selected_card = ""
			controller._refresh()
	)
	label(canvas,"À REPLACER" if session.retrying else "VOTRE MAIN",85,681,160,40,14,GOLD,false,HORIZONTAL_ALIGNMENT_LEFT)
	hand_count = label(canvas,"",85,712,110,32,19,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
	if session.phase == "result":
		label(canvas,"Toutes les cartes ont été placées.",425,728,750,72,26,CREAM,true)
		return
	discard_button = action(canvas,"DiscardFriezeCard","Défausser",75,794,129,44,discard_selected)
	deck_art = picture(canvas,CardArt.BACK,1390,731,117,166)
	for depth in [1,2]:
		var back := picture(deck_art,CardArt.BACK,depth*4,-depth*4,117,166)
		back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	deck_count = label(canvas,"",1393,679,120,44,23,GOLD,true)
	deck_caption = label(canvas,"",1383,904,137,32,13,MUTED)
	draw_button = action(canvas,"DrawFriezeCard","Piocher",1367,892,160,43,func():
		if session.draw_one():
			controller.play_sound()
			controller.focus_after = "HandCard_"+session.hand.back()
			controller._refresh()
	,true)
	if session.retrying:
		retained_notice = label(canvas,"%d événements justes\nconservés en place" % (session.retained_slots.size()-session.period_count()),1250,735,275,82,19,GOOD)
	var origins: Dictionary = controller.retry_origins
	refresh_hand(origins)
	for id in session.draw_pile:
		if origins.has(id):
			var back := picture(flight_layer,CardArt.BACK,0,0,90,126)
			back.position = origins[id] - back.size/2
			var collect := back.create_tween()
			collect.tween_property(back,"position",DECK_POSITION,0.23).set_trans(Tween.TRANS_QUAD)
			collect.tween_callback(back.queue_free)
	controller.retry_origins = {}
	refresh_pile()

func discard_selected() -> void:
	var index := session.hand.find(controller.selected_card)
	if session.discard(controller.selected_card):
		next_deal_delay = 0.15
		controller.focus_after = "HandCard_"+session.hand[index]
		controller.selected_card = ""
		controller.play_sound()
		controller._refresh()
		deck_art.pivot_offset = deck_art.size/2
		var shuffle := deck_art.create_tween()
		shuffle.tween_property(deck_art,"rotation_degrees",-5.0,0.09)
		shuffle.tween_property(deck_art,"rotation_degrees",4.0,0.11)
		shuffle.tween_property(deck_art,"rotation_degrees",0.0,0.10)

func refresh_pile() -> void:
	hand_count.text = "%d / 7"%session.hand.size()
	discard_button.visible = not showing_periods or session.drawable_count() > 0
	discard_button.disabled = not session.can_discard(controller.selected_card)
	var reserved := showing_periods and session.drawable_count() == 0
	deck_count.text = str(session.draw_pile.size() if reserved else session.drawable_count())
	deck_caption.text = "EN RÉSERVE" if reserved else "PIOCHE"
	draw_button.visible = session.can_draw()
	var show_deck := not session.retrying or not session.draw_pile.is_empty()
	deck_art.visible = show_deck
	deck_count.visible = show_deck
	deck_caption.visible = show_deck and not draw_button.visible
	if retained_notice:
		retained_notice.visible = not show_deck
	if session.retrying and not show_deck:
		discard_button.hide()

func can_update_board() -> bool:
	return board_active and session.phase == "placement" and (session.game_mode != "classic" or showing_periods == session.period_stage_active())

func center_on_canvas(node: Control) -> Vector2:
	return canvas.get_global_transform().affine_inverse() * (node.get_global_transform() * (node.size/2))

func fly(face: Button, origin: Vector2, destination: Vector2, delay := 0.0, landing := true) -> void:
	if origin.distance_to(destination) < 2:
		return
	var copy := face.duplicate(0) as Button
	copy.name = "FlyingCard"
	copy.mouse_filter = MOUSE_FILTER_IGNORE
	copy.focus_mode = FOCUS_NONE
	for child in copy.find_children("*","Control",true,false):
		child.name = "Artwork"
		child.mouse_filter = MOUSE_FILTER_IGNORE
		child.focus_mode = FOCUS_NONE
	flight_layer.add_child(copy)
	copy.rotation = 0
	copy.scale = Vector2.ONE
	copy.pivot_offset = copy.size/2
	copy.position = origin-copy.size/2
	copy.modulate = Color.WHITE
	var motion := copy.create_tween()
	if landing:
		face.modulate.a = 0.1
		var reveal := face.create_tween()
		reveal.tween_interval(delay+0.10)
		reveal.tween_property(face,"modulate:a",1.0,0.10)
	if delay > 0:
		copy.modulate.a = 0
		motion.tween_interval(delay)
		motion.tween_property(copy,"modulate:a",1.0,0.04)
	motion.tween_property(copy,"position",destination-copy.size/2,0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.parallel().tween_property(copy,"modulate:a",0.0,0.09).set_delay(0.11)
	motion.tween_callback(copy.queue_free)

func refresh_hand(origins: Dictionary) -> void:
	for id in hand_cards.keys():
		if id not in session.hand:
			var old: Button = hand_cards[id]
			if session.placed_slot(id).is_empty():
				fly(old,center_on_canvas(old),DECK_POSITION+Vector2(70,95),0.0,false)
			retire(old)
			hand_cards.erase(id)
	for index in session.hand.size():
		var id := session.hand[index]
		var offset := index-(session.hand.size()-1)/2.0
		var home := Vector2(719+offset*156,687+absf(offset)*6)
		var face: Button = hand_cards.get(id)
		if face == null:
			face = make_card(canvas,id,Rect2(home,Vector2(162,224)))
			hand_cards[id] = face
			face.pivot_offset = Vector2(81,224)
			face.mouse_entered.connect(lift_hand.bind(face,true))
			face.mouse_exited.connect(lift_hand.bind(face,false))
			face.focus_entered.connect(lift_hand.bind(face,true))
			face.focus_exited.connect(lift_hand.bind(face,false))
		face.set_meta("home",home)
		face.position = home
		face.rotation_degrees = offset*2
		var destination := center_on_canvas(face)
		var origin: Vector2 = origins.get(id,DECK_POSITION+Vector2(70,95))
		var delay := index*0.025 if origins.is_empty() else 0.0
		if not origins.has(id): delay += next_deal_delay
		fly(face,origin,destination,delay)
	next_deal_delay = 0.0

func lift_hand(face: Button, active: bool) -> void:
	if not face.has_meta("home"): return
	if face.has_meta("lift"):
		var previous: Tween = face.get_meta("lift")
		previous.kill()
	var home: Vector2 = face.get_meta("home")
	face.z_index = 3 if active else 0
	var lift := face.create_tween().set_parallel(true)
	face.set_meta("lift",lift)
	lift.tween_property(face,"position",home-Vector2(0,17) if active else home,0.10)
	lift.tween_property(face,"scale",Vector2.ONE*(1.16 if compact else 1.07) if active else Vector2.ONE,0.10)

func retire(node: Control) -> void:
	node.get_parent().remove_child(node)
	node.queue_free()

func select_face(previous: String,current: String) -> void:
	painted_selection = current
	for id in [previous,current]:
		if id == "": continue
		var slot := session.placed_slot(id)
		var face: Button = slot_cards.get(slot) if slot != "" else hand_cards.get(id)
		if face == null: continue
		var image := face.get_node("FaceSkin") as TextureRect
		image.texture = load("res://assets/frieze/"+board_skin(id, slot)+".png")
	refresh_pile()

func update_validation_button() -> void:
	if session.can_validate() and not is_instance_valid(validate_button):
		validate_button = action(canvas,"ValidateFrieze","Valider la frise",1245,638,245,48,controller.validate_board,true)
	elif not session.can_validate() and is_instance_valid(validate_button):
		retire(validate_button)
		validate_button = null

func update_board() -> void:
	if session.game_mode != "classic":
		update_alternate_board()
		return
	var origins := {}
	for face in hand_cards.values():
		origins[face.card_id] = center_on_canvas(face)
	var changed: Array[String] = []
	for slot in slot_cards:
		var face: Button = slot_cards[slot]
		var id: String = face.card_id
		if id != "":
			origins[id] = center_on_canvas(face)
		if id != session.placements.get(slot,""):
			changed.append(slot)
	for slot in changed:
		var face: Button = slot_cards[slot]
		var area := face.get_rect()
		var id: String = session.placements.get(slot,"")
		if face.card_id in session.draw_pile:
			fly(face,center_on_canvas(face),DECK_POSITION+Vector2(70,95),0.0,false)
		retire(face)
		var replacement := make_card(track,id,area,slot)
		slot_cards[slot] = replacement
		slot_dates[slot].add_theme_color_override("font_color",GOOD if session.locked(slot) else CREAM)
		if id != "":
			var destination := center_on_canvas(replacement)
			fly(replacement,origins.get(id,destination),destination)
			if session.is_period_card(id):
				var skin := replacement.get_node("FaceSkin") as TextureRect
				var flash := skin.create_tween()
				flash.tween_interval(0.13)
				flash.tween_property(skin,"self_modulate",GOOD if session.locked(slot) else BAD,0.11)
				flash.tween_property(skin,"self_modulate",Color.WHITE,0.18)
	refresh_hand(origins)
	if painted_selection != controller.selected_card:
		select_face(painted_selection,controller.selected_card)
	refresh_pile()
	update_validation_button()
	if showing_periods:
		header_count.text = "%d / %d" % [session.correct_period_count(),session.period_count()]
	elif session.retrying:
		header_count.text = str(session.events.size()-session.placements.size())
	else:
		header_count.text = "%d / %d" % [session.placements.size()-session.period_count(),count_events]

func result() -> void:
	board()
	# Modal absorbs pointer and keyboard input intended for the underlying board.
	for b in canvas.find_children("*","BaseButton",true,false):
		b.focus_mode = FOCUS_NONE
	var shade := box(canvas,24,130,1552,816,Color("#020d13ed"),Color.TRANSPARENT,20)
	shade.mouse_filter = MOUSE_FILTER_STOP
	fade_in(shade,0.15)
	box(canvas,335,194,930,670,DARK,GOLD,24)
	box(canvas,346,205,908,648,Color.TRANSPARENT,Color("#394e46"),17)
	box(canvas,682,228,236,30,DARK,GOLD,15)
	label(canvas,"FRISE VALIDÉE",682,228,236,30,13,GOLD)
	label(canvas,"L’histoire prend sa place.",365,278,870,76,43,CREAM,true)
	var mistakes := session.wrong_slots.size()
	label(canvas,str(count_events-mistakes),450,336,700,78,53,GOOD,true)
	label(canvas,("repères retrouvés sur %d" if session.game_mode == "markers" else "événements bien placés sur %d")%count_events,430,400,740,40,18,MUTED)
	if mistakes:
		box(canvas,684,445,232,37,DARK,BAD,16)
	label(canvas,"%d cartes à revoir"%mistakes if mistakes else "Toutes les cartes sont à leur place.",395,444,810,41,17,BAD if mistakes else GOOD)
	for i in (2 if mistakes else 1):
		var x := 383+i*428 if mistakes else 597
		box(canvas,x,503,405,262,Color("#18363a"),Color("#48645f"),14)
		picture(canvas,preload("res://assets/frieze/retry.svg") if i else preload("res://assets/frieze/eye.svg"),x+24,527,27,27)
		label(canvas,("Voir les erreurs" if mistakes else "Revoir la frise") if i==0 else "Refaire les mauvaises",x+24,557,361,49,25,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
		label(canvas,("Retrouvez les œuvres, les dates et les fiches de période." if mistakes == 0 else "Comparez votre essai à la bonne chronologie.") if i==0 else "Gardez vos bonnes réponses. Replacez uniquement les cartes à corriger.",x+24,602,360,76,16,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
		if i==0:
			action(canvas,"ShowSolution","Explorer la frise" if mistakes == 0 else "Voir la correction",x+24,696,357,49,func():
				session.show_solution()
				controller.animate_correction = true
				controller.comparison_index = 0
				controller._refresh()
			)
		else:
			action(canvas,"RetryErrors","Réessayer les %d cartes"%mistakes,x+24,696,357,49,func():
				if session.retry_errors():
					for slot in session.wrong_slots:
						if session.game_mode != "classic": continue
						var from := center_on_canvas(slot_cards[slot])
						from.x = clampf(from.x,scroll.position.x,scroll.position.x+scroll.size.x)
						controller.retry_origins[session.submitted[slot]] = from
					controller._refresh()
			,true)
	footer("Retrouvez les œuvres et leurs dates." if mistakes == 0 else "Choisissez votre façon de revoir les erreurs.")
	action(canvas,"ReplayFrieze","Recommencer",830,786,286,51,controller._start_game,false,true)
	action(canvas,"ShowReward",reward_button_text(),475,786,350,51,reward_dialog,true)
	action(canvas,"QuitFrieze","Quitter",429,887,278,46,controller.leave_game)
	action(canvas,"ResultCollection","Voir la collection",735,887,432,46,controller.leave_game.bind("collection"))
	if not session.new_gold.is_empty():
		label(canvas,"✦ %d nouvelle(s) carte(s) dorée(s)" % session.new_gold.size(),445,842,710,36,17,GOLD)

func comparison() -> void:
	var perfect := session.wrong_slots.is_empty()
	label(canvas,"%d cartes justes conservées" % (count_events-session.wrong_slots.size()),1240,164,290,38,14,GOOD)
	var ids := session.wrong_slots.duplicate()
	if controller.review_all or perfect:
		ids.clear()
		for e in session.events:
			ids.append(e.id)
	var index := clampi(controller.comparison_index,0,ids.size()-1)
	var page_start := index-index%2
	var original_centers := {}
	label(canvas,"→",648,434,36,55,27,GOLD)
	label(canvas,"TOUTE LA FRISE EST JUSTE" if perfect else "CHAQUE ERREUR DEVIENT UN REPÈRE",76,144,880,39,13,GOLD,false,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,"Votre chronologie en détail." if perfect else "Votre frise, avant et après.",76,182,1080,56,38,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
	for side in 2:
		var x := 73+side*609
		box(canvas,x,259,578,409,DARK,Color("#45594f"),18)
		label(canvas,"PLACEMENT INITIAL" if side==0 else ("REPÈRES ATTENDUS" if perfect else "CORRECTION AUTOMATIQUE"),x+27,275,510,35,13,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
		label(canvas,"Votre essai" if side==0 else "La bonne chronologie",x+27,302,520,46,25,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
		box(canvas,x+29,399,520,1,GOLD,Color.TRANSPARENT,0)
		for offset in mini(2,ids.size()-page_start):
			var slot: String = ids[page_start+offset]
			var id: String = session.submitted[slot] if side==0 else session.placements[slot]
			var cx := x+78+offset*238
			var placement_date := ChronologyRepository.event_date(session.event(slot))
			if side == 0 and session.game_mode == "free":
				placement_date = ChronologyRepository.date_label(session.submitted_years[slot])
			label(canvas,placement_date,cx-22,349,226,49,16)
			var state := "correct"
			if slot in session.wrong_slots:
				state = "incorrect" if side == 0 else "changed"
			var b := make_card(canvas,id,Rect2(cx,407,182,224),"",state)
			b.focus_mode = FOCUS_ALL
			b.name = ("Original_" if side==0 else "Correction_")+slot
			b.pressed.connect(change_comparison.bind(page_start+offset,side == 0))
			if side == 0:
				original_centers[id] = b.position + b.size/2
			elif controller.animate_correction and state == "changed":
				if original_centers.has(id):
					fly(b,original_centers[id],b.position+b.size/2)
				else:
					fade_in(b,0.2)
	controller.animate_correction = false
	box(canvas,1283,259,245,409,Color("#152e32"),Color("#4d6256"),18)
	label(canvas,"Frise complète" if controller.review_all or perfect else "Cartes corrigées",1297,304,217,76,24,CREAM,true)
	label(canvas,"Sélectionnez une œuvre ou un repère pour retrouver sa date et son explication.",1304,383,203,106,16,MUTED)
	if not perfect:
		action(canvas,"ReviewScope","Erreurs seulement" if controller.review_all else "Toute la frise",1305,494,200,42,func():
			controller.review_all = not controller.review_all
			change_comparison(0)
		)
	label(canvas,"%d / %d" % [index+1,ids.size()],1305,543,199,44,19,CHANGED)
	var prev := action(canvas,"PreviousReview","←",1308,597,84,43,change_comparison.bind(index-1))
	prev.disabled = index == 0
	var next := action(canvas,"NextReview","→",1415,597,84,43,change_comparison.bind(index+1))
	next.disabled = index == ids.size()-1
	var slot: String = ids[index]
	var id: String = session.submitted[slot] if controller.review_original else session.placements[slot]
	var event := session.event(id)
	var location := session.event(slot)
	var dates := "Date attendue · "+ChronologyRepository.event_date(event)
	if event.get("accepted_to",event.year) != event.get("year_end",event.year):
		dates += "   ·   Années acceptées de %s à %s" % [ChronologyRepository.date_label(event.accepted_from),ChronologyRepository.date_label(event.accepted_to)]
	if controller.review_original and slot in session.wrong_slots:
		var initial := ChronologyRepository.date_label(session.submitted_years[slot]) if session.game_mode == "free" else ChronologyRepository.event_date(location)
		dates = "Votre placement · "+initial+"     |     "+dates
	box(canvas,74,697,1185,182,Color("#18363a"),Color("#4b6259"),15)
	label(canvas,dates,100,706,1080,37,17,GOLD,false,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,event.title,100,742,1110,48,24,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT).name = "ReviewEventTitle"
	label(canvas,event.explanation,100,790,1125,82,17,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	if event.get("kind")=="period_boundary":
		action(canvas,"ReviewFriezeSheet","Revoir la fiche",1283,704,245,48,func(): controller.revision_requested.emit(event.source.sheet_id))
	else:
		action(canvas,"ReviewFriezeCourse","Revoir le cours",1283,704,245,48,func(): controller.course_requested.emit(event.course_id,event.chapter))
		action(canvas,"FriezeSource","Source · Internet ↗",1283,834,245,44,func(): OS.shell_open(event.source.url))
	action(canvas,"ShowReward",reward_button_text(),76,890,248,41,reward_dialog)
	action(canvas,"MarkReview","✓ À revoir" if controller.progress_repository.collectible(id).review else "Marquer à revoir",1283,889,245,42,func():
		controller.progress_repository.toggle_review(id)
		controller._refresh())
	action(canvas,"ReplayFrieze","Nouvelle partie",1283,771,245,48,controller._start_game,true)
	footer("À gauche, votre placement. À droite, la réponse correcte.")

func change_comparison(index: int, original := false) -> void:
	controller.review_original = original
	controller.comparison_index = index
	controller._refresh()

func _input(event: InputEvent) -> void:
	if is_instance_valid(date_dialog):
		if event.is_action_pressed("ui_cancel"):
			close_dialog()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		pointer = event.position
		if not date_painters.is_empty():
			mouse_dates = true
			var target: Button
			for card in date_painters:
				if card.get_global_rect().has_point(pointer) and not card.disabled:
					target = card
					break
			highlight_date(target)
	if event is InputEventKey and event.pressed and not event.echo and session.phase in ["start","end"]:
		mouse_dates = false
		var focused := get_viewport().gui_get_focus_owner()
		if focused in date_painters: highlight_date(focused)
		if focused == null and (event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left")):
			for card in date_painters:
				if not card.disabled:
					card.grab_focus()
					get_viewport().set_input_as_handled()
					return
		var choice: int = event.keycode-KEY_1
		var options := session.boundary_choices()
		if choice>=0 and choice<options.size() and int(options[choice]) not in session.wrong_choices:
			controller.answer(options[choice])
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_instance_valid(scroll) or not get_viewport().gui_is_dragging():
		return
	var local := scroll.get_global_transform_with_canvas().affine_inverse()*pointer
	if session.game_mode == "free":
		if Rect2(Vector2.ZERO,scroll.size).has_point(local):
			if local.y < 30: scroll.scroll_vertical -= ceili(480*delta)
			elif local.y > scroll.size.y-30: scroll.scroll_vertical += ceili(480*delta)
		return
	if local.y>=0 and local.y<=scroll.size.y:
		if local.x<52: scroll.scroll_horizontal -= ceili(800*delta)
		elif local.x>scroll.size.x-52: scroll.scroll_horizontal += ceili(800*delta)

func date_zone() -> void:
	var zone := DropZone.new()
	zone.name = "EnterDateZone"
	zone.session = session
	style_button(zone)
	zone.text = "Saisir une date"
	zone.tooltip_text = "Déposez une carte ici ou sélectionnez une carte puis ce bouton."
	if session.game_mode == "classic": position_node(canvas,zone,922,643,250,33)
	else: position_node(canvas,zone,900,625,254,46)
	zone.card_dropped.connect(func(id, _point): open_date(id))
	zone.pressed.connect(func():
		if controller.selected_card != "": open_date(controller.selected_card)
		elif session.game_mode == "markers" and not session.hand.is_empty(): open_date(session.hand[0])
		else:
			zone.text = "Choisissez une carte"
			if not session.hand.is_empty(): hand_cards[session.hand[0]].grab_focus())

func dialog_frame() -> Control:
	if is_instance_valid(date_dialog): close_dialog()
	date_dialog = Control.new()
	date_dialog.z_index = 20
	position_node(canvas,date_dialog,0,0,1600,1000)
	var dim := box(date_dialog,0,0,1600,1000,Color("#071316e9"))
	dim.mouse_filter = MOUSE_FILTER_STOP
	var previous := get_viewport().gui_get_focus_owner()
	if previous != null: date_dialog.set_meta("prior_focus",previous.get_path())
	for button in canvas.find_children("*","BaseButton",true,false):
		button.set_meta("prior_mode",button.focus_mode)
		button.focus_mode = FOCUS_NONE
	box(date_dialog,306,158,988,670,DARK,GOLD,20)
	action(date_dialog,"QuitFromDialog","Quitter",1042,51,126,47,controller.leave_game)
	return date_dialog

func close_dialog() -> void:
	if not is_instance_valid(date_dialog): return
	var previous: NodePath = date_dialog.get_meta("prior_focus", NodePath(""))
	retire(date_dialog)
	date_dialog = null
	for b in canvas.find_children("*","BaseButton",true,false):
		if b.has_meta("prior_mode"):
			b.focus_mode = b.get_meta("prior_mode")
			b.remove_meta("prior_mode")
	if not previous.is_empty():
		var prior := get_node_or_null(previous) as Control
		if prior != null and prior.focus_mode != FOCUS_NONE: prior.grab_focus()

func open_date(id: String) -> void:
	if session.phase != "placement" or session.locked(session.placed_slot(id)): return
	var dialog := dialog_frame()
	var face := make_card(dialog,id,Rect2(371,280,287,386),"","preview")
	face.mouse_filter = MOUSE_FILTER_IGNORE
	label(dialog,"Quelle année choisissez-vous ?",700,204,535,72,30,CREAM,true)
	var input := LineEdit.new()
	input.name = "YearInput"
	input.placeholder_text = "Année"
	input.max_length = 7
	input.add_theme_font_size_override("font_size",27)
	position_node(dialog,input,732,314,210,56)
	var era := OptionButton.new()
	era.name = "YearEra"
	era.add_item("après J.-C.")
	era.add_item("avant J.-C.")
	position_node(dialog,era,968,314,212,56)
	if session.years_placed.has(id):
		var existing: int = session.years_placed[id]
		input.text = str(absi(existing))
		era.select(1 if existing < 0 else 0)
	var feedback := label(dialog,"",700,566,523,59,17,BAD)
	feedback.name = "YearFeedback"
	var options := ScrollContainer.new()
	position_node(dialog,options,731,385,450,170)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	options.add_child(list)
	var update := func():
		for child in list.get_children(): retire(child)
		feedback.text = ""
		if session.game_mode != "classic": return
		for suggestion in session.suggestions(input.text,era.selected == 1):
			var pick := Button.new()
			pick.text = suggestion.caption
			list.add_child(pick)
			pick.pressed.connect(func():
				input.text = str(absi(suggestion.year))
				update_date(id, input, era, feedback))
	input.text_changed.connect(func(_value): update.call())
	era.item_selected.connect(func(_index): update.call())
	var submit := func(): update_date(id, input, era, feedback)
	input.text_submitted.connect(func(_value): submit.call())
	action(dialog,"SubmitYear","Valider la date",732,643,448,55,submit,true)
	action(dialog,"CancelYear","Annuler",732,714,448,45,close_dialog,false,true)
	update.call()
	input.grab_focus()
	input.select_all()

func update_date(id: String, input: LineEdit, era: OptionButton, feedback: Label) -> void:
	var digits := input.text.strip_edges().replace(" ","")
	if not digits.is_valid_int() or digits.begins_with("-") or int(digits) <= 0:
		feedback.text = "Entrez une année positive et choisissez son ère."
		return
	var year := int(digits) * (-1 if era.selected == 1 else 1)
	if session.assign_year(id, year):
		close_dialog()
		controller.selected_card = ""
		controller.play_sound(session.game_mode == "markers")
		controller._refresh()
	elif session.game_mode == "classic":
		feedback.text = "Aucune date correspondante sur cette frise." if session.slots_at(year).is_empty() else "Cet emplacement est déjà verrouillé ou occupé par cette carte."
	elif session.game_mode == "markers":
		feedback.text = "Ce repère correspond à une autre année. Réessayez."
	else:
		feedback.text = "Choisissez une année entre les deux extrémités de la frise."

func reward_button_text() -> String:
	if session.pack_opened or session.new_normals.is_empty(): return "Mes récompenses"
	return "Ouvrir le lot · %d" % session.new_normals.size()

func reward_dialog() -> void:
	var dialog := dialog_frame()
	var reveal := not session.pack_opened
	session.pack_opened = true
	var opener := canvas.find_child("ShowReward",true,false) as Button
	if opener != null: opener.text = reward_button_text()
	label(dialog,"Récompenses de la partie",358,176,884,68,34,CREAM,true)
	var summaries := PackedStringArray(["%d cartes travaillées" % session.first_try.size()])
	if not session.new_normals.is_empty():
		var count := session.new_normals.size()
		summaries.append("1 nouvelle normale" if count == 1 else "%d nouvelles normales" % count)
	if not session.new_gold.is_empty():
		var count := session.new_gold.size()
		summaries.append("1 nouvelle dorée" if count == 1 else "%d nouvelles dorées" % count)
	var summary := "   ·   ".join(summaries)
	label(dialog,summary,349,249,902,45,19,GOLD)
	var scroll_box := ScrollContainer.new()
	scroll_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	position_node(dialog,scroll_box,373,310,853,377)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",12)
	scroll_box.add_child(rows)
	var catalog := {}
	for card in controller.repository.collection_cards(): catalog[card.id] = card
	if not session.new_normals.is_empty():
		var grid := GridContainer.new()
		grid.columns = mini(4,session.new_normals.size())
		grid.size_flags_horizontal = SIZE_SHRINK_CENTER
		grid.add_theme_constant_override("h_separation",12)
		grid.add_theme_constant_override("v_separation",12)
		rows.add_child(grid)
		for i in session.new_normals.size():
			var card: Dictionary = catalog[session.new_normals[i]]
			var face := Control.new()
			face.custom_minimum_size = Vector2(194,265)
			grid.add_child(face)
			CardArt.layer(face,CardArt.FACE)
			var marker: bool = card.get("kind") == "period_boundary"
			var rank: Array = ChronologyRepository.RARITIES[card.get("rarity","common")]
			box(face,14,14,166,4,period_color(card.periods[0]) if marker else rank[1])
			label(face,"REPÈRE DE PÉRIODE" if marker else str(rank[0]).to_upper(),10,21,174,28,13,INK)
			var top := 55
			if card.has("image"):
				picture(face,load(card.image),15,50,164,66,true)
				top = 120
			label(face,card.title,13,top,168,216-top,21,INK,true)
			label(face,"Normale acquise",12,222,170,30,14,INK)
			if reveal:
				var back := CardArt.layer(face,CardArt.BACK)
				back.pivot_offset = face.custom_minimum_size / 2
				var turn := back.create_tween()
				turn.tween_interval(0.2 + mini(i,5)*0.09)
				turn.tween_property(back,"scale:x",0.0,0.18)
				turn.tween_callback(back.queue_free)
	else:
		rows.add_child(AppTheme.label("Toutes les cartes normales de cette partie sont déjà dans votre collection.",17,MUTED))
	for id in session.marks_gained:
		var card: Dictionary = catalog[id]
		var total: int = controller.progress_repository.collectible(id).marks
		var detail := "✦ Dorée débloquée" if id in session.new_gold else "Maîtrise"
		var line := AppTheme.label("%s · %s   +%d   (%d/%d)" % [detail,card.title,session.marks_gained[id],total,ProgressRepository.GOLD_THRESHOLD],17,GOLD)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rows.add_child(line)
	action(dialog,"CloseReward","Retour au bilan",581,710,438,55,close_dialog,true).grab_focus()

func alternate_board() -> void:
	board_active = session.phase == "placement"
	showing_periods = session.game_mode == "markers"
	var markers := showing_periods
	label(canvas,"Repères de périodes" if markers else "Frise libre",75,149,860,66,35,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,"Choisissez une carte en main et retrouvez son année." if markers else "Glissez une carte sur l’axe. Cliquez sur son année pour l’ajuster.",77,209,1430,44,19,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	scroll = ScrollContainer.new()
	scroll.name = "FriezeBoardScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	position_node(canvas,scroll,90,274,1418,335)
	track = Control.new()
	scroll.add_child(track)
	if markers: marker_board()
	else: free_board()
	scroll.set_deferred("scroll_vertical", controller._board_position)
	scroll.get_v_scroll_bar().value_changed.connect(func(v): controller._board_position = int(v))
	hand()
	update_validation_button()
	if session.phase == "placement": date_zone()
	footer("Les bandes apparaissent lorsque leurs deux bornes sont retrouvées." if markers else "Axe à l’échelle · Plusieurs événements peuvent occuper la même année.")

func marker_board() -> void:
	track.custom_minimum_size = Vector2(1370,maxi(285,session.periods.size()*77))
	for i in session.periods.size():
		var period: Dictionary = session.periods[i]
		var base := "period-boundary-"+str(period.id)+"-"
		var y := i*77
		var start_known := session.placements.has(base+"start")
		var end_known := session.placements.has(base+"end")
		label(track,period.title,16,y,270,55,22,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
		label(track,ChronologyRepository.date_label(period.start) if start_known else "Début à retrouver",292,y,300,55,18,GOOD if start_known else MUTED)
		label(track,ChronologyRepository.date_label(period.end) if end_known else "Fin à retrouver",988,y,335,55,18,GOOD if end_known else MUTED)
		if start_known and end_known:
			var x := 278 + 1040 * inverse_lerp(first_year,last_year,period.start)
			var right := 278 + 1040 * inverse_lerp(first_year,last_year,period.end)
			box(track,x,y+57,maxf(3,right-x),7,period_color(period.id))

const AXIS_LEFT := 120.0
const AXIS_WIDTH := 1130.0

func free_year(x: float) -> int:
	var last_tick := last_year-1 if first_year < 0 and last_year > 0 else last_year
	var tick := roundi(lerpf(first_year,last_tick,clampf((x-AXIS_LEFT)/AXIS_WIDTH,0,1)))
	return tick+1 if first_year < 0 and last_year > 0 and tick >= 0 else tick

func year_x(year: int) -> float:
	var crosses := first_year < 0 and last_year > 0
	return AXIS_LEFT + AXIS_WIDTH * inverse_lerp(first_year,last_year-1 if crosses else last_year,year-1 if crosses and year > 0 else year)

func free_board() -> void:
	var zone := DropZone.new()
	zone.session = session
	zone.name = "FreeAxis"
	style_button(zone,true)
	position_node(track,zone,0,0,1370,300)
	var preview := label(track,"",390,0,600,39,20,GOLD)
	preview.name = "HoverYear"
	var hover := func(at): preview.text = ChronologyRepository.date_label(free_year(at.x))
	var drop := func(id,at):
		if session.assign_year(id,free_year(at.x)):
			controller.selected_card = ""
			controller.play_sound()
			controller._refresh()
	zone.card_hovered.connect(hover)
	zone.card_dropped.connect(drop)
	zone.mouse_exited.connect(func(): preview.text = "")
	label(track,ChronologyRepository.date_label(first_year),0,0,280,40,18,GOLD)
	label(track,ChronologyRepository.date_label(last_year),1090,0,280,40,18,GOLD)
	box(track,AXIS_LEFT,51,AXIS_WIDTH,3,GOLD)
	var ids := session.placements.keys()
	ids.sort_custom(func(a,b): return session.years_placed[a] < session.years_placed[b])
	var occupied := []
	for id in ids:
		var year: int = session.years_placed[id]
		var x := year_x(year)
		var lane := 0
		while lane < occupied.size() and occupied[lane] > x-85: lane += 1
		if lane == occupied.size(): occupied.append(0)
		occupied[lane] = x+85
		var y := 85+lane*240
		box(track,x-1,51,2,17,GOOD if session.locked(id) else GOLD)
		var b := make_card(track,id,Rect2(x-78,y+30,156,198),"","preview")
		b.focus_mode = FOCUS_ALL
		b.pressed.connect(open_date.bind(id))
		slot_cards[id] = b
		var edit := action(track,"EditYear_"+str(id),ChronologyRepository.date_label(year),x-92,y-9,184,38,open_date.bind(id))
		edit.disabled = session.locked(id)
		# An occupied year stays a valid drop location for another event.
		for hit in [edit,b]:
			var over := func(_at,data):
				var local := track.get_local_mouse_position()
				return zone._can_drop_data(local,data)
			var release := func(_at,data): zone._drop_data(track.get_local_mouse_position(),data)
			hit.set_drag_forwarding(b._get_drag_data,over,release)
	track.custom_minimum_size = Vector2(1370,maxi(300,occupied.size()*240+100))
	zone.size = track.custom_minimum_size

func update_alternate_board() -> void:
	var origins := {}
	for face in hand_cards.values(): origins[face.card_id] = center_on_canvas(face)
	for face in slot_cards.values(): origins[face.card_id] = center_on_canvas(face)
	var saved := scroll.scroll_vertical
	for child in track.get_children(): retire(child)
	slot_cards.clear()
	if session.game_mode == "free": free_board()
	else: marker_board()
	scroll.set_deferred("scroll_vertical",saved)
	refresh_hand(origins)
	for id in slot_cards:
		if origins.has(id): fly(slot_cards[id],origins[id],center_on_canvas(slot_cards[id]))
	refresh_pile()
	update_validation_button()
	if painted_selection != controller.selected_card: select_face(painted_selection,controller.selected_card)
	if session.retrying: header_count.text = str(session.events.size()-session.placements.size())
	else: header_count.text = "%d / %d" % [session.placements.size(),session.events.size()]
