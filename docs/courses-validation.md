# Validation de la proposition des cours d'Antiquité

16 novembre 2026 — Godot 4.7.2 stable, Windows, OpenGL Compatibility, NVIDIA GTX 1060.

## Vérifications effectuées

- Validation Python : trois cours, vingt et un chapitres, dix-sept questions, trente-cinq illustrations existantes et quatorze types de colonnes illustrés individuellement ; identifiants, réponses, renvois, fichiers locaux et sources cohérents.
- `courses_smoke.gd` : **89 vérifications réussies, 0 échec**, avec captures de chaque type de colonne, des repères techniques et des zooms.
- Catalogue Antiquité et filtre direct par période ; ouverture du lecteur natif et présence de texte sélectionnable.
- Construction des vingt et un chapitres avec le même lecteur ; navigation par sommaire et continuation sans statut « lu » ni enregistrement automatique de lecture.
- Carte du Nil à la largeur de lecture, proportions conservées ; vérification de toutes les figures (trente-cinq images distinctes), toutes chargées et avec une hauteur suffisante.
- Lecteur d’image intégré : agrandissement réel, défilement, vue entière, ajustement en largeur et adaptation à 960 × 640.
- Présence de la preuve du placage et capture de ses légendes et notices.
- Retour au menu et reprise du même chapitre ; correction d'une erreur, relecture du chapitre concerné et reprise du quiz avec réponse conservée.
- Résultat calculé à partir des réponses, meilleur score conservé, nouvelle tentative remise à zéro.
- Lecteur à 960 × 640 avec sélecteur de chapitre et boutons dans la fenêtre ; accès aux fiches préservé.
- `course_data_test.gd` : **6 vérifications réussies, 0 échec** ; trois quiz complets, absence de double comptage, refus du passage sans réponse, absence de statut de lecture exposé, meilleur score préservé après rechargement, remplacement atomique terminé, champs invalides ignorés et anciens champs de lecture préservés sur disque sans être utilisés.
- Régression : `menu_smoke.gd`, **24 vérifications réussies, 0 échec** ; `revision_smoke.gd`, **29 vérifications réussies, 0 échec**.

Les tests de cours utilisent une progression en mémoire et un fichier de validation unique supprimé après vérification. La progression personnelle n'est pas écrasée. Les captures sont générées sous `docs/validation/courses/`, exclu de Git.

Revue visuelle réalisée sur le catalogue, le lecteur Égypte, le zoom de la carte du Nil, le coffret de Kemeni et sa légende sourcée, la chaise de Reniseneb, les ordres grecs, la correction et le résultat du quiz, ainsi que la disposition compacte. Les titres du sommaire ont été rendus multilignes et les actions des cartes du catalogue alignées après cette revue.

Les références externes n'ont pas été cliquées par les tests pour ne pas ouvrir de navigateurs. Leur action passe par `OS.shell_open()` uniquement sur clic explicite. Textes et illustrations des cours sont des ressources locales. Aucun export autonome ni lecture vidéo ne sont revendiqués pour cette étape.

Le pipeline d’extraction a été relancé : les dix images PDF sont réextraites, les vingt-deux photos de musée et les trois dessins de référence avec leurs notices sont conservés. La validation structurelle Python et `git diff --check` passent.

## Rubrique Le Mobilier commune aux périodes

Les trois titres affichés sont vérifiés dans le lecteur. Les douze blocs d’étude de mobilier sont effectivement construits, avec leurs photographies et caractéristiques. Trois captures complémentaires montrent les caractéristiques et les notices dans chaque période. La validation Python impose la présence d’une rubrique `section: mobilier` par cours de période, son titre exact, au moins quatre exemples avec trois caractéristiques chacun et la concordance entre leur notice et celle du média. Les notices brutes, le statut domaine public, les URL des vues sélectionnées et les empreintes des vingt-deux images du Met sont contrôlés localement.

## Originaux et reproductions fidèles

La suppression de la réinterprétation de 1825 est vérifiée dans le dépôt de médias et dans le lecteur grec : une représentation attique d’époque est affichée à sa place. Le quiz concerné porte désormais sur les caractéristiques du klismos. La politique commune impose le statut historique et l’association à la période enseignée pour les images de mobilier. Trois contrôles de rejet vérifient qu’une réinterprétation déclarée, une attribution à une autre période et une reproduction sans justificatifs de fidélité sont refusées. Le contrôle reste fondé sur les sources et qualifications relues par l’auteur, pas sur une reconnaissance automatique de l’image.

## Sculpture et colonnes

- Les vingt et un chapitres sont effectivement construits ; les quatre illustrations de la sculpture égyptienne sont présentes dans le nouveau chapitre.
- Les chapitres de colonnes égyptiennes et romaines sont accessibles par le sommaire ; le chapitre des ordres grecs est enrichi et conserve son identifiant.
- Tous les médias locaux sont chargés ; les références et les empreintes des vues du Met passent la validation structurelle.
- Le quiz grec comporte désormais cinq questions : le parcours d’erreur, la relecture et le score sont vérifiés avec ce nombre variable. Le test de données termine les trois quiz enrichis sans double comptage.
- Le sommaire égyptien de huit chapitres est défilant à 1280 × 720, avec les commandes du bas dans la fenêtre. Le mode compact à 960 × 640 reste utilisable.
- Captures supplémentaires : sculpture égyptienne, colonnes égyptiennes, colonnes romaines et sommaire égyptien défilant. Revue visuelle des nouvelles dispositions et des photographies retenues.

## Illustrations individuelles et repères techniques

- Quatorze blocs sont construits avec une image d’au moins 400 pixels de haut : six types égyptiens, trois grecs et cinq romains. Le validateur compare leurs identifiants à la liste attendue par période et impose trois indices de reconnaissance par type.
- Les cadrages normalisés restent dans les limites de l’image source. Les libellés et définitions des repères sont présents ; leurs coordonnées sont vérifiées. Les légendes natives restent sélectionnables et ne dépendent pas de la définition du dessin d’origine.
- Revue visuelle des types, du dessin des parties égyptiennes, de l’anatomie ionique, du détail tore/scotie et de l’entablement dorique. Les pointeurs des moulures ont été ajustés après examen du rendu. Les originaux fragmentaires, restaurés ou remontés restent signalés comme tels.
- Le zoom du chapiteau composite conserve le cadrage et ses deux repères. Son affichage initial a été corrigé pour attendre la disposition de la zone défilante ; les images plus petites que la zone sont centrées. Le schéma ionique et ses sept repères tiennent en vue entière dans le zoom à 960 × 640.
- Les trois nouveaux dessins sont identifiés comme références pédagogiques ; ils ne sont pas présentés comme des objets antiques. Les notices Wikimedia brutes, les URL de téléchargement, les empreintes SHA-256, l’auteur et la licence sont vérifiés. La distinction domaine public / CC BY-SA 4.0 est conservée. Le schéma de JLVwiki et ses repères portent la même licence.
- Les SVG n’utilisent aucun script ni contenu distant. Leur image embarquée éventuelle est locale dans le SVG. Aucune source graphique n’est téléchargée à l’exécution.

Les trois planches de référence sont archivées sans retouche ; le cadrage et les flèches sont appliqués dans le lecteur. Le zoom ne peut pas ajouter de détails absents des petites images originales ; les termes et explications sont donc rendus en texte natif, et des photos de musée en haute définition complètent les schémas.
