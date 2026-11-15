# Atelier des Époques — prototype Godot

Prototype de culture artistique pour le BMA ébénisterie, créé et testé avec Godot **4.7.2 stable**, GDScript, rendu Compatibility (OpenGL).

## Essayer sans Godot et sans Internet

1. Extraire complètement `builds/AtelierDesEpoques-Windows.zip` dans un dossier accessible en écriture.
2. Ouvrir `AtelierDesEpoques.exe` par double-clic.
3. Conserver `AtelierDesEpoques.pck` à côté de l'exécutable.

Version Windows x86_64. Aucun serveur, compte, installation de Godot ou téléchargement de contenu n'est nécessaire. Les liens de référence ouvrent le navigateur externe à la demande et nécessitent Internet.

Le dossier portable `data/` est créé lors d'une sauvegarde. Il contient la progression de cette copie. En développement, la progression se trouve dans `.local/progress.json`. Conserver ce dossier lors des mises à jour ; pour retrouver sa progression sur un autre ordinateur, le copier avec l'application.

Cette version embarque le binaire éditeur de Godot comme moteur d'exécution : les modèles d'export optimisés n'étaient pas installés. Elle est donc plus volumineuse qu'une version finale. Le projet ne distribue pas encore un exécutable unique avec ses données intégrées.

## Contenu du test

- Trois cours : Rome antique, gothique, Renaissance.
- Trois illustrations SVG originales, explicitement schématiques.
- Quiz visuel de trois questions, explications, résultat et meilleur score.
- Classement chronologique de trois cartes : glisser-déposer ou sélectionner puis cliquer sur une case ; les cases occupées échangent les cartes.
- Cours lus, activité de frise validée et meilleur résultat de quiz sauvegardés localement.
- Souris, défilement vertical et navigation clavier Tab / Entrée / Espace.

Le catalogue ne cherche pas à dater un meuble réel à partir d'un seul détail. Les périodes sont situées avec prudence et leurs chevauchements sont explicités. Les dessins ne sont pas des photographies ou des reproductions de pièces de musée.

L'éditeur administrateur, les vidéos, les 69 repères de l'autre chat et une véritable frise historique à plusieurs pistes ne sont pas inclus dans ce prototype. La frise présente est un jeu de classement. Le contenu pédagogique complet reste à relire avant publication.

## Projet éditable

Ouvrir `project.godot` dans Godot 4.7.2 et appuyer sur F6 pour la scène ouverte ou F5 pour le projet.

```text
scenes/main.tscn           Scène principale
scripts/main.gd            Cours, quiz, navigation et sauvegarde
scripts/timeline_card.gd   Cartes interactives et dépôt natif
content/catalog.json      Catalogue partagé entre cours et jeux
assets/                   Illustrations SVG originales
tests/                    Tests fonctionnels, entrées souris et captures
docs/                     Captures, résultats et mentions du moteur
builds/                   Application Windows et archive à partager
```

## Vérifier et reconstruire

Depuis PowerShell, adapter uniquement le chemin de l'exécutable Godot :

```powershell
$godotExe = 'D:\Nathan\Projects\Code\Godot\Godot_v4.7.2-stable_win64_console.exe'
$projectDir = 'D:\Nathan\Projects\Code\Culture_Artistique'
& $godotExe --headless --path $projectDir --script res://tests/run_tests.gd -- --self-test
& $godotExe --path $projectDir --script res://tests/ui_input.gd
& $godotExe --path $projectDir --script res://tests/render_smoke.gd
& $godotExe --headless --path $projectDir --export-release 'Windows Desktop' "$projectDir\builds\windows\AtelierDesEpoques.exe"
```

Le preset actuel pointe vers le moteur installé à côté du projet pour cette version portable. Pour un export optimisé, installer les modèles correspondant exactement à la version de Godot, puis vider les deux champs `custom_template` du preset. Un export macOS ou Linux demandera un paquet distinct.

Les tests `run_tests.gd` utilisent exclusivement `tests/.test-progress.json` et ne changent pas la progression personnelle. Les essais d'interface injectent des événements dans Godot ; ils ne sont pas une validation manuelle sur différents ordinateurs.

## Provenance

Les quatre SVG sont des dessins originaux créés pour ce prototype, sans téléchargement d'images. Les liens vers le Met et GrandPalaisRmn sont listés dans `content/catalog.json`. Le moteur Godot et ses composants tiers sont décrits dans `docs/GODOT-LICENSE.txt`, également livré avec la version portable.

Aucun dépôt Git ni dépôt GitHub n'a été créé.
