extends Control
## Chroniques uses the approved 1600 × 1000 composition as a logical canvas.
## The shell scales it uniformly. All cards, dates, counts and choices are live.
const CARD = preload("res://components/chroniques_card.gd")
const GOLD := Color("#ddbb73")
const CREAM := Color("#f3ecd9")
const MUTED := Color("#a9bfba")
const INK := Color("#213336")
const DARK := Color("#10272c")
const GOOD := Color("#83d1aa")
const BAD := Color("#ef8f81")
const CHANGED := Color("#b99cde")
const COLORS := {"egypte": Color("#e5b65e"), "grece": Color("#58bebd"), "rome": CHANGED}
const PHOTOS := {
	"egy-kemeni":"543955", "egy-reniseneb":"547687", "egy-hatshepsout":"544450",
	"gre-exekias":"250551", "gre-sardes":"252453", "egy-akhenaton":"544056"
}
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

func _ready() -> void:
	var matte := ColorRect.new()
	matte.color = Color("#0a171b")
	add_child(matte)
	matte.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	canvas = Control.new()
	canvas.size = Vector2(1600,1000)
	add_child(canvas)
	resized.connect(_fit)
	count_events = session.events.size() - session.period_count()
	first_year = int(session.start_period.start)
	last_year = int(session.end_period.end)
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

func _fit() -> void:
	var factor := minf(size.x/1600.0,size.y/1000.0)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - canvas.size * factor) / 2.0

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
	# Real titles can wrap differently from the example on the design card.
	var font_size := px
	while font_size > 9 and item.get_line_count() * item.get_line_height() > h:
		font_size -= 1
		item.add_theme_font_size_override("font_size",font_size)
	return item

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
		unit = "événements corrects"
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
		subtitle = "Comparez votre essai à la solution"
		counter = str(session.wrong_slots.size())
		unit = "cartes corrigées"
	label(canvas,subtitle,570,73,460,29)
	label(canvas,counter,1150,46,170,35,26,GOLD,true,HORIZONTAL_ALIGNMENT_RIGHT)
	label(canvas,unit,1110,81,210,24,13,MUTED,false,HORIZONTAL_ALIGNMENT_RIGHT)
	action(canvas,"ChroniquesHome","",52,49,202,60,func(): controller.destination_requested.emit("home"),false,true).tooltip_text = "Retour au menu"
	action(canvas,"ChangePeriods","",1415,48,54,60,controller._show_setup,false,true).tooltip_text = "Choisir les périodes"
	var sound := action(canvas,"Sound","",1363,48,59,60,toggle_sound,false,true)
	sound.tooltip_text = "Activer ou couper le son"
	if AudioServer.is_bus_mute(0):
		label(canvas,"×",1382,74,30,24,21,BAD)

func toggle_sound() -> void:
	AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
	controller._refresh()

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
	label(canvas,session.start_period.title if first else session.end_period.title,290,316,1020,28,17,GOLD)
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
		var home_y := b.position.y
		var raise_card := func(active: bool):
			b.position.y = home_y - (18 if active else 0)
			glow.visible = active
			plaque.visible = active
			hint.text = "→   Choisir" if active else "Touche %d" % (i+1)
			hint.add_theme_color_override("font_color",INK if active else MUTED)
		b.mouse_entered.connect(raise_card.bind(true))
		b.mouse_exited.connect(raise_card.bind(false))
		b.focus_entered.connect(raise_card.bind(true))
		b.focus_exited.connect(raise_card.bind(false))
		if year in session.wrong_choices:
			b.disabled = true
			b.modulate = Color("#aa7770")
	if session.wrong_choices.is_empty():
		var initial := canvas.get_node("Boundary_" + str(options[0])) as Button
		initial.call_deferred("grab_focus")
	label(canvas,controller._message if controller._message else "Une erreur ? Vous pouvez réessayer.",240,752,1120,42,17,BAD if controller._message else MUTED)
	label(canvas,"La pioche arrive après les deux bonnes réponses." if first else "✓   Début trouvé · "+ChronologyRepository.date_label(first_year),200,821,1200,48,16,MUTED if first else GOOD)
	footer("Choisissez une carte · Souris ou touches 1 à 5")

func period_color(id: String) -> Color:
	return COLORS.get(id,Color.from_hsv(fposmod(id.hash()*0.618,1.0),0.45,0.85))

func board() -> void:
	var periods := session.period_stage_active()
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
		make_card(track,placed,Rect2(x,top,180,212),id)
	scroll.scroll_horizontal = controller._board_position
	scroll.set_deferred("scroll_horizontal",controller._board_position)
	scroll.get_h_scroll_bar().value_changed.connect(_scrolled)
	if not periods:
		_scrolled(controller._board_position)
	hand()
	if session.can_validate():
		action(canvas,"ValidateFrieze","Valider la frise",1245,638,245,48,controller.validate_board,true)
	if session.phase == "result": return
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
		var skin := "plain"
		if session.locked(slot): skin = "right"
		if status == "wrong": skin = "wrong"
		if controller.selected_card == id: skin = "hover"
		if review == "changed": skin = "change"
		texture(b,skin,0,0,w,h)
		box(b,12,13,w-24,5,period_color(event.periods[0]),Color.TRANSPARENT,2)
		label(b,"REPÈRE DE PÉRIODE" if period else "ÉVÉNEMENT",6,19,w-12,23,11,Color("#735e38"))
		if PHOTOS.has(id):
			box(b,13,44,w-26,88,Color("#e2d9c6"),Color.TRANSPARENT,6)
			picture(b,load("res://assets/courses/museum/met-"+PHOTOS[id]+".jpg"),17,47,w-34,81,true)
			label(b,event.title,9,132,w-18,h-158,15,INK,true)
		else:
			label(b,"◆",0,43,w,36,23,GOLD if status!="wrong" else BAD)
			label(b,event.title,10,78,w-20,h-113,18,INK,true)
		if status == "wrong" and review == "":
			var recycle := action(b,"RecyclePeriod_"+id,"↶ Retour en pioche",9,h-40,w-18,32,func():
				if session.return_wrong_period_to_pile(id):
					controller.selected_card = ""
					controller._refresh()
			)
			recycle.add_theme_font_size_override("font_size",12)
			recycle.add_theme_stylebox_override("normal",surface(Color("#773c38"),BAD,6))
		else:
			var mark := "THE MET · CC0" if PHOTOS.has(id) else "CHRONIQUES"
			if review=="changed":
				box(b,15,h-30,w-30,21,Color("#594975"),Color.TRANSPARENT,9)
				label(b,"CARTE CORRIGÉE",15,h-30,w-30,21,10,CREAM)
			elif session.locked(slot):
				picture(b,preload("res://assets/frieze/lock.svg"),w/2-9,h-29,18,18)
			else:
				label(b,mark,5,h-29,w-10,22,10,Color("#60573e"))
		b.tooltip_text = event.title
	if review == "":
		b.dropped.connect(controller._place)
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
	label(canvas,"%d / 7"%session.hand.size(),85,712,100,32,19,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
	if not session.period_stage_active() and not session.retrying and session.phase == "placement":
		var discard := action(canvas,"DiscardFriezeCard","Défausser",75,794,129,44,func():
			if session.discard(controller.selected_card):
				controller.selected_card = ""
				controller._refresh()
		)
		discard.disabled = not session.can_discard(controller.selected_card)
	if session.phase == "result":
		label(canvas,"Toutes les cartes ont été placées.",425,728,750,72,26,CREAM,true)
		return
	var n := session.hand.size()
	for i in n:
		var t := i-(n-1)/2.0
		var id := session.hand[i]
		var y := 687+absf(t)*6 - (15 if controller.selected_card==id else 0)
		var b := make_card(canvas,id,Rect2(800-81+t*156,y,162,224))
		b.pivot_offset = Vector2(81,224)
		b.rotation_degrees = t*2
		var lift := func(active: bool):
			b.z_index = 3 if active else 0
			b.create_tween().tween_property(b,"position:y",y-13 if active else y,.10)
		b.mouse_entered.connect(lift.bind(true))
		b.mouse_exited.connect(lift.bind(false))
	if session.retrying:
		label(canvas,"%d événements justes" % (session.retained_slots.size()-session.period_count()),1260,727,255,42,18,GOOD)
		label(canvas,"conservés en place",1260,766,255,34,15,MUTED)
		return
	var reserve := session.period_stage_active() and session.drawable_count()==0
	texture(canvas,"deck",1386,690,138,218)
	label(canvas,str(session.draw_pile.size() if reserve else session.drawable_count()),1393,679,120,44,23,GOLD,true)
	label(canvas,"EN RÉSERVE" if reserve else "PIOCHE",1383,904,137,32,13,MUTED)
	if session.can_draw():
		var draw := action(canvas,"DrawFriezeCard","Piocher",1367,892,160,43,func():
			session.draw_one()
			controller._refresh()
		,true)
		draw.tooltip_text = "Piocher une carte disponible"

func result() -> void:
	board()
	# Modal absorbs pointer and keyboard input intended for the underlying board.
	for b in canvas.find_children("*","BaseButton",true,false):
		b.focus_mode = FOCUS_NONE
	var shade := box(canvas,24,130,1552,816,Color("#020d13ed"),Color.TRANSPARENT,20)
	shade.mouse_filter = MOUSE_FILTER_STOP
	box(canvas,335,194,930,670,DARK,GOLD,24)
	box(canvas,346,205,908,648,Color.TRANSPARENT,Color("#394e46"),17)
	box(canvas,682,228,236,30,DARK,GOLD,15)
	label(canvas,"FRISE VALIDÉE",682,228,236,30,13,GOLD)
	label(canvas,"L’histoire prend sa place.",365,278,870,76,43,CREAM,true)
	var mistakes := session.wrong_slots.size()
	label(canvas,str(count_events-mistakes),450,336,700,78,53,GOOD,true)
	label(canvas,"événements bien placés sur %d"%count_events,430,400,740,40,18,MUTED)
	if mistakes:
		box(canvas,684,445,232,37,DARK,BAD,16)
	label(canvas,"%d cartes à revoir"%mistakes if mistakes else "Toutes les cartes sont à leur place.",395,444,810,41,17,BAD if mistakes else GOOD)
	for i in (2 if mistakes else 1):
		var x := 383+i*428 if mistakes else 597
		box(canvas,x,503,405,262,Color("#18363a"),Color("#48645f"),14)
		picture(canvas,preload("res://assets/frieze/retry.svg") if i else preload("res://assets/frieze/eye.svg"),x+24,527,27,27)
		label(canvas,("Voir les erreurs" if mistakes else "Revoir la frise") if i==0 else "Refaire les mauvaises",x+24,557,361,49,25,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
		label(canvas,"Comparez votre essai à la bonne chronologie." if i==0 else "Gardez vos bonnes réponses. Replacez uniquement les cartes à corriger.",x+24,602,360,76,16,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
		if i==0:
			action(canvas,"ShowSolution","Voir la correction",x+24,696,357,49,func():
				session.show_solution()
				controller.comparison_index = 0
				controller._refresh()
			)
		else:
			action(canvas,"RetryErrors","Réessayer les %d cartes"%mistakes,x+24,696,357,49,func():
				if session.retry_errors():
					controller._board_position = 0
					controller._refresh()
			,true)
	footer("Choisissez votre façon de revoir les erreurs.")
	action(canvas,"ReplayFrieze","Recommencer une partie complète",565,786,470,51,controller._start_game,false,true)

func comparison() -> void:
	label(canvas,"%d événements justes conservés" % (count_events-session.wrong_slots.size()),1240,164,290,38,14,GOOD)
	var ids := session.wrong_slots.duplicate()
	if ids.is_empty():
		for e in session.events:
			ids.append(e.id)
	var index := clampi(controller.comparison_index,0,ids.size()-1)
	var page_start := index-index%2
	label(canvas,"→",648,434,36,55,27,GOLD)
	label(canvas,"CHAQUE ERREUR DEVIENT UN REPÈRE",76,144,880,39,13,GOLD,false,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,"Votre frise, avant et après.",76,182,1080,56,38,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
	for side in 2:
		var x := 73+side*609
		box(canvas,x,259,578,409,DARK,Color("#45594f"),18)
		label(canvas,"PLACEMENT INITIAL" if side==0 else "CORRECTION AUTOMATIQUE",x+27,275,510,35,13,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
		label(canvas,"Votre essai" if side==0 else "La bonne chronologie",x+27,302,520,46,25,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
		box(canvas,x+29,399,520,1,GOLD,Color.TRANSPARENT,0)
		for offset in mini(2,ids.size()-page_start):
			var slot: String = ids[page_start+offset]
			var id: String = session.submitted[slot] if side==0 else session.placements[slot]
			var cx := x+78+offset*238
			label(canvas,ChronologyRepository.event_date(session.event(slot)),cx-22,349,226,49,16)
			var b := make_card(canvas,id,Rect2(cx,407,182,224),"","changed" if side==1 and slot in session.wrong_slots else "initial")
			b.focus_mode = FOCUS_ALL
			b.name = ("Original_" if side==0 else "Correction_")+slot
			b.pressed.connect(change_comparison.bind(page_start+offset))
	box(canvas,1283,259,245,409,Color("#152e32"),Color("#4d6256"),18)
	label(canvas,"Cartes corrigées",1297,304,217,76,24,CREAM,true)
	label(canvas,"Le sceau indique les cartes déplacées. Sélectionnez une carte pour lire son explication.",1304,387,203,147,17,MUTED)
	label(canvas,"%d / %d" % [index+1,ids.size()],1305,543,199,44,19,CHANGED)
	var prev := action(canvas,"PreviousReview","←",1308,597,84,43,change_comparison.bind(index-1))
	prev.disabled = index == 0
	var next := action(canvas,"NextReview","→",1415,597,84,43,change_comparison.bind(index+1))
	next.disabled = index == ids.size()-1
	var event := session.event(session.placements[ids[index]])
	box(canvas,74,697,1185,182,Color("#18363a"),Color("#4b6259"),15)
	label(canvas,"COMPRENDRE LA CHRONOLOGIE",100,706,1080,37,13,GOLD,false,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,event.title,100,742,1110,48,24,CREAM,true,HORIZONTAL_ALIGNMENT_LEFT)
	label(canvas,event.explanation,100,790,1125,82,17,MUTED,false,HORIZONTAL_ALIGNMENT_LEFT)
	if event.get("kind")=="period_boundary":
		action(canvas,"ReviewFriezeSheet","Revoir la fiche",1283,704,245,48,func(): controller.revision_requested.emit(event.source.sheet_id))
	else:
		action(canvas,"ReviewFriezeCourse","Revoir le cours",1283,704,245,48,func(): controller.course_requested.emit(event.course_id,event.chapter))
		action(canvas,"FriezeSource","Source · Internet ↗",1283,834,245,44,func(): OS.shell_open(event.source.url))
	action(canvas,"ReplayFrieze","Nouvelle partie",1283,771,245,48,controller._start_game,true)
	footer("À gauche, votre placement. À droite, la réponse correcte.")

func change_comparison(index: int) -> void:
	controller.comparison_index = index
	controller._refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer = event.position
	if event is InputEventKey and event.pressed and not event.echo and session.phase in ["start","end"]:
		var choice: int = event.keycode-KEY_1
		var options := session.boundary_choices()
		if choice>=0 and choice<options.size() and int(options[choice]) not in session.wrong_choices:
			controller.answer(options[choice])
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_instance_valid(scroll) or not get_viewport().gui_is_dragging():
		return
	var local := scroll.get_global_transform_with_canvas().affine_inverse()*pointer
	if local.y>=0 and local.y<=scroll.size.y:
		if local.x<52: scroll.scroll_horizontal -= ceili(800*delta)
		elif local.x>scroll.size.x-52: scroll.scroll_horizontal += ceili(800*delta)
