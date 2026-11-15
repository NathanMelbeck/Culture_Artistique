# Culture Artistique

Application locale de culture artistique, développée avec **Godot 4.7.2 et GDScript**. Le lecteur en développement se trouve dans `app/` ; le prototype antérieur est conservé dans `test/`.

## Démarrer le lecteur

Dans Godot, importer **`app/project.godot`**, puis appuyer sur **F5**. Le menu propose Cours, Jeux et Crédits. Cours donne accès aux parcours Égypte, Grèce et Rome ; Jeux conserve son écran d'attente. Les crédits sont consultables.

La proposition des premiers cours est développée sur **`feat/cours-antiquite`**. Chaque période comprend six chapitres rédigés, avec sommaire, texte natif sélectionnable, illustrations existantes légendées, agrandissement dans l'application et quiz de quatre questions expliquées. Le catalogue permet de consulter toute l'Antiquité ou de choisir directement une période. Il ne s'agit pas de pages PDF affichées comme images : seuls les visuels sélectionnés sont extraits des supports, puis intégrés à des blocs de cours rédigés séparément.

Le bouton **Fiche** dans la barre du haut ouvre les **17 fiches de révision (34 pages)** : choix d'une période, recherche par nom, page précédente/suivante, zoom de 100 à 300 % et retour à la largeur du lecteur. Les fiches sont consultées directement dans l'application, hors ligne. La fiche, sa page et son zoom sont conservés lorsque l'on revient au menu pendant la même session.

Depuis PowerShell, avec le moteur installé à côté du dépôt :

```powershell
& '..\Godot\Godot_v4.7.2-stable_win64.exe' --path '.\app'
```

L'application ne fait aucun téléchargement au lancement : les textes, illustrations, fiches et polices sont embarqués. Seuls les boutons de références externes dans les crédits ou les cours ouvrent le navigateur, avec la mention « Internet requis ».

## Commandes

- Souris : cartes et navigation supérieure.
- Tab / Maj+Tab : parcourir les actions ; focus visible.
- Entrée / Espace : activer une action.
- Échap : revenir au menu depuis une rubrique ; fermer une fenêtre de licences.
- Molette : défiler lorsque la fenêtre est plus petite.
- Dans les fiches : flèches gauche/droite pour changer de page, sauf pendant la saisie d'une recherche ou l'utilisation du sélecteur de période.

La fenêtre peut être redimensionnée à partir de 960 × 640. Le menu passe en colonne dans les petites fenêtres. Le bouton Quitter et la fermeture native de la fenêtre terminent l'application.

## Organisation actuelle

```text
app/
  project.godot
  scenes/app_shell.*             Coquille, en-tête et pied de page
  scenes/main_menu/              Menu principal
  scenes/section_preview/        Écran d'attente Jeux
  scenes/courses/                Catalogue, lecteur et quiz des cours
  scenes/credits/                Sources et licences hors ligne
  scenes/revision_sheets/        Lecteur de fiches intégré au lecteur Godot
  components/destination_card.*  Carte de navigation réutilisable
  components/course_block.gd     Paragraphes, encadrés et figures du lecteur
  services/navigation_service.gd Navigation locale
  services/quiz_session.gd       Règles de session partagées des quiz
  repositories/media_repository.gd Résolution des médias locaux
  repositories/revision_repository.gd Catalogue des fiches et pages locales
  repositories/course_repository.gd Cours et notices des illustrations
  repositories/progress_repository.gd Chapitres lus et meilleurs résultats
  content/media.json             Notices et crédits des médias
  content/revision_sheets.json   Périodes, ordre, sources et pages de révision
  content/courses/               Catalogue et textes des trois cours
  content/course_media.json      Provenance des 15 illustrations des cours
  assets/                       Photo, polices et icônes embarquées
  theme/app_theme.gd             Couleurs, typographie et styles
  tests/menu_smoke.gd            Parcours d'entrée et captures
  tests/revision_smoke.gd        Navigation, recherche, zoom et 34 pages
  tests/courses_smoke.gd         Cours, sommaire, corrections et reprise
  tests/course_data_test.gd      Scores et sauvegarde locale isolée
fiche_revision/                 Fiches PDF originales fournies par Nathan
documents_support_cours/        Supports pédagogiques sources inchangés
tools/import_revision_sheets.py Préparation des pages pour Godot
tools/extract_course_assets.py  Extraction des illustrations existantes
tools/validate_courses.py       Validation du catalogue et de ses relations
docs/asset-register.csv          Provenance des ressources
design/maquette-v1/              Sources de conception et lien Figma
test/                           Ancien prototype indépendant
```

Les ressources du lecteur sont toutes sous `app/` pour que les chemins `res://` restent valides lors des futurs exports. Le catalogue éditorial complet et son outil de publication seront ajoutés progressivement selon [la feuille de route](ARCHITECTURE_ET_FEUILLE_DE_ROUTE.md).

## Vérifier le menu

```powershell
$godot = '..\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path '.\app' --editor --quit
& $godot --path '.\app' --script 'res://tests/menu_smoke.gd'
& $godot --path '.\app' --script 'res://tests/revision_smoke.gd'
& $godot --headless --path '.\app' --script 'res://tests/course_data_test.gd'
& $godot --path '.\app' --script 'res://tests/courses_smoke.gd'
```

Le second parcours injecte de vrais événements souris et clavier, vérifie la navigation et le redimensionnement et écrit des captures dans `docs/validation/menu/` (exclues de Git). Il demande un affichage graphique. Aucun export autonome du nouveau lecteur n'est encore fourni.

Le parcours des fiches vérifie aussi les 34 ressources locales, les bornes de pagination, les changements de période, le zoom, les recherches sans accent, les résultats vides et la reprise de lecture. Ses captures sont dans `docs/validation/revision/` (exclues de Git).

Les tests des cours emploient une progression en mémoire et un fichier temporaire unique, sans modifier la progression personnelle. La validation des JSON peut être lancée avec `python tools/validate_courses.py`.

## Les cours d'Antiquité

Les fichiers JSON sous `app/content/courses/` constituent la source de vérité des textes et questions. Chaque chapitre contient des blocs typés et les pages du support utilisées comme base pédagogique. Les cours sont des propositions à relire avec Nathan, pas une transcription littérale des diapositives.

Le lecteur conserve la position de lecture et le quiz en cours pendant la session, y compris après un retour au menu. « Continuer » ou « Marquer comme lu » enregistre le chapitre ; le meilleur score du quiz est enregistré séparément dans `user://learning_progress.json`. La lecture n'est donc pas assimilée à une validation des connaissances. Le fichier est remplacé après écriture d'une version temporaire et les champs invalides sont ignorés.

Les 15 illustrations sont extraites des images contenues dans les supports fournis, avec conservation de leurs proportions et des crédits visibles. Leurs pages et index d'origine sont renseignés dans `app/content/course_media.json` et dans `docs/course-asset-register.csv`. Aucun meuble ou monument n'est redessiné. Une reprise moderne du klismos est explicitement présentée comme telle.

Pour reconstruire ces illustrations, utiliser `python tools/extract_course_assets.py` avec `pypdf` et `Pillow`, puis laisser Godot réimporter les ressources. Les PDF sources ne sont pas chargés à l'exécution. Les notes de couverture pédagogique et de vérification sont dans [docs/cours-antiquite-editorial.md](docs/cours-antiquite-editorial.md).

## Ajouter ou mettre à jour les fiches

Les PDF originaux restent inchangés dans `fiche_revision/`. L'outil de préparation rend leurs pages en WebP haute définition (grand côté de 3000 pixels) et produit un catalogue avec des identifiants stables, les noms de périodes, les alias, les chemins des pages et les empreintes SHA-256 des sources. L'application charge seulement la page consultée ; elle ne lance pas de logiciel PDF et ne dépend pas des dossiers sources extérieurs à `app/`.

Le rendu conserve les textes et visuels dans leur mise en page d'origine. Il ne transforme pas le PDF en cours éditable : la sélection du texte et sa recomposition dans de nouveaux blocs ne sont pas implémentées.

Pour relancer l'import, utiliser Python avec `pypdf` et `Pillow`, et Poppler :

```powershell
python '.\tools\import_revision_sheets.py' --pdftoppm 'CHEMIN\pdftoppm.exe'
```

L'ordre et les associations de périodes sont explicites dans `SHEETS` dans cet outil. Un fichier nouveau ou manquant provoque un message demandant de vérifier ce catalogue plutôt qu'une omission silencieuse. Une modification d'un PDF nécessite de relancer l'import et de laisser Godot réimporter les pages. Python et Poppler ne sont utilisés que pendant la préparation, jamais par le lecteur distribué.

## Images et droits

Les objets, lieux et œuvres doivent être représentés par des **photographies ou dessins existants**, avec une source et des droits de réutilisation vérifiés. Les icônes et formes abstraites de l'interface peuvent être originales. Les anciens dessins du prototype et de la maquette ne sont pas utilisés comme illustrations historiques dans le lecteur.

Photographie du menu : [Cabinet (credenza), Toscane, seconde moitié du XVIᵉ siècle — The Met, 08.175.3](https://www.metmuseum.org/art/collection/search/190788), domaine public, [Met Open Access / CC0](https://www.metmuseum.org/hubs/open-access). Notice brute conservée à côté du JPEG, métadonnées utilisées dans `app/content/media.json`. Licences Lora et Manrope incluses dans `app/assets/fonts/` et consultables avec celles de Godot dans les crédits.
