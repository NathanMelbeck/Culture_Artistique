extends "res://tests/frieze_smoke.gd"

func enter_year(year: int) -> void:
	var field := widget("YearInput") as LineEdit
	var era := widget("YearEra") as OptionButton
	if field == null or era == null:
		check(false,"La carte propose un champ et les deux ères")
		return
	field.text = str(absi(year))
	field.text_changed.emit(field.text)
	era.select(1 if year < 0 else 0)
	era.item_selected.emit(era.selected)
	await click("SubmitYear")

func _run() -> void:
	output_directory = ProjectSettings.globalize_path("res://../.tmp/frieze-validation")
	DirAccess.make_dir_recursive_absolute(output_directory)
	app = load("res://scenes/app_shell.tscn").instantiate()
	app.progress_repository = ProgressRepository.new("")
	root.add_child(app)
	root.size = Vector2i(1280,800)
	await frames(10)
	await click("GamesNav")
	await click("OpenFrieze")
	await click("Group_antiquite")
	await capture("preparation-modes.png")
	await click("Mode_markers")
	await click("ClearPeriods")
	await click("SelectPeriod_egypte")
	await click("StartFrieze")
	var games: Control = app._page
	check(games.session.hand.size()==2 and widget("FreeAxis")==null and widget("YearInput")==null,"Repères sans cases initiales")
	var id: String = games.session.hand[0]
	await click("HandCard_"+id)
	check(widget("YearInput") != null and (widget("YearEra") as OptionButton).selected==0,"Un clic ouvre la carte en grand avec après J.-C. par défaut")
	await enter_year(120)
	check(widget("YearInput") != null and not (widget("YearFeedback") as Label).text.is_empty(),"Un repère erroné reste ouvert")
	await capture("repere-saisie.png")
	await enter_year(games.session.event(id).year)
	id = games.session.hand[0]
	await click("HandCard_"+id)
	await enter_year(games.session.event(id).year)
	await click("ValidateFrieze")
	await click("ShowReward")
	check(games.session.new_normals.size()==1,"Une carte normale est automatiquement attribuée pour deux cartes travaillées")
	var prize: String = games.session.new_normals[0]
	check(app.progress_repository.collectible(prize).normal and app.progress_repository.collectible(prize).marks==0,"La nouvelle carte du lot entre dans la collection à zéro marque")
	await capture("lot-de-normales.png")
	await click("CloseReward")
	await click("ShowReward")
	check(games.session.new_normals == [prize] and app.progress_repository.owned_normals().size() == 1,"Rouvrir le lot retrouve la même récompense")
	await click("CloseReward")
	await click("ShowSolution")
	await click("MarkReview")
	check(app.progress_repository.review_ids().size()==1,"Carte marquée à revoir depuis la correction")
	await click("ChangePeriods")
	await click("OpenCollection")
	await click("Filter_1")
	await capture("collection.png")
	await click("OpenFrieze")
	await click("Mode_free")
	await click("StartFrieze")
	check(widget("FreeAxis")!=null and games.session.placements.is_empty(),"Frise libre vierge")
	id = games.session.hand[0]
	await create_timer(0.45).timeout
	await drag_card(widget("HandCard_"+id),widget("FreeAxis"))
	check(games.session.placements.has(id),"Glisser de la main vers l’axe crée une position")
	if games.session.placements.has(id):
		await click("EditYear_"+id)
		await enter_year(-1500)
		check(games.session.years_placed[id]==-1500,"Cliquer sur l’année déplace la carte")
	var next: String = games.session.hand[0]
	await create_timer(0.45).timeout
	await drag_card(widget("HandCard_"+next),widget("EnterDateZone"))
	await enter_year(-1500)
	check(games.session.years_placed.get(next)==-1500,"Le dépôt sur la saisie autorise une deuxième carte à la même année")
	await capture("frise-libre.png")
	await create_timer(0.4).timeout
	await drag_card(games.screen.slot_cards[id],widget("HoverYear"))
	check(games.session.years_placed.get(id)!=-1500 and games.session.years_placed.get(next)==-1500 and games.session.placements.size()==2,"Déplacer une carte posée garde l’autre à la même année")
	while not games.session.hand.is_empty():
		var remaining: String = games.session.hand[0]
		games.session.assign_year(remaining,games.session.event(remaining).year)
	games._refresh()
	await frames()
	await click("ValidateFrieze")
	check(games.session.phase=="result","Validation finale des événements de la frise libre")
	await click("RetryErrors")
	check(games.session.hand.size()>=1 and games.session.phase=="placement","Seules les cartes libres erronées reviennent en main")
	await click("ChangePeriods")
	await click("Mode_classic")
	await click("StartFrieze")
	await click("Boundary_-4000")
	await click("Boundary_-400")
	id = games.session.hand[0]
	await create_timer(0.45).timeout
	await drag_card(widget("HandCard_"+id),widget("EnterDateZone"))
	await enter_year(-3333)
	check(widget("YearFeedback") != null and (widget("YearFeedback") as Label).text=="Aucune date correspondante sur cette frise.","Date absente refusée en classique")
	await enter_year(games.session.event(id).year)
	check(games.session.placements.has(id),"La saisie classique remplit la date existante")
	await verify_collection_art(games)
	print("FRIEZE MODES UI RESULT: %d failures" % failures)
	app.queue_free()
	await frames()
	quit(1 if failures else 0)

func count_art(parent: Node, art: Texture2D) -> int:
	var amount := 0
	for image in parent.find_children("*","TextureRect",true,false):
		if image.texture == art: amount += 1
	return amount

func verify_collection_art(games: Control) -> void:
	const Art = preload("res://components/chroniques_card_art.gd")
	var progress := ProgressRepository.new("")
	# Legacy save with partial progress, an already unlocked gold and a normal.
	progress._store_card("egy-unification", {"wins":2, "review":true})
	progress._store_card("egy-kemeni", {"wins":3})
	progress._store_card("egy-reniseneb", {"normal":true, "wins":1})
	games.progress_repository = progress
	await click("ChangePeriods")
	await click("OpenCollection")
	await click("Filter_0")
	var hidden_count: int = games.repository.collection_cards().size()-2
	check(count_art(games,Art.BACK)==hidden_count and count_art(games,Art.FACE)==2 and count_art(games,Art.GOLD)==1,
		"La collection révèle la normale et la dorée conservée de l’ancienne sauvegarde")
	var anonymous := true
	for image in games.find_children("*","TextureRect",true,false):
		if image.texture == Art.BACK:
			var tile: Control = image.get_parent()
			anonymous = anonymous and tile.get_child_count()==1 and tile.tooltip_text.is_empty() and tile.accessibility_name=="Carte à découvrir"
	check(anonymous,"Chaque dos caché est anonyme, y compris au survol")
	await capture("collection-marqueterie.png")
	await click("Filter_3")
	check(count_art(games,Art.BACK)==1 and count_art(games,Art.FACE)==0,"Une carte à revoir encore inconnue garde son dos")
	await click("Filter_2")
	check(count_art(games,Art.GOLD)==1 and count_art(games,Art.BACK)==0,"Le filtre doré inclut une ancienne dorée migrée")
	await click("OpenFrieze")
	await click("Mode_free")
	await click("StartFrieze")
	check(count_art(games.screen.hand_cards["egy-kemeni"],Art.GOLD)==1 and count_art(games.screen.hand_cards["egy-unification"],Art.BACK)==0,
		"La dorure apparaît dans la main et les cartes inconnues sont jouables face visible")
	check(games.screen.deck_art.texture==Art.BACK,"La pioche utilise le dos Marqueterie")
	await create_timer(0.45).timeout
	await drag_card(games.screen.hand_cards["egy-kemeni"],widget("FreeAxis"))
	check(games.screen.slot_cards.has("egy-kemeni") and count_art(games.screen.slot_cards["egy-kemeni"],Art.GOLD)==1,"La carte posée conserve sa dorure")
	await click("EditYear_egy-kemeni")
	await enter_year(games.session.event("egy-kemeni").year)
	await capture("carte-doree-plateau.png")
