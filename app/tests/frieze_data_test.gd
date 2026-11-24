extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + description)
	if not condition:
		failures += 1

func ownership(session: FriezeSession) -> bool:
	var ids: Array = []
	ids.append_array(session.hand)
	ids.append_array(session.draw_pile)
	ids.append_array(session.placements.values())
	var expected: Array = []
	for event in session.events:
		expected.append(event["id"])
	ids.sort()
	expected.sort()
	return ids == expected and session.hand.size() <= 7

func begin(session: FriezeSession) -> void:
	session.answer_boundary(int(session.start_period["start"]))
	session.answer_boundary(int(session.end_period["end"]))

func _init() -> void:
	var repository := ChronologyRepository.new()
	var egypt := repository.resolve_periods(["egypte"])
	# Inventory fixtures stay independent of the number of historical events
	# inside a revision sheet's style boundaries.
	var inventory_cards: Array = []
	for index in 8:
		inventory_cards.append({"id": "inventory-fixture-" + str(index), "year": -2000 + index})
	var selection := repository.resolve_periods(["rome", "egypte"])
	check(selection.size() == 3 and selection[1]["id"] == "grece" and repository.events_for(selection).size() == 19, "La sélection inclut la période intermédiaire sans dupliquer les événements")
	check(int(egypt[0]["start"]) == -4000 and int(egypt[0]["end"]) == -400 and int(repository.find_period("grece")["start"]) == -1100 and int(repository.find_period("grece")["end"]) == -100 and int(repository.find_period("rome")["start"]) == -800 and int(repository.find_period("rome")["end"]) == 400, "Les six bornes correspondent aux en-têtes des fiches de révision")
	var filtered := repository.events_for(selection)
	var included_ids: Array = []
	for event in filtered:
		included_ids.append(event["id"])
	check(repository.events.filter(func(e): return e.course_id in ["egypte", "grece", "rome"]).size() == 24 and repository.events_for(egypt).size() == 5 and "egy-romaine" not in included_ids and "egy-alexandre" not in included_ids and "egy-rosette" not in included_ids and "gre-actium" not in included_ids and "rom-occident" not in included_ids and repository.events.any(func(e): return e.id == "rom-occident" and int(e.year) == 476), "Les événements hors bornes sont exclus des parties sans modifier leurs dates historiques")
	var opening := repository.boundary_cards_for(selection)
	var opening_valid := opening.size() == 4 and repository.cards_for(selection).size() == 23
	for card in opening:
		var period := repository.find_period(card["periods"][0])
		opening_valid = opening_valid and int(card["year"]) == int(period[card["boundary"]]) and card["source"]["sheet_id"] == period["id"] and not card["title"].contains("J.-C.")
	check(opening_valid, "Les quatre repères intérieurs reprennent les fiches sans dupliquer les bornes de l’Antiquité")
	var presets_valid := repository.boundary_cards_for([]).is_empty()
	for id in ["egypte", "grece", "rome"]:
		presets_valid = presets_valid and repository.boundary_cards_for(repository.resolve_periods([id])).is_empty()
	var pair := repository.boundary_cards_for(repository.resolve_periods(["egypte", "grece"]))
	var pair_ids: Array = []
	for card in pair:
		pair_ids.append(card["id"])
	presets_valid = presets_valid and pair.size() == 2 and "period-boundary-egypte-end" in pair_ids and "period-boundary-grece-start" in pair_ids
	check(presets_valid, "Les cartes déjà fixées sont exclues selon chaque preset : période seule ou sélection combinée")
	var shared_first := repository.find_period("egypte")
	var shared_second := repository.find_period("grece")
	shared_second["start"] = shared_first["start"]
	var shared_cards := repository.boundary_cards_for([shared_first, shared_second])
	var shared_valid: bool = shared_cards.size() == 1 and shared_cards[0]["id"] == "period-boundary-egypte-end"
	shared_second["end"] = shared_first["end"]
	check(shared_valid and repository.boundary_cards_for([shared_first, shared_second]).is_empty(), "Les périodes partageant une même borne extérieure ne produisent aucun doublon à jouer")
	var first_draws_valid := true
	for seed_value in 30:
		var ordered := FriezeSession.new(selection, repository.cards_for(selection), seed_value)
		begin(ordered)
		for index in 4:
			first_draws_valid = first_draws_valid and ordered.event(ordered.hand[index]).get("kind") == "period_boundary"
		first_draws_valid = first_draws_valid and ordered.hand.size() == 4 and ordered.period_stage_active() and ordered.drawable_count() == 0 and ownership(ordered)
	check(first_draws_valid, "Seuls les quatre repères sont distribués, sans compléter avec des événements, sur trente parties")
	var gated := FriezeSession.new(selection, repository.cards_for(selection), 8)
	begin(gated)
	var bad_card: String = gated.hand[0]
	gated.place(bad_card, "egy-unification")
	check(gated.period_status("egy-unification") == "wrong" and gated.period_stage_active() and gated.hand.size() == 3 and not gated.draw_one() and not gated.discard(gated.hand[0]) and ownership(gated), "Un repère mal placé est identifié immédiatement et ne débloque aucune pioche d’événement")
	check(gated.return_wrong_period_to_pile(bad_card) and bad_card in gated.draw_pile and bad_card not in gated.hand and not gated.placements.has("egy-unification") and gated.can_draw() and ownership(gated), "Le retour d’un repère rouge libère la case et conserve la carte dans la pioche")
	check(gated.draw_one() and bad_card in gated.hand and gated.hand.size() == 4 and ownership(gated), "La pioche explicite reprend seulement le repère recyclé")
	var correct_card: String = gated.hand[0]
	gated.place(correct_card, correct_card)
	check(gated.period_status(correct_card) == "correct" and not gated.return_wrong_period_to_pile(correct_card) and gated.period_stage_active(), "Un bon repère est validé immédiatement et ne propose pas de retour d’erreur")
	check(not gated.return_to_hand(correct_card) and gated.locked(correct_card) and gated.correct_period_count() == 1, "Un repère validé reste verrouillé")
	for id in gated.hand.duplicate():
		gated.place(id, id)
	var only_events := true
	for id in gated.hand:
		only_events = only_events and not gated.is_period_card(id)
	check(not gated.period_stage_active() and gated.correct_period_count() == 4 and gated.hand.size() == 7 and only_events and ownership(gated), "Tous les repères corrects déclenchent automatiquement la distribution de sept événements")
	var ordinary_id: String = gated.hand[0]
	gated.place(ordinary_id, ordinary_id)
	check(gated.period_status(ordinary_id).is_empty() and gated.phase == "placement", "Un événement correctement placé reste réservé à la correction finale")
	while not gated.hand.is_empty():
		var id: String = gated.hand[0]
		gated.place(id, id)
	check(not gated.place(correct_card, ordinary_id) and not gated.place(ordinary_id, correct_card) and gated.can_validate() and ownership(gated), "Les repères validés restent protégés des échanges dans les deux sens")
	var empty_hand := FriezeSession.new(selection, repository.cards_for(selection), 9)
	begin(empty_hand)
	var wrong_slots := repository.events_for(selection)
	var wrong_slot_index := 0
	for id in empty_hand.hand.duplicate():
		empty_hand.place(id, wrong_slots[wrong_slot_index]["id"])
		wrong_slot_index += 1
	var returned_id: String = empty_hand.placements.values()[0]
	check(empty_hand.hand.is_empty() and empty_hand.period_stage_active() and empty_hand.return_wrong_period_to_pile(returned_id) and empty_hand.draw_one() and empty_hand.hand.size() == 1 and empty_hand.is_period_card(empty_hand.hand[0]) and ownership(empty_hand), "Même si tous les repères sont rouges et la main vide, retour puis pioche permettent de continuer")
	var one_period := FriezeSession.new(egypt, repository.cards_for(egypt), 17)
	begin(one_period)
	var one_period_valid := one_period.events.size() == 5 and one_period.hand.size() == 5 and one_period.draw_pile.is_empty()
	for id in one_period.hand:
		one_period_valid = one_period_valid and one_period.event(id).get("kind") != "period_boundary"
	check(one_period_valid and one_period.periods_completed and not one_period.period_stage_active(), "Sans repère intérieur, une période seule passe directement aux événements")
	while not one_period.hand.is_empty():
		var id: String = one_period.hand[0]
		one_period.place(id, id)
	check(one_period.validate() and one_period.score() == 5 and ownership(one_period), "La partie reste entièrement remplissable sans les cartes de bornes")
	# Ten opening cards exercise selections larger than a seven-card hand.
	var overflow_cards: Array = inventory_cards.duplicate(true)
	for index in 10:
		overflow_cards.append({"id": "opening-fixture-" + str(index), "year": -3000 + index, "kind": "period_boundary"})
	var overflow := FriezeSession.new(egypt, overflow_cards, 111)
	begin(overflow)
	var seen: Dictionary = {}
	var overflow_valid := true
	for id in overflow.hand:
		seen[id] = true
		overflow_valid = overflow_valid and overflow.event(id).get("kind") == "period_boundary"
	for turn in 3:
		var before := overflow.hand.duplicate()
		if turn == 1:
			overflow.place(before[0], before[0])
		else:
			overflow.discard(before[0])
		for id in overflow.hand:
			if id not in before:
				seen[id] = true
				overflow_valid = overflow_valid and overflow.event(id).get("kind") == "period_boundary"
		overflow_valid = overflow_valid and ownership(overflow)
	check(overflow_valid and seen.size() == 10, "Au-delà de sept bornes, poses et défausses ne font jamais passer un événement avant une borne encore non piochée")
	var short_game := FriezeSession.new(egypt, repository.events_for(egypt), 7)
	begin(short_game)
	var short_ok := short_game.hand.size() == 5 and short_game.draw_pile.is_empty() and ownership(short_game)
	while not short_game.hand.is_empty():
		var id: String = short_game.hand[0]
		short_game.place(id, id)
	check(short_ok and short_game.can_validate() and short_game.validate() and short_game.score() == 5, "Une période avec moins de sept cartes se distribue et se termine normalement")
	var future := ChronologyRepository.new({"periods": [{"id": "egypte", "order": 0}, {"id": "grece", "order": 1}, {"id": "rome", "order": 2}, {"id": "moyen-age", "order": 3}, {"id": "renaissance", "order": 4}, {"id": "art-nouveau", "order": 5}]})
	check(future.resolve_periods(["egypte", "art-nouveau"]).size() == 6 and future.resolve_periods(["inconnu"]).is_empty(), "Le remplissage automatique fonctionne aussi avec de futures périodes et refuse un identifiant absent")
	var overlap := FriezeSession.new(repository.resolve_periods(["egypte", "grece"]), repository.events_for(repository.resolve_periods(["egypte", "grece"])), 42)
	check(int(overlap.start_period["start"]) == -4000 and int(overlap.end_period["end"]) == -100, "Les bornes prennent le début minimal et la fin maximale malgré les chevauchements")
	var session := FriezeSession.new(egypt, inventory_cards, 42)
	check(session.phase == "start" and session.hand.is_empty() and session.boundary_choices().size() == 5 and ownership(session), "La partie commence sans cartes en main, avec cinq dates de début")
	var wrong := 0
	for value in session.boundary_choices():
		if int(value) != int(session.start_period["start"]):
			wrong = int(value)
			break
	check(not session.answer_boundary(wrong) and session.phase == "start" and wrong in session.wrong_choices, "Une erreur de borne ne fait pas avancer et autorise une autre réponse")
	session.answer_boundary(int(session.start_period["start"]))
	check(session.phase == "end" and session.boundary_choices().size() == 5 and session.hand.is_empty(), "La borne de fin précède toute distribution")
	session.answer_boundary(int(session.end_period["end"]))
	check(session.phase == "placement" and session.hand.size() == 7 and session.draw_pile.size() == 1 and ownership(session), "Sept cartes sont distribuées et le reste reste en pioche")
	var discarded: String = session.hand[0]
	check(session.discard(discarded) and discarded in session.draw_pile and discarded not in session.hand and session.hand.size() == 7 and ownership(session), "La défausse renouvelle la main, recycle la carte et ne la repioche pas immédiatement")
	var card_in_pile: String = session.draw_pile[0]
	check(not session.place(card_in_pile, session.events[0]["id"]) and not session.validate() and ownership(session), "Une carte non piochée et une validation prématurée sont refusées")
	var first_card: String = session.hand[0]
	var first_slot: String = session.events[0]["id"]
	session.place(first_card, first_slot)
	check(session.hand.size() == 7 and session.draw_pile.is_empty() and session.placements.size() == 1 and ownership(session), "Placer une carte entraîne une pioche automatique")
	var replacement: String = session.hand[0]
	session.place(replacement, first_slot)
	check(session.placements[first_slot] == replacement and first_card in session.hand and ownership(session), "Poser sur un emplacement occupé rend la carte remplacée à la main")
	var second_card: String = session.hand[0]
	var second_slot: String = session.events[1]["id"]
	session.place(second_card, second_slot)
	session.place(replacement, second_slot)
	check(session.placements[second_slot] == replacement and session.placements[first_slot] == second_card and ownership(session), "Deux cartes du plateau peuvent être échangées sans perte ni duplication")
	check(session.return_to_hand(replacement) and session.hand.size() == 7 and not session.return_to_hand(second_card) and ownership(session), "Reprendre une carte utilise une place libre et refuse de dépasser sept cartes")
	check(not session.discard(session.hand[0]) and not session.place("inconnue", first_slot) and not session.place(session.hand[0], "absent") and ownership(session), "Les actions impossibles laissent la partie intacte")
	var perfect := FriezeSession.new(egypt, inventory_cards, 18)
	begin(perfect)
	while not perfect.hand.is_empty():
		var id: String = perfect.hand[0]
		perfect.place(id, id)
	check(perfect.can_validate() and perfect.score() == perfect.events.size(), "La validation devient possible uniquement lorsque toutes les cartes sont placées")
	perfect.place(perfect.events[0]["id"], perfect.events[-1]["id"])
	check(perfect.score() == perfect.events.size() - 2 and perfect.validate() and perfect.phase == "result", "Une erreur d’échange donne deux mauvaises associations puis un résultat final")
	check(not perfect.place(perfect.events[0]["id"], perfect.events[0]["id"]) and not perfect.validate() and ownership(perfect), "Un résultat validé ne peut plus être modifié ni validé deux fois")
	var first_wrong: String = perfect.events[0].id
	var last_wrong: String = perfect.events[-1].id
	check(perfect.retry_errors() and perfect.hand.size() == 2 and perfect.retained_slots.size() == 6 and ownership(perfect), "La seconde chance ne redistribue que les erreurs")
	check(not perfect.place(first_wrong, perfect.events[1].id), "Les bonnes réponses conservées restent verrouillées")
	perfect.place(first_wrong, last_wrong)
	perfect.place(last_wrong, first_wrong)
	perfect.validate()
	perfect.show_solution()
	check(perfect.submitted[first_wrong] == last_wrong and perfect.placements[first_wrong] == first_wrong and perfect.score() == 8 and not perfect.retry_errors() and ownership(perfect), "La comparaison conserve la copie initiale et corrige toutes les erreurs")
	var equal := FriezeSession.new(egypt, [{"id": "a", "year": -100}, {"id": "b", "year": -100}], 4)
	begin(equal)
	equal.place("a", "b")
	equal.place("b", "a")
	check(equal.score() == 2 and equal.validate(), "Deux événements de même date sont acceptés sur les emplacements équivalents")
	var stress := FriezeSession.new(selection, repository.events_for(selection), 222)
	begin(stress)
	var consistent := true
	for index in 120:
		if not stress.hand.is_empty():
			stress.place(stress.hand[0], stress.events[index % stress.events.size()]["id"])
		if not stress.hand.is_empty():
			stress.discard(stress.hand[-1])
		consistent = consistent and ownership(stress)
	check(consistent, "Cent vingt séries de placements et défausses conservent toutes les cartes et la limite de sept")
	var restart := FriezeSession.new(egypt, inventory_cards, 19)
	check(restart.phase == "start" and restart.hand.is_empty() and restart.placements.is_empty() and ownership(restart), "Une nouvelle tentative repart des bornes avec toutes ses cartes")
	check(ChronologyRepository.date_label(-3100, true) == "vers 3 100 av. J.-C." and ChronologyRepository.date_label(476) == "476 ap. J.-C." and ChronologyRepository.event_date({"year": -590, "year_end": -580}) == "590–580 av. J.-C.", "Les dates avant et après notre ère et les intervalles restent explicites")
	print("FRIEZE DATA RESULT: %d failures" % failures)
	quit(1 if failures else 0)
