# Menu principal — première implémentation

Vérifié le 15 novembre 2026 avec Godot **4.7.2 stable**, Windows, rendu Compatibility / OpenGL 3.3 sur NVIDIA GTX 1060.

## Résultat

- Import de l'éditeur et chargement des ressources réalisés. Le premier lancement dans le bac à sable ne pouvait pas accéder au dossier utilisateur ; les vérifications finales ont été exécutées dans le contexte utilisateur normal.
- Parcours `app/tests/menu_smoke.gd` : **24 vérifications réussies, 0 échec**, dont cinq captures du rendu réel.
- Clic sur chaque carte et retour au menu ; navigation supérieure ; retour depuis le logo et le crédit photo.
- Tab, Entrée, Espace et Échap injectés comme événements Godot.
- Affichage des licences de polices, de Godot et de ses composants tiers dans une fenêtre locale.
- Fenêtres 1440 × 1000, 1280 × 900 et 960 × 640 ; contrôle de l'absence de débordement horizontal et de la présence des textes dans les cartes ; navigation après défilement.
- Revue visuelle des captures, puis correction de la graisse du texte, des dimensions des cartes et de la disposition du menu à 1280 × 900.

Les captures finales se trouvent dans `docs/validation/menu/`, exclu de Git. Les boutons de références externes n'ont pas été activés par le test pour ne pas ouvrir de navigateur ; leur ouverture utilise `OS.shell_open()` uniquement sur clic explicite. Les sources du menu ne contiennent ni client HTTP ni chargement de média distant : photo et polices sont des ressources locales.

## État livré

Le menu, la navigation et les crédits sont utilisables. Cours et Jeux ouvrent des écrans d'attente clairement identifiés. Le lecteur n'utilise ni la progression ni les illustrations historiques de l'ancien prototype. Aucun exécutable autonome du nouveau lecteur n'a été exporté pendant cette étape.

La règle de représentation des objets et lieux est consignée dans la feuille de route. Le JPEG du Met est inchangé ; sa notice, la vérification du domaine public et les crédits sont conservés dans le dépôt. Les ressources du lecteur sont regroupées sous `app/` pour préparer leur inclusion dans les futurs exports.
