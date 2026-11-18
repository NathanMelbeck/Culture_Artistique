# Frise — maquette visuelle V2

18 novembre 2026. Sept écrans de conception en 1600 × 1000. Aucun fichier de l’application Godot n’est modifié.

## Voir les écrans

Ouvrir `index.html` dans un navigateur. Les sept écrans sont sous `svg/` ; les captures de contrôle sont sous `previews/`. Le nom « Chroniques » est une proposition de titre pour cette exploration, pas un nom de produit validé.

## Figma et coût

Fichier créé et ouvert : https://www.figma.com/design/tO1OXFLEch1doEVcahuLRJ

Le connecteur a signalé sa limite d’appels du forfait Starter avant toute création de calque : le fichier est encore vide. Il n’a pas été contourné et aucun abonnement n’a été souscrit. Les écrans locaux sont fournis en SVG pour un import manuel dans Figma ; ce ne sont pas des captures aplaties de l’interface. Les cartes photographiques embarquent seulement les images de contenu. Les composants natifs, les interactions et les animations de prototype restent à construire dans Figma lorsque l’accès sera disponible.

Les textes SVG utilisent Lora et Manrope, fournis avec leurs licences dans `fonts/`. Selon la prise en charge du logiciel d’import, le texte et les filtres SVG peuvent nécessiter un ajustement ; les SVG d’origine et la galerie conservent la référence visuelle.

## Direction retenue

- TFT : cinq cartes de choix des bornes au centre, fond temporairement assombri, focus doré.
- Balatro : main, pioche et sensation de manipulation de cartes.
- Hearthstone : présence du plateau, bordures, profondeur et retours visuels.
- Périodes : trois couleurs, bandes empilées dans les zones de chevauchement, repères justes verrouillés.
- Résultat : choisir entre voir la correction automatique avec comparaison et refaire seulement les mauvaises cartes.

Les images d’objets sont des photographies existantes du Met, sous CC0, reprises du catalogue du projet ; voir `credits-images.json`. Les ornements et le monogramme sont abstraits. Il n’y a ni objet antique inventé ni image générée.

## Limites de la maquette

Les écrans représentent des états de conception, pas un jeu fonctionnel ni des animations réalisées. Les panoramas de frise montrent une portion du plateau ; les autres événements sont hors champ. La vue d’ensemble garde les chevauchements lisibles. Le mode court, validé mais reporté, n’est pas présenté comme une option déjà disponible. Le code du jeu attend la confirmation explicite de Nathan.
