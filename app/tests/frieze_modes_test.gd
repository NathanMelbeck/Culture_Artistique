extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + description)
	if not condition: failures += 1

func synthetic(stocks: Array) -> ChronologyRepository:
	var periods := []
	var events := []
	for i in stocks.size():
		var id := "p"+str(i)
		periods.append({"id":id,"order":i,"start":1,"end":200})
		for j in stocks[i]:
			events.append({"id":id+"-"+str(j),"periods":[id],"year":j+1})
	return ChronologyRepository.new({"periods":periods,"events":events})

func _initialize() -> void:
	var repo := ChronologyRepository.new()
	var all := repo.resolve_periods(["egypte", "rome"])
	var allocation_ok := true
	for example in [[[25,25,25],30],[[5,30,30],50],[[5,12,20],50],[[1,0,20],10],[[1,20,20],1]]:
		var data := synthetic(example[0])
		var limits := data.event_limits(data.event_pools(data.periods))
		for trial in 15:
			var deck := data.build_deck(data.periods,"free",example[1])
			allocation_ok = allocation_ok and deck.size() == clampi(example[1],limits.x,limits.y)
			for period in data.periods:
				var count := deck.filter(func(e): return period.id in e.periods).size()
				var stock: int = example[0][period.order]
				allocation_ok = allocation_ok and count >= mini(stock,2) and count <= stock
				if example[1] == 30: allocation_ok = allocation_ok and count >= 7 and count <= 13
				if stock == 5 and example[1] == 50: allocation_ok = allocation_ok and count == 5
	check(allocation_ok,"Petits stocks, minimum, tirage borné et redistribution du surplus")
	var shared := synthetic([2,2])
	shared.events[0].periods = ["p0","p1"]
	var unique := shared.build_deck(shared.periods,"free",2)
	check(unique.size() == 4 and unique.map(func(e):return e.id).count(shared.events[0].id)==1,"Événement partagé compté une fois")
	var deck := repo.build_deck(all,"free",6,["egy-reniseneb","gre-kouros"])
	check(deck.any(func(e):return e.id=="egy-reniseneb") and deck.any(func(e):return e.id=="gre-kouros"),"Deux révisions compatibles sont incluses dans le budget")
	var storage := "user://frieze-test-%d.json" % Time.get_ticks_usec()
	var progress := ProgressRepository.new(storage)
	progress.save_quiz("course",1,2)
	for example in [[0,0],[1,1],[5,1],[6,2],[9,2],[10,3],[14,3],[15,4],[19,4],[20,5],[50,11]]:
		check(ProgressRepository.pack_size(example[0])==example[1],"Lot pour %d cartes" % example[0])
	var marker_id := "period-boundary-egypte-start"
	var other_marker := "period-boundary-egypte-end"
	for trial in 7:
		var markers := FriezeSession.new([all[0]],repo.build_deck([all[0]],"markers",0),trial,"markers")
		markers.normals_at_start = progress.owned_normals()
		check(markers.phase == "placement" and markers.hand.size()==2,"Repères seuls, deux cartes distribuées immédiatement")
		for id in markers.hand.duplicate():
			if id == other_marker or trial == 3:
				check(not markers.assign_year(id,1) and not markers.first_try[id],"Une erreur suivie d’une correction reste un échec au premier essai")
			markers.assign_year(id,int(markers.event(id).year))
		check(markers.validate(),"Partie Repères terminée")
		progress.finish_frieze(markers)
		var before := progress.collectible(marker_id)
		progress.finish_frieze(markers)
		check(before==progress.collectible(marker_id),"Un deuxième bilan ne crédite rien de plus")
		check(markers.new_normals.size()==(1 if trial < 2 else 0),"Lot automatique de normales inédites limité au stock")
		for id in markers.new_normals:
			check(progress.collectible(id).marks==0 and id not in markers.new_gold,"Une nouvelle normale commence à zéro")
		if trial == 3:
			check(markers.marks_gained.is_empty(),"Un nouvel essai conserve la maîtrise précédente")
	check(progress.collectible(marker_id).marks==7 and progress.collectible(other_marker).marks==0,"Maîtrise plafonnée à sept points, sans gain sur une erreur")
	progress.toggle_review(marker_id)
	progress = ProgressRepository.new(storage)
	check(marker_id in progress.review_ids() and progress.get_course("course").quiz_best==1 and progress.collectible(marker_id).marks==7,"Les marques et les quiz sont conservés au rechargement")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(storage))
	var legacy := ProgressRepository.new("")
	legacy._store_card("old-gold",{"wins":3,"review":true})
	legacy._store_card("partial",{"wins":2,"normal":true})
	legacy._store_card("unowned",{"wins":2})
	check(legacy.collectible("old-gold")=={"marks":7,"normal":true,"review":true} and legacy.collectible("partial").marks==2 and legacy.collectible("unowned").marks==0,"Les anciennes dorées gardent leur finition, les normales leur progression")
	var classic_game := FriezeSession.new(all,repo.cards_for(all),1)
	var keeper := ProgressRepository.new("")
	for card in classic_game.events: keeper._store_card(card.id,{"normal":true,"marks":0})
	keeper._store_card(marker_id,{"normal":true,"marks":6})
	classic_game.normals_at_start = keeper.owned_normals()
	# An acquisition after the deal must wait for the next game to earn mastery.
	var late := "period-boundary-rome-end"
	keeper._store_card(late,{"normal":true,"marks":0})
	classic_game.answer_boundary(classic_game.start_period.start)
	classic_game.answer_boundary(classic_game.end_period.end)
	while not classic_game.hand.is_empty():
		var id := classic_game.hand[0]
		classic_game.place(id,id)
	classic_game.validate()
	keeper.finish_frieze(classic_game)
	check(classic_game.new_gold==[marker_id] and keeper.collectible("egy-reniseneb").marks==1 and keeper.collectible(late).marks==0,"Classique : une marque pour la borne, le repère et l’événement possédés au départ")
	var free_progress := ProgressRepository.new("")
	free_progress._store_card("gre-kouros",{"normal":true,"marks":6})
	var another_id: String = deck.filter(func(e): return e.id not in ["gre-kouros","egy-reniseneb"])[0].id
	free_progress._store_card(another_id,{"normal":true,"marks":0})
	var free := FriezeSession.new(all,deck,1,"free")
	free.normals_at_start = free_progress.owned_normals()
	var kouros := "gre-kouros"
	var other := "egy-reniseneb"
	check(free.assign_year(kouros,-584) and free.assign_year(other,-584) and free.assign_year(other,-600) and free.years_placed.size()==2 and free.years_placed[kouros]==-584,"Déplacement d’une carte sans résidu, deux cartes à la même date")
	for id in free.hand.duplicate(): free.assign_year(id,int(free.event(id).year))
	check(free.validate() and free.wrong_slots==[other],"Une année dans un intervalle est juste, une autre carte attend sa correction")
	free_progress.finish_frieze(free)
	check(free_progress.collectible(another_id).marks==2,"Une première validation correcte en libre rapporte deux marques")
	check(free.new_normals.size()==2 and free.new_gold==["gre-kouros"] and free_progress.collectible("gre-kouros").marks==7,"Un même bilan peut dorer une ancienne carte et accorder deux autres normales")
	check(free.retry_errors() and free.hand==[other] and not free.years_placed.has(other),"Nouvel essai limité aux erreurs")
	free.assign_year(other,-500)
	free.validate()
	free.show_solution()
	check(free.submitted_years[other]==-500 and free.years_placed[other]==-1450,"Comparaison avant/après avec l’année réellement proposée")
	var classic := FriezeSession.new(all,repo.cards_for(all),1)
	classic.answer_boundary(classic.start_period.start)
	classic.answer_boundary(classic.end_period.end)
	check(classic.suggestions("585",true).size()==1 and classic.suggestions("585",false).is_empty() and classic.slots_at(-585)==[kouros],"Autocomplétion par ère et correspondance à l’intérieur d’un intervalle")
	print("FRIEZE MODES RESULT: %d failures" % failures)
	quit(1 if failures else 0)
