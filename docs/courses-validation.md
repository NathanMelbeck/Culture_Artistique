# Validation de la proposition des cours d'Antiquité

15 novembre 2026 — Godot 4.7.2 stable, Windows, OpenGL Compatibility, NVIDIA GTX 1060.

## Vérifications effectuées

- Validation Python : trois cours, dix-huit chapitres, douze questions et quinze illustrations existantes ; identifiants, réponses, renvois, fichiers locaux et sources cohérents.
- `courses_smoke.gd` : **27 vérifications réussies, 0 échec**, dont six captures du rendu réel.
- Catalogue Antiquité et filtre direct par période ; ouverture du lecteur natif et présence de texte sélectionnable.
- Construction des dix-huit chapitres avec le même lecteur ; navigation par sommaire, continuation et état « lu ».
- Agrandissement d'une illustration dans une fenêtre Godot.
- Retour au menu et reprise du même chapitre ; correction d'une erreur, relecture du chapitre concerné et reprise du quiz avec réponse conservée.
- Résultat calculé à partir des réponses, meilleur score distinct des chapitres lus, nouvelle tentative remise à zéro.
- Lecteur à 960 × 640 avec sélecteur de chapitre et boutons dans la fenêtre ; accès aux fiches préservé.
- `course_data_test.gd` : **6 vérifications réussies, 0 échec** ; trois quiz complets, absence de double comptage, refus du passage sans réponse, progression retrouvée après rechargement, absence de doublons, meilleur score préservé, remplacement atomique terminé et champs invalides ignorés.
- Régression : `menu_smoke.gd`, **24 vérifications réussies, 0 échec** ; `revision_smoke.gd`, **29 vérifications réussies, 0 échec**.

Les tests de cours utilisent une progression en mémoire et un fichier de validation unique supprimé après vérification. La progression personnelle n'est pas écrasée. Les captures sont générées sous `docs/validation/courses/`, exclu de Git.

Revue visuelle réalisée sur le catalogue, le lecteur Égypte, les ordres grecs, la correction et le résultat du quiz, ainsi que la disposition compacte. Les titres du sommaire ont été rendus multilignes et les actions des cartes du catalogue alignées après cette revue.

Les références externes n'ont pas été cliquées par les tests pour ne pas ouvrir de navigateurs. Leur action passe par `OS.shell_open()` uniquement sur clic explicite. Textes et illustrations des cours sont des ressources locales. Aucun export autonome ni lecture vidéo ne sont revendiqués pour cette étape.
