# Fiches de révision intégrées

Vérification du 15 novembre 2026, Godot 4.7.2, Windows, OpenGL Compatibility.

## Contenu et préparation

Les 17 PDF du dossier `fiche_revision/` ont été lus avec pypdf et rendus avec Poppler en 34 pages. Les pages ont un grand côté de 3000 pixels et occupent environ 28,9 Mo en WebP. Les sources PDF ne sont pas modifiées. Chaque fiche possède un identifiant stable, un groupe, un titre, des alias, un chemin source, une empreinte SHA-256 et la liste des pages dans `app/content/revision_sheets.json`.

Ces documents sont fournis par Nathan. Les textes et images, ainsi que les crédits présents sur les pages, sont conservés. Leur import ne leur attribue pas une nouvelle licence et ne les assimile pas à la photographie CC0 du menu.

Les supports dans `documents_support_cours/` n'ont pas été intégrés aux cours pendant cette étape.

## Résultats

- Import Godot de toutes les nouvelles ressources et scripts : terminé sans erreur.
- `revision_smoke.gd` : **29 vérifications réussies, 0 échec**, dont trois captures.
- Les 34 textures sont chargées avec les dimensions attendues.
- Accès depuis le nouveau bouton, sélection de période, recherche sans accent, recherche vide et sans résultat.
- Navigation entre les deux pages, bornes de pagination, flèches gauche/droite.
- Zoom à 250 %, défilement horizontal, retour à la largeur disponible.
- Retour au menu puis reprise de la même fiche, page et échelle pendant la session.
- Passage aux fiches précédente/suivante et arrêt à la fin du catalogue.
- Fenêtres de 1440 × 1000 et 960 × 640 ; sélection compacte et commandes restant dans la fenêtre.
- Régression du menu : `menu_smoke.gd`, **24 vérifications réussies, 0 échec**.
- Revue des 17 premières pages sur planche contact, ainsi que des captures du lecteur, de son zoom et de sa disposition compacte.

Les captures sont sous `docs/validation/revision/` (exclues de Git). Le lecteur n'appelle ni un navigateur ni un logiciel PDF : il charge des ressources `res://assets/revision_sheets/`. Python, pypdf, Pillow et Poppler ne sont nécessaires que pour préparer de nouvelles pages sur le poste de développement.

La lecture reste une présentation des pages originales, sans sélection de texte ni reflow. Aucune validation historique ou modification éditoriale du contenu des fiches n'a été réalisée.
