# Audit de Chroniques — Frise à remplir

Version examinée le 18 novembre 2026 sur la branche `codex/frise-a-remplir`, commit `8e3b51d`. Périmètre examiné dans Godot 4.7.2 sous Windows, avec l’Antiquité et les sélections à une période. Les règles de référence sont FRI-01 à FRI-15 de la [feuille de route](../ARCHITECTURE_ET_FEUILLE_DE_ROUTE.md). Les sept [maquettes approuvées](../design/maquette-frise-v2/index.html) servent de référence visuelle.

## Corrections vérifiées le 19 novembre 2026

| Parcours | Comportement de la version corrigée |
|---|---|
| Choix des bornes | Hors des cartes, les cinq propositions sont neutres à l’ouverture. Le clavier ou la souris met en avant une seule carte. Une réponse éliminée garde la mention « Écartée ». Chaque question rappelle que la borne vient de la fiche du style. |
| Placement | Le texte de la date et sa case acceptent la carte. Le repère juste conserve son cadre vert et son cadenas après un clic. Les titres longs tiennent sur leur face. En petite fenêtre, les cartes en main s’agrandissent au survol ou au focus. |
| Pioche et défausse | La distribution, le mélange, la pose, l’échange et le retour des cartes sont animés. La défausse devient disponible lorsqu’un repère recyclé peut remplacer la carte choisie. Le focus revient à la remplaçante. En seconde chance avec dix erreurs, sept cartes arrivent en main et les trois autres sont visibles en pioche. |
| Résultats | L’essai initial marque chaque erreur et distingue les réussites. Cliquer sur la chaise de Reniseneb à gauche ouvre son explication et indique sa date proposée et sa date attendue. « Toute la frise » donne aussi accès aux bonnes réponses, aux cours et aux fiches des repères. Un sans-faute ouvre directement la revue complète. |
| Reprise et son | « Reprendre ma partie » rétablit la session et ses périodes après un passage par la sélection. Les sons de carte et de validation sont locaux. Le haut-parleur commande uniquement les sons de Chroniques. |
| Fluidité | La sélection change le cadre de la carte en place. La pose met à jour les emplacements modifiés, la main et les compteurs en conservant la position du plateau. Le test vérifie que le même plateau reste à l’écran entre la sélection et la pose. |

Les tests des règles et du parcours souris/clavier ont été exécutés dans Godot 4.7.2 sous Windows. Ils couvrent notamment les deux tentatives, le parcours sans faute, le retour d’une fiche et les titres à 960 × 640. Le mode court FRI-14 reste programmé pour une évolution ultérieure.

## Constats de l’audit initial du 18 novembre

Les observations ci-dessous décrivent le commit `8e3b51d` et conservent les étapes qui ont permis de reproduire les défauts.

### Problèmes prioritaires observés

| Priorité | Reproduction et résultat observé | Critère pour accepter la correction |
|---|---|---|
| Haute · Explication de la mauvaise œuvre | Échanger le coffret de Kemeni et la chaise de Reniseneb, valider, choisir « Voir la correction », puis cliquer sur la chaise **à gauche** à la date du coffret. Le panneau explique le coffret. Les boutons de cours et de source suivent eux aussi l’événement attendu à cet emplacement. | Cliquer sur une carte de l’essai identifie l’œuvre cliquée, sa date proposée et sa date attendue. Cliquer à droite ouvre les informations de la carte corrigée. |
| Haute · Trois intitulés incomplets | Avec les cartes posées, le jeu affiche deux lignes sur trois pour Hatchepsout, Amenhotep IV et les éléments ioniques du temple d’Artémis à Sardes. L’infobulle contient le texte complet. Le défaut existe déjà dans la composition de référence de 1600 × 1000. | Lire l’intégralité de chaque intitulé sur la carte posée, y compris avec une photo ou un cadenas, aux deux tailles de fenêtre testées. |
| Haute · Clic sur la date sans effet | Sélectionner un repère en main, puis cliquer sur le texte « vers 3 100 av. J.-C. ». La carte reste en main. Cliquer juste en dessous, dans la case, la pose immédiatement. Le texte et la case forment deux zones distinctes. | Le texte de la date et sa case acceptent la même association. Le clavier conserve un seul arrêt utile par emplacement. |
| Haute · Défausse inaccessible dans deux situations | **Repères** — Renvoyer un repère rouge dans la pioche, puis sélectionner un autre repère en main. Le moteur autorise sa défausse, mais le bouton est absent. **Seconde chance** — Avec dix erreurs, sept cartes arrivent en main et trois restent en pioche. La pioche et la commande de défausse disparaissent. Les nouvelles cartes arrivent tout de même après une pose. | Dès qu’une remplaçante autorisée existe, le joueur peut défausser et connaître le nombre de cartes encore disponibles. Les événements restent réservés pendant la phase des repères. |
| Moyenne · Changement de périodes sans chemin de retour | Pendant une partie, ouvrir l’icône de choix des périodes. L’écran propose « Commencer la frise » ou le retour au catalogue. La session précédente existe encore en mémoire, mais aucune commande ne permet de la reprendre. « Commencer » la remplace et redemande la première borne. Le retour par l’accueil ordinaire conserve bien la partie. | Pouvoir annuler le changement de périodes et retrouver sa main et son plateau. |
| Moyenne · Révision incomplète après une erreur | Après une partie imparfaite, la comparaison parcourt uniquement les emplacements erronés. Les repères de période étant forcément justes à la validation, leurs fiches et les explications des autres cartes réussies sont inaccessibles depuis cette comparaison. Avec un score parfait, la liste contient toutes les cartes. | Garder le raccourci vers les erreurs et permettre aussi de revoir chaque carte de la frise terminée, fiche ou cours associé compris. |
| Moyenne · Bilan rouge et vert incomplet | La validation établit le score et identifie les erreurs. Après avoir choisi la correction, le sceau violet marque les cartes déplacées à droite. À gauche, les événements mal placés conservent leur aspect ordinaire. Le joueur ne retrouve pas le bilan des bonnes et mauvaises associations prévu en FRI-07. | Après le choix « Voir les erreurs », identifier les erreurs initiales et les réussites par une couleur et un symbole, tout en gardant le sceau de correction. La seconde chance doit rester possible sans révélation préalable. |

Les deux premières anomalies sont visibles sur les captures de contrôle de la [comparaison](validation/frieze/06-comparaison.png) et de la [seconde chance](validation/frieze/07-seconde-chance.png). Le comportement au clic a aussi été vérifié dans le moteur.

## Choix des bornes — surlignages trompeurs

Un essai à 1280 × 800 avec des déplacements de souris et une réponse au clavier a reproduit trois défauts visuels.

| Geste | Affichage observé | Comportement attendu |
|---|---|---|
| Ouvrir la première question avec la souris hors des cartes, puis passer à la seconde au clavier | À chaque ouverture, la première carte est déjà levée et affiche « Choisir ». Le compteur de tentatives de la question est encore à zéro. La carte surlignée était à gauche lors du test. Le signalement initial concernait la carte de droite. | À l’ouverture avec la souris hors des cartes, présenter cinq options neutres. Donner un repère visible dès que le joueur navigue au clavier. |
| Depuis cet état, survoler la carte de droite | La première carte garde le focus clavier et la carte de droite reçoit le survol. Les deux affichent « Choisir » en même temps. | Une seule carte reçoit la mise en avant principale à un instant donné. |
| Donner une mauvaise réponse, sortir le pointeur puis revenir sur cette carte | La carte éliminée se soulève et affiche à nouveau « Choisir » malgré son bouton désactivé. | Une réponse éliminée conserve son état d’erreur et cesse de proposer « Choisir ». |

Le jeu attribue automatiquement le focus à la première proposition. Les signaux de survol et de focus pilotent ensuite le même effet indépendamment. Le test de capture habituel retire le focus et déplace le pointeur avant d’enregistrer l’image, ce qui masque le premier défaut.

## Autres défauts et points de lisibilité

- **Parcours au clavier.** Après une défausse, la sélection est vidée et le focus disparaît. Le joueur doit reprendre la navigation pour atteindre la nouvelle carte. Le test d’entrée clavier couvre déjà la sélection et la pose, mais pas le retour du focus après une défausse.
- **Partie parfaite.** Avec zéro erreur, le résultat affiche tout de même « Choisissez votre façon de revoir les erreurs ». L’écran suivant s’intitule « Cartes corrigées » et explique comment repérer les cartes déplacées. Un bilan de réussite devrait inviter à revoir les œuvres ou à rejouer.
- **Bornes de style.** Les valeurs sont exactes pour les fiches. Sur les cinq cartes de choix, « Égypte antique » et « fin de la période » rendent pourtant possible une lecture historique de la réponse « 400 av. J.-C. ». La précision « style de la fiche » est disponible dans la sélection et le contenu pédagogique. Elle gagnerait à rester visible au moment de répondre.
- **Petite fenêtre.** À 960 × 640, la composition est réduite à 60 %. Certains libellés de 11 unités s’affichent à environ 6,6 pixels. Le survol soulève légèrement les cartes sans les agrandir. Les commandes restent utilisables pendant le test, mais les légendes et les crédits sont difficiles à lire à cette taille.
- **Son.** L’icône de haut-parleur agit sur le bus audio général de l’application. Le jeu inspecté ne déclenche aucun son de carte, de réussite ou d’erreur. C’est une décision de présentation à prendre, distincte des règles validées.
- **Fluidité.** Sélectionner ou défausser une carte reconstruit le plateau entier. À 960 × 640, pour un plateau de l’Antiquité comportant 247 contrôles dans la mesure, douze reconstructions ont pris **40 à 50 ms**, médiane **46,6 ms**, sur le PC de test. C’est déjà plus que les 16,7 ms d’une image à 60 Hz. La mesure porte uniquement sur la reconstruction synchrone de l’interface. Elle ne donne pas la cadence moyenne d’une partie. Ce point mérite d’être traité avant d’animer les déplacements de cartes.

## Animations et retours visuels manquants

Le survol d’une carte en main est animé sur 0,10 seconde et le glisser-déposer suit déjà le pointeur. Les cartes de borne se soulèvent et s’éclairent au survol ou au focus. Les mouvements ci-dessous restent à réaliser. Les propositions décrivent l’effet attendu, sans fixer de durée de jeu supplémentaire.

| Ordre | Action | Ce qui devrait être perceptible |
|---|---|---|
| 1 | **Défausser et remélanger** | La carte choisie quitte la main et rejoint la pioche. Le paquet réagit au mélange et la remplaçante se détache du paquet pour rejoindre la main. Conserver la règle actuelle qui empêche de repiocher immédiatement la même carte. |
| 2 | Distribuer et piocher | Les cartes partent du paquet et se rangent en éventail. Après le dernier repère validé, le joueur voit la première main d’événements arriver. |
| 3 | Poser, échanger et reprendre | La case ciblée se distingue pendant le survol. Une carte s’y pose, deux cartes échangées changent visiblement de place, et un dépôt hors case ramène visuellement la carte à son origine. Le reste de la main se resserre. |
| 4 | Valider ou recycler un repère | Un repère juste prend sa couleur et son cadenas. Un repère faux reçoit un signal bref, puis son bouton de retour. Quand le joueur l’utilise, la carte rejoint visiblement la pioche mélangée. |
| 5 | Choisir les bornes | Conserver les cinq cartes au centre et le fond sombre. Faire apparaître le choix, distinguer la réponse validée, puis enchaîner vers la seconde borne ou le plateau. |
| 6 | Valider la frise et revoir ses erreurs | Faire apparaître le bilan puis, si le joueur le demande, rendre lisible la correspondance entre l’ancienne position et la correction. En seconde chance, seules les erreurs reviennent dans la main ou la pioche. Les bonnes réponses restent en place. |

## Vérification des règles

| Règles | État au 18 novembre | Vérification |
|---|---|---|
| FRI-01, FRI-02 | En place | Égypte + Rome inclut la Grèce. Cinq propositions par borne, début puis fin, nouvelle tentative après erreur. Les six bornes du catalogue correspondent aux fiches. Les événements hors intervalle sont filtrés. |
| FRI-03 | Partielle | Cartes sans date, glisser-déposer et sélection suivie d’un clic dans la case fonctionnent. Le clic sur le texte de la date échoue. |
| FRI-04, FRI-05, FRI-10 | Mécanique en place, commandes partielles | Maximum de sept cartes. Uniquement les repères intérieurs jusqu’à leur validation, même avec une main incomplète. Grèce seule exclut ses deux bornes. Antiquité distribue quatre repères puis dix-neuf événements. La défausse ordinaire remplace la carte et la recycle. Les deux absences de commande sont détaillées plus haut. |
| FRI-06, FRI-11 | En place | Échanges et retour en main selon la place disponible. Contrôle immédiat des repères, date verte et cadenas pour une réussite, rouge et bouton de retour en cas d’erreur. |
| FRI-07, FRI-08 | Partielles | Validation seulement quand le plateau est complet, score, nouvelle partie et retour du cours fonctionnels. Le marquage final, la consultation de toutes les cartes et l’explication de la carte de gauche sont incomplets. |
| FRI-09 | En place avec une réserve de présentation | Ordre des dates, dates approximatives et intervalles, emplacements équivalents et défilement au bord vérifiés. La distinction entre borne de style et événement historique manque de visibilité pendant les questions. |
| **FRI-12** | **Les deux choix validés sont en place** | L’essai est conservé avant correction et les cartes déplacées reçoivent le sceau violet. La seconde tentative conserve les bonnes réponses verrouillées et redistribue seulement les erreurs, sans repasser par les bornes. Les défauts de consultation et de pioche sont décrits ci-dessus. |
| **FRI-13** | **En place** | Un repère juste ne peut plus être déplacé ni remplacé. Les bandes Égypte, Grèce et Rome couvrent leurs intervalles et restent visibles sur des lignes superposées lors des chevauchements. |
| **FRI-14** | **Validée et volontairement reportée** | Le mode court de huit à dix événements reste à réaliser. Le nombre définitif doit être ajusté lors des essais. |
| **FRI-15** | **Sept écrans présents, animations partielles** | Choix des bornes sur fond sombre, plateau immersif, main en éventail, pioche et états de correction intégrés. La distribution, la défausse, le mélange et les transitions restent à travailler. |

La navigation rapide en cliquant dans la vue d’ensemble reste une proposition à discuter avec Nathan. Elle ne compte pas parmi les règles manquantes.

## Comment les constats ont été vérifiés

- Les suites existantes `frieze_data_test.gd` et `frieze_smoke.gd` ont toutes deux terminé avec **zéro échec**. Le parcours graphique utilise la souris, le clavier et le moteur OpenGL sur une GeForce GTX 1060 6 Go.
- Des essais ciblés dans Godot ont complété ces suites avec un clic sur une date, un échange de deux œuvres, le retour d’un repère rouge, une reprise à dix erreurs, un score parfait, l’ouverture du choix des périodes, la mesure des lignes de texte et la mesure du rafraîchissement. Le défilement horizontal a bien conservé sa position lors d’une sélection en main.
- Certains tests existants lisent le texte du bouton de carte, alors que sa face est composée de libellés enfants. Ces tests ne détectent donc pas, à eux seuls, une date révélée dans un libellé ou un titre tronqué. Les essais concernent le projet lancé dans Godot sous Windows. La version exportée et le ressenti de joueurs restent à évaluer.

Les comportements de correction, d’affichage et d’animation se trouvent principalement dans [l’écran Chroniques](../app/scenes/games/chroniques.gd), [le contrôleur des écrans de jeu](../app/scenes/games/games.gd) et [les règles de la session](../app/services/frieze_session.gd).
