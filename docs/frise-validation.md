# Frise à remplir — règles, architecture et validation

17 novembre 2026 — Godot 4.7.2 stable, Windows, OpenGL Compatibility, NVIDIA GTX 1060.

## Périmètre réalisé

Le menu Jeux ouvre un catalogue avec le premier jeu de frise. Une période, plusieurs périodes ou le groupe Antiquité peuvent être choisis. Les périodes intermédiaires sont ajoutées automatiquement selon l’ordre pédagogique du catalogue. La sélection avec Égypte et Art nouveau est testée avec un catalogue synthétique pour vérifier la règle future, sans ajouter une période fictive au contenu public.

Le joueur retrouve le début minimal puis la fin maximale, parmi cinq propositions à chaque étape, avec nouvelles tentatives jusqu’à la bonne réponse. Il reçoit ensuite sept cartes au maximum. La frise comporte des emplacements datés ; les cartes ne montrent pas leurs dates.

Une pose depuis la main la complète automatiquement depuis la pioche. Une défausse tire une remplaçante puis remet la carte écartée dans la pioche mélangée : cela évite de repiocher immédiatement la même. Un échange avec une case occupée restitue la carte précédente en main ; un échange entre cases permute les cartes. Reprendre une carte en main est aussi possible si la capacité le permet. Aucun événement n’est éliminé et chaque carte appartient à un seul endroit.

Valider apparaît uniquement lorsque toutes les cartes sont placées. Les réponses deviennent vertes ou rouges, accompagnées de symboles. Le joueur peut consulter le détail de chaque réponse, son repère attendu, une explication, la source et le chapitre de cours associé. Rejouer recommence par les bornes. La navigation entre rubriques et la relecture d’un cours conservent la partie pendant la session.

## Organisation du code

- `app/content/games/chronology.json` : trois périodes, cinq propositions par borne et vingt-quatre événements distincts conservés avec leurs explications et sources. Dix-neuf entrent dans les bornes des fiches : cinq égyptiens, sept grecs et sept romains. Les identifiants des cartes ne contiennent pas de date.
- `ChronologyRepository` : catalogue indépendant de l’interface, résolution des périodes intermédiaires, événements sélectionnés et formatage des dates.
- `FriezeSession` : étapes début/fin/placement/résultat, inventaire des cartes, pioche mélangée, déplacements, échanges et validation. Les années issues du JSON sont converties en entiers pour les choix de réponse.
- `scenes/games/` : catalogue, choix des périodes, questions de bornes, plateau, main et correction ; reprise du contexte dans la coquille de l’application.
- `FriezeCard`, `FriezeSlot`, `FriezeHand`, `FriezeTrack` : contrôles Godot réutilisables. Le glisser-déposer vérifie le type de charge, l’identité de la partie et la disponibilité de la carte. Le défilement au bord utilise les positions des événements souris dans le repère du plateau.

Les futurs contenus étendent le catalogue ; ils ne nécessitent pas une scène par période. Le moteur de ce jeu reste indépendant du futur Timeline à dates entièrement cachées.

## Contrôles exécutés

- `tools/validate_chronology.py` : comparaison des bornes avec les en-têtes des PDF originaux et de leurs empreintes avec le catalogue des fiches, bornes ordonnées, absence d’année zéro, cinq choix uniques et réponse attendue présente, sources HTTPS des événements, absence de dates dans les libellés de cartes et liens valides vers les chapitres existants.
- `frieze_data_test.gd` : **24 contrôles réussis, 0 échec**. Sélection automatique présente et future, chevauchements, nouvelles tentatives, capacité de la main, pioche, recyclage sans reprise immédiate, poses et échanges, reprise en main, actions invalides, validation et verrouillage du résultat, dates équivalentes, redémarrage et formatage. Les six bornes des fiches, le filtrage sans altération des dates historiques et une partie de cinq cartes sont vérifiés. Les tests d’inventaire utilisent huit cartes de test indépendantes du contenu public. Cent vingt séries de mutations contrôlent l’unicité et la conservation de toutes les cartes.
- `frieze_smoke.gd` : **36 contrôles réussis, 0 échec**. Événements réels souris et clavier envoyés à Godot : sélection, bornes, distribution, glisser-déposer, échange de cartes posées, dépôt hors plateau, défilement au bord avec carte tenue, sélection avec Espace puis placement avec Entrée, défausse et reprise de navigation. Les sept cartes et le bouton Valider restent dans la fenêtre à 960 × 640. Correction à deux erreurs voulues, ouverture du chapitre associé et nouvelle tentative vérifiées. Une partie Égypte seule utilise −4000 et −400 et affiche cinq cartes, sans pioche restante.
- Régression : menu **24/24**, fiches **29/29**, cours **89/89**, données et sauvegardes des cours **6/6**. Le catalogue des cours conserve trois périodes, vingt et un chapitres, dix-sept questions et trente-cinq images.

Les tests graphiques créent huit captures sous `docs/validation/frieze/`, dossier exclu de Git. Revue visuelle du catalogue, de la sélection automatique, des bornes, du plateau et de la main à 1440 × 1000 et 960 × 640, ainsi que de la correction et de la sélection égyptienne suivant la fiche. La taille des emplacements et le chevauchement de la main ont été ajustés après examen des captures. Le schéma des dates n’est pas proportionnel aux durées, ce qui est indiqué à l’écran.

Les tests utilisent une progression de cours en mémoire. Aucun navigateur n’est ouvert automatiquement et la progression personnelle n’est pas écrasée. Un délai court laisse la fenêtre native se stabiliser avant les premières interactions du test graphique.

## Sources et précautions historiques

Les liens et notices de chaque événement sont conservés dans les données et accessibles depuis la correction. Le jeu ne fait aucune requête réseau pour fonctionner. Aucune image d’objet ou d’architecture n’a été créée : l’interface utilise uniquement des formes de cartes et des repères abstraits.

- Égypte : [NMEC — chronologie historique](https://nmec.gov.eg/historical-timeline/), notices d’objets et publications du Met ; [British Museum — guide Hieroglyphs](https://www.britishmuseum.org/sites/default/files/2022-10/Hieroglyphs_unlocking_ancient_Egypt_large_print_guide_The_British_Museum_2.pdf) pour le décret de la pierre de Rosette. Les règnes et fabrications approximatifs sont signalés.
- Grèce : [The Met — art archaïque](https://www.metmuseum.org/essays/greek-art-in-the-archaic-period), [art hellénistique](https://www.metmuseum.org/essays/art-of-the-hellenistic-age-and-the-hellenistic-tradition), notices d’œuvres et [musée de l’Acropole — Parthénon](https://www.theacropolismuseum.gr/en/exhibit-halls/parthenon-gallery). Le début du chantier et son achèvement sont distincts. L’intervalle du kouros reste un intervalle.
- Rome : [MIT OpenCourseWare — chronologie, p. 2](https://ocw.mit.edu/courses/21h-336-the-making-of-a-roman-emperor-spring-2023/mit21h_336_s23_lec01.pdf), [Parc du Colisée — notice historique, p. 2](https://colosseo.it/sito/wp-content/uploads/2020/07/Carta-della-qualita-dei-servizi-Colosseo.pdf), [Turismo Roma — colonne Trajane](https://www.turismoroma.it/en/places/trajan%E2%80%99s-column) et [The Met — Byzance](https://www.metmuseum.org/fr/essays/byzantium-ca-330-1453).

Les bornes reprennent exactement les en-têtes de la première page des fiches fournies : « Style Égyptien | -4000 à -400 », « Style Grec | -1100 à -100 » et « Style Romain | -800 à 400 ». Il s’agit du découpage des styles utilisé dans les fiches, distinct de la chronologie historique détaillée des civilisations et des événements. Pour l’Égypte, l’en-tête prévaut sur les autres dates mentionnées dans le paragraphe historique de la même fiche. La provenance est conservée dans `bounds_source` pour chaque période.

Le filtre exclut de ce jeu les événements égyptiens de −332, −196 et −30, la bataille d’Actium de −31 et la déposition de Romulus Augustule de 476. Ils restent dans le catalogue avec leurs dates et sources inchangées. Les événements d’un intervalle doivent y entrer entièrement ; leur date n’est jamais tronquée pour les faire entrer dans les bornes.

## Limites actuelles

La partie et son résultat ne sont pas encore sauvegardés après fermeture de l’application. Le jeu ne comporte ni chronomètre, ni vies, ni pénalité de borne. Le paquet comprend tous les événements des périodes retenues ; aucun réglage de difficulté ou de taille de paquet n’est ajouté. Aucun export autonome ni retour de test humain sur le plaisir de jeu n’est revendiqué : les vérifications portent sur le projet exécuté dans Godot.
