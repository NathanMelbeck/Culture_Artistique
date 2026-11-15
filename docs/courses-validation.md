# Validation de la proposition des cours d'Antiquité

15 novembre 2026 — Godot 4.7.2 stable, Windows, OpenGL Compatibility, NVIDIA GTX 1060.

## Vérifications effectuées

- Validation Python : trois cours, dix-huit chapitres, douze questions et vingt-deux illustrations existantes ; identifiants, réponses, renvois, fichiers locaux et sources cohérents.
- `courses_smoke.gd` : **46 vérifications réussies, 0 échec**, dont treize captures du rendu réel.
- Catalogue Antiquité et filtre direct par période ; ouverture du lecteur natif et présence de texte sélectionnable.
- Construction des dix-huit chapitres avec le même lecteur ; navigation par sommaire et continuation sans statut « lu » ni enregistrement automatique de lecture.
- Carte du Nil à la largeur de lecture, proportions conservées ; vérification de toutes les figures (vingt-deux images distinctes), toutes chargées et avec une hauteur suffisante.
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

Le pipeline d’extraction a été relancé : les dix images PDF sont réextraites, les douze photos de musée et leurs notices conservées. La validation structurelle Python et `git diff --check` passent.

## Rubrique Le Mobilier commune aux périodes

Les trois titres affichés sont vérifiés dans le lecteur. Les douze blocs d’étude de mobilier sont effectivement construits, avec leurs photographies et caractéristiques. Trois captures complémentaires montrent les caractéristiques et les notices dans chaque période. La validation Python impose la présence d’une rubrique `section: mobilier` par cours de période, son titre exact, au moins quatre exemples avec trois caractéristiques chacun et la concordance entre leur notice et celle du média. Les notices brutes, le statut domaine public, les URL des vues sélectionnées et les empreintes des douze images du Met sont contrôlés localement.

## Originaux et reproductions fidèles

La suppression de la réinterprétation de 1825 est vérifiée dans le dépôt de médias et dans le lecteur grec : une représentation attique d’époque est affichée à sa place. Le quiz concerné porte désormais sur les caractéristiques du klismos. La politique commune impose le statut historique et l’association à la période enseignée pour les images de mobilier. Trois contrôles de rejet vérifient qu’une réinterprétation déclarée, une attribution à une autre période et une reproduction sans justificatifs de fidélité sont refusées. Le contrôle reste fondé sur les sources et qualifications relues par l’auteur, pas sur une reconnaissance automatique de l’image.
