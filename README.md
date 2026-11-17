# Culture Artistique

Application locale de culture artistique, développée avec **Godot 4.7.2 et GDScript**. Le lecteur en développement se trouve dans `app/` ; le prototype antérieur est conservé dans `test/`.

## Démarrer le lecteur

Dans Godot, importer **`app/project.godot`**, puis appuyer sur **F5**. Le menu propose Cours, Jeux et Crédits. Cours donne accès aux parcours Égypte, Grèce et Rome ; Jeux propose désormais le premier jeu **Frise à remplir**. Les crédits sont consultables.

Les premiers cours d’Antiquité ont été intégrés à **`main`** après validation. Les parcours comportent huit chapitres pour l’Égypte, six pour la Grèce et sept pour Rome, avec sommaire défilant, texte natif sélectionnable, illustrations légendées, zoom intégré et quiz expliqués. Le catalogue permet de consulter toute l'Antiquité ou de choisir directement une période. Il ne s'agit pas de pages PDF affichées comme images : seuls les visuels sélectionnés sont extraits des supports, puis intégrés à des blocs de cours rédigés séparément.

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
  scenes/games/                  Choix des périodes, frise et correction
  scenes/section_preview/        Ancien écran d’attente conservé
  scenes/courses/                Catalogue, lecteur et quiz des cours
  scenes/credits/                Sources et licences hors ligne
  scenes/revision_sheets/        Lecteur de fiches intégré au lecteur Godot
  components/destination_card.*  Carte de navigation réutilisable
  components/course_block.gd     Paragraphes, sources et encadrés du lecteur
  components/course_figure.gd    Figures proportionnelles et légendes
  components/course_marked_texture.gd Repères sur les images et les détails cadrés
  components/course_image_viewer.gd Zoom et défilement intégrés
  components/frieze_*.gd         Cartes, main et emplacements de la frise
  services/navigation_service.gd Navigation locale
  services/quiz_session.gd       Règles de session partagées des quiz
  services/frieze_session.gd     Bornes, pioche, échanges et correction de frise
  repositories/chronology_repository.gd Catalogue chronologique et sélection
  repositories/media_repository.gd Résolution des médias locaux
  repositories/revision_repository.gd Catalogue des fiches et pages locales
  repositories/course_repository.gd Cours et notices des illustrations
  repositories/progress_repository.gd Meilleurs résultats des quiz
  content/media.json             Notices et crédits des médias
  content/revision_sheets.json   Périodes, ordre, sources et pages de révision
  content/courses/               Catalogue et textes des trois cours
  content/course_media.json      Provenance des 35 illustrations des cours
  content/games/chronology.json  Périodes, bornes et événements sourcés
  assets/                       Photo, polices et icônes embarquées
  theme/app_theme.gd             Couleurs, typographie et styles
  tests/menu_smoke.gd            Parcours d'entrée et captures
  tests/revision_smoke.gd        Navigation, recherche, zoom et 34 pages
  tests/courses_smoke.gd         Cours, sommaire, corrections et reprise
  tests/course_data_test.gd      Scores et sauvegarde locale isolée
  tests/frieze_data_test.gd      Règles et conservation des cartes de frise
  tests/frieze_smoke.gd          Parcours réel et glisser-déposer Godot
fiche_revision/                 Fiches PDF originales fournies par Nathan
documents_support_cours/        Supports pédagogiques sources inchangés
tools/import_revision_sheets.py Préparation des pages pour Godot
tools/extract_course_assets.py  Extraction des illustrations existantes
tools/validate_courses.py       Validation du catalogue et de ses relations
tools/validate_chronology.py    Validation des dates, sources et renvois aux cours
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
& $godot --headless --path '.\app' --script 'res://tests/frieze_data_test.gd'
& $godot --path '.\app' --script 'res://tests/frieze_smoke.gd'
```

Le second parcours injecte de vrais événements souris et clavier, vérifie la navigation et le redimensionnement et écrit des captures dans `docs/validation/menu/` (exclues de Git). Il demande un affichage graphique. Aucun export autonome du nouveau lecteur n'est encore fourni.

Le parcours des fiches vérifie aussi les 34 ressources locales, les bornes de pagination, les changements de période, le zoom, les recherches sans accent, les résultats vides et la reprise de lecture. Ses captures sont dans `docs/validation/revision/` (exclues de Git).

Les tests des cours emploient une progression en mémoire et un fichier temporaire unique, sans modifier la progression personnelle. La validation des JSON peut être lancée avec `python tools/validate_courses.py`.

## Jouer à la frise à remplir

Ouvrir **Jeux → Frise à remplir → Choisir les périodes**. Choisir une période, plusieurs périodes ou toute l’Antiquité. Les périodes intermédiaires sont ajoutées automatiquement : Égypte + Rome inclut Grèce. Le jeu utilise les bornes des en-têtes des fiches de révision : Égypte −4000 à −400, Grèce −1100 à −100 et Rome −800 à 400. Dix-neuf événements entrent dans ces intervalles : cinq pour l’Égypte, sept pour la Grèce et sept pour Rome. Les cinq autres événements du catalogue restent conservés, avec leur datation historique, mais ne sont pas distribués.

Retrouver le début le plus ancien puis la fin la plus tardive, avec cinq choix et autant de tentatives que nécessaire. La main apparaît ensuite en bas, avec sept cartes maximum. Les cartes **Début** et **Fin** correspondant aux deux bornes déjà trouvées sont retirées du paquet selon la sélection de la partie. Les premières cartes piochées sont les repères de période intérieurs, avec leurs dates cachées, puis les événements. Toute l’Antiquité comporte ainsi quatre cartes de période et dix-neuf événements, soit vingt-trois cartes. Égypte seule propose ses cinq événements ; Grèce seule, ses sept événements : leurs cartes de début et de fin sont déjà couvertes par les bornes. Le filtre s’applique aussi aux périodes qui partagent une même borne extérieure.

Glisser une carte sur une date, ou la sélectionner puis cliquer sur un emplacement. **La première phase est réservée aux périodes** : aucun événement n’est distribué tant que tous les repères intérieurs ne sont pas bien placés, même avec moins de sept cartes en main. Toute l’Antiquité commence donc avec quatre cartes. Chaque pose de repère est contrôlée immédiatement : date verte et symbole de confirmation si elle est juste ; carte rouge avec un petit bouton **↶ Pioche** si elle est fausse. Ce bouton libère l’emplacement et remet la carte dans la pioche mélangée. **Piocher** permet de la reprendre lorsqu’une place est disponible en main. Une sélection sans repère intérieur, comme une période seule, passe directement aux événements.

Dès que tous les repères sont corrects, les événements sont distribués automatiquement jusqu’à sept cartes. Chaque pose depuis la main complète celle-ci depuis la pioche. Sélectionner une carte puis **Défausser la sélection** la remplace par une autre autorisée dans la phase courante et la remet dans la pioche mélangée. La carte écartée ne revient pas immédiatement ; sans carte disponible dans la phase courante, la défausse est désactivée. Les repères encore jamais piochés gardent leur priorité après mélange.

Les cartes peuvent être déplacées et échangées avant validation. Les repères restent contrôlés immédiatement, tandis que les événements attendent la correction finale. Le bouton **Valider la frise** apparaît quand toutes les cartes sont placées et les repères de période corrects. La correction utilise vert/rouge et des symboles ; cliquer sur une carte donne sa date attendue, une explication et sa source. Une carte d’événement renvoie au cours ; une carte de période ouvre sa fiche de révision dans l’application, hors ligne. **Rejouer** recommence les bornes et la distribution. Les dates des emplacements sont visibles, celles des cartes sont cachées avant correction. Les espacements ne représentent pas les durées.

La frise défile horizontalement avec sa barre ; faire glisser une carte près d’un bord fait aussi défiler le plateau. La main et les commandes restent visibles à 960 × 640. La partie est conservée lorsque l’on change de rubrique ou que l’on relit un cours pendant la même session. Elle n’est pas encore sauvegardée après fermeture de l’application.

Les événements, repères approximatifs et sources sont dans `app/content/games/chronology.json`. Chaque période indique la fiche et l’en-tête utilisés pour ses bornes. Le découpage des styles suit les fiches ; les dates historiques des événements restent celles de leurs sources. Le validateur compare les bornes aux en-têtes des PDF, sans que l’application ait à lire les PDF à l’exécution. Les sources externes s’ouvrent seulement sur demande ; aucune image ni requête réseau n’est nécessaire au jeu. Vérifier les données avec `python tools/validate_chronology.py` (dépendance de préparation : `pypdf`). Les tests et limites sont détaillés dans [docs/frise-validation.md](docs/frise-validation.md).

## Les cours d'Antiquité

Les fichiers JSON sous `app/content/courses/` constituent la source de vérité des textes et questions. Chaque chapitre contient des blocs typés et les pages du support utilisées comme base pédagogique. Les cours sont des propositions à relire avec Nathan, pas une transcription littérale des diapositives.

Le lecteur conserve la position de lecture et le quiz en cours pendant la session, y compris après un retour au menu. Il ne propose aucun statut « lu » et « Continuer » ne sauvegarde aucun statut de lecture. Seul le meilleur score du quiz est enregistré dans `user://learning_progress.json`. Les éventuels anciens champs de lecture sont conservés sur disque mais ignorés par l’application.

Les 35 illustrations comprennent 10 images extraites des documents pédagogiques, 22 photographies du Met en haute définition sous CC0 et 3 dessins de référence existants issus de Wikimedia Commons. Les légendes décrivent les images, sans mentionner les documents pédagogiques. Les notices précisent matériaux, datation, provenance et restaurations lorsqu’ils sont connus ; la traçabilité technique reste dans `app/content/course_media.json` et `docs/course-asset-register.csv`.

L’Égypte possède un chapitre sur les colonnes et un autre sur la sculpture : bas-relief, haut-relief, ronde-bosse et relief en creux. Le cours grec détaille dorique, ionique et corinthien ; Rome possède un chapitre sur ses types de supports et les ordres, dont toscan et composite. Les parties des colonnes, les critères de reconnaissance et les restaurations des exemples sont expliqués. Les quiz totalisent dix-sept questions avec correction et retour au chapitre concerné. Les compteurs du catalogue sont calculés à partir des données.

Chacun des **14 types de colonnes** possède son illustration et trois indices de reconnaissance. Des repères en lettres renvoient à des définitions françaises : base, fût, collier, chapiteau, abaque, volutes, acanthe, architrave, frise, corniche, triglyphe, métope, tore et scotie. Les photographies d’originaux et les dessins pédagogiques sont qualifiés dans les légendes. Les détails sont cadrés dans le lecteur sans retoucher le fichier source ; les repères suivent le zoom. Les trois nouveaux dessins et leurs notices sont sous `app/assets/courses/diagrams/` : planche de l’Encyclopédie et schéma ionique de F l a n k e r dans le domaine public, schéma dorique de JLVwiki sous CC BY-SA 4.0 (repères et légendes associés sous la même licence).

Chaque période possède la rubrique **Le Mobilier**, couvrant structure, décor et parties souples de l’ameublement. Les trois rubriques actuelles comprennent douze études illustrées : sièges, coffret, tabouret, appui-tête, lits, tables, pied sculpté et candélabre. Les exemples grecs utilisent uniquement des représentations antiques ; la chaise de 1825 a été retirée. Pour les futures périodes, le [modèle de rubrique](docs/modele-section-mobilier.md) prévoit aussi tapisserie d’ameublement, garnitures, textiles et couture selon les sources. Le validateur impose cette rubrique, au moins quatre études illustrées et trois caractéristiques par étude.

Les cartes et planches occupent la largeur de lecture en conservant leurs proportions. Chaque figure dispose d’un lecteur intégré avec zoom, défilement, modes largeur, vue entière et 100 %. Les sources documentaires sont placées près des explications concernées ; les liens ouvrent le navigateur uniquement sur demande. Les derniers chapitres donnent des critères de reconnaissance du mobilier propres à chaque période. Seuls les originaux de la période, les représentations d’époque et les reproductions fidèles documentées sont admis pour illustrer le mobilier. Les réinterprétations sont exclues. Les liens complémentaires sont regroupés sous « Autres ressources ».

Pour réextraire les illustrations provenant des PDF sans modifier les photographies de musée ni leurs légendes, utiliser `python tools/extract_course_assets.py` avec `pypdf` et `Pillow`, puis laisser Godot réimporter les ressources. Les PDF sources ne sont pas chargés à l'exécution. Les notes de couverture pédagogique et de vérification sont dans [docs/cours-antiquite-editorial.md](docs/cours-antiquite-editorial.md).

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
