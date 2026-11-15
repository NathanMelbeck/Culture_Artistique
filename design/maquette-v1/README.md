# Culture Artistique — Maquette V1

Direction visuelle : une interface éditoriale inspirée d'un atelier et d'un musée. Ivoire, vert forêt, sauge et bronze ; titres Lora et texte Manrope. Les illustrations sont des schémas originaux, pas des reproductions d'objets de musée.

## Fichier Figma

[Ouvrir la maquette sur l'accueil](https://www.figma.com/design/ruQLolXUGJUfUyIQ4f4Buc?node-id=7-2)

Fichier créé dans les brouillons du compte Figma connecté. Les neuf premiers écrans ont été construits en calques natifs : textes, frames, instances de composants et vecteurs. Aucune capture complète d'interface n'a été placée comme image de fond.

Le fichier comprend des styles de texte, une collection de variables de couleur et de géométrie, des composants communs et des illustrations vectorielles. Le bloc « Composants · Navigation, cartes et illustrations » se trouve sous les écrans et contient leurs composants principaux.

**Limite rencontrée :** l'offre Figma Starter a bloqué les appels après la création du neuvième écran. Les crédits, la planche des fondations, les interactions de prototype et la revue visuelle finale de tous les écrans n'ont donc pas été terminés dans Figma. Ces deux dernières planches sont préparées en HTML et en SVG localement. Le premier écran a été inspecté et ses alignements corrigés ; les contrôles de rendu locaux couvrent les onze planches. Une revue complète du rendu Figma reste nécessaire quand les appels seront de nouveau disponibles.

## Les planches

| Fichier | Écran | Dans Figma |
|---|---|---|
| 01-accueil | Menu principal Cours / Jeux / Crédits et reprise de lecture | Oui |
| 02-catalogue | Regroupement Antiquité, civilisations et filtres | Oui |
| 03-cours | Cours avec sommaire, illustration, vidéo locale et accès au quiz | Oui |
| 04-recherche | Recherche par spécificité : sgabello et associations | Oui |
| 05-jeux | Choix entre quiz, Timeline et frise à remplir | Oui |
| 06-quiz | Question visuelle et choix de réponse | Oui |
| 07-correction | Exemple de correction d'une mauvaise réponse | Oui |
| 08-timeline | Une carte piochée à insérer avant/après/entre, dates cachées | Oui |
| 09-frise | Frise structurée à compléter avec des étiquettes | Oui |
| 10-credits | Crédits et références | SVG prêt à importer |
| 11-systeme-visuel | Palette, typographie et exemples de composants | SVG prêt à importer |

Les textes, quantités de cours, niveaux de progression et durées des vidéos sont des exemples de conception. Les écrans présentent plusieurs périodes pour illustrer le produit ; ils ne constituent pas une application pédagogique fonctionnelle ou un catalogue historique validé. Les états question et correction sont des exemples distincts, sans simulation de toutes les réponses possibles.

## Reprendre le travail

1. Ouvrir le lien Figma et modifier les textes ou les composants.
2. Pour les crédits et les fondations, glisser les SVG correspondants de `figma-svg/` sur le canvas Figma. Ces fichiers contiennent des formes, des vecteurs et des éléments SVG de texte ; ce ne sont pas des captures PNG aplaties. Vérifier la typographie après l'import.
3. Lorsque les appels Figma seront de nouveau disponibles, les identifiants existants de `figma-state.json` permettront de poursuivre sans recréer les écrans.

## Fichiers locaux

- `index.html` : vue d'ensemble des onze planches.
- `screens/` : chaque écran HTML autonome, avec les polices intégrées.
- `previews/` : captures locales pour la revue, sans prétendre qu'il s'agit d'exports du fichier Figma.
- `figma-svg/` : planches vectorielles importables.
- `figma-state.json` : identifiants et état de création dans Figma.
- `build-design.cjs` : génération des pages de conception.
- `render-design.cjs` : contrôle des dimensions et préparation des calques.
- `figma-native.js` : construction des calques natifs et composants.
- `export-svg.cjs` : export vectoriel de secours.

Ces fichiers sont des sources de maquette, distinctes du projet Godot. Aucun commit ni push n'a été effectué pour cette étape.

## Polices et ressources

Lora et Manrope proviennent du dépôt officiel `google/fonts`, avec leurs licences OFL conservées dans `fonts/`. Les illustrations de mobilier sont issues du prototype local et les monuments sont des dessins vectoriels originaux de conception. Les boutons et champs de recherche Figma utilisent des instances adaptées de Simple Design System ; les autres composants sont locaux au fichier.
