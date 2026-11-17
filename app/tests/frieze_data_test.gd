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
	check(repository.events.size() == 24 and repository.events_for(egypt).size() == 5 and "egy-romaine" not in included_ids and "egy-alexandre" not in included_ids and "egy-rosette" not in included_ids and "gre-actium" not in included_ids and "rom-occident" not in included_ids and int(repository.events[-1]["year"]) == 476, "Les événements hors bornes sont exclus des parties sans modifier leurs dates historiques")
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
