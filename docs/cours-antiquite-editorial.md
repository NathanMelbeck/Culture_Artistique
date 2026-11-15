# Proposition de cours d'Antiquité

Branche de travail : `feat/cours-antiquite`. Base : `81f4c7b` sur `main`.

## Intention pédagogique et couverture

Les supports définissent les thèmes ; les textes sont rédigés pour le lecteur. Les chapitres sont rendus avec les mêmes composants Godot : paragraphes sélectionnables, listes, encadrés, figures légendées et références. Les PDF originaux sont inchangés. Les quinze visuels sont des images existantes extraites des supports, pas des reconstitutions générées.

| Cours | Base examinée | Parcours rédigé |
|---|---|---|
| Égypte | 18 pages | Nil et repères ; pouvoir, croyances et écriture ; architecture ; conventions des images ; mobilier et bois ; synthèse d'observation. |
| Grèce | 11 pages | Cités et chronologie ; mythes et céramique ; sculpture ; ordres ; motifs et mobilier ; synthèse argumentée. |
| Rome | 7 pages | Repères et échanges ; images du pouvoir et du divin ; architecture ; intérieurs et décor ; mobilier ; comparaison des héritages antiques. |

Le validateur compte 4 433 mots dans les blocs des trois cours, hors objectifs, introductions, légendes et quiz. Chaque parcours comprend six chapitres et quatre questions avec correction et renvoi au chapitre pertinent. Les pages utilisées sont indiquées dans chaque chapitre JSON.

Les contenus restent une première proposition à valider avec Nathan. Aucun média vidéo n'a été ajouté : aucun fichier de vidéo pédagogique n'a été fourni pour cette étape.

## Points corrigés ou nuancés

| Sujet du support | Traitement retenu et appui |
|---|---|
| Chronologie égyptienne | Repères approximatifs cohérents : Ancien Empire vers 2650–2150, Moyen Empire vers 2030–1640, Nouvel Empire vers 1550–1070 av. J.-C. La périodisation ne doit pas être comprise comme une date exacte commune à tous les auteurs. [Ressource éducative du Met](https://resources.metmuseum.org/resources/metpublications/pdf/The_Art_of_Ancient_Egypt_A_Resource_for_Educators.pdf), [chronologie du Met](https://www.metmuseum.org/fr/toah/ht/02/afe.html). |
| Momification | Distinction entre organes protégés dans les canopes et cerveau retiré ; natron utilisé pour dessécher, avec variation des pratiques. [Australian Museum](https://australian.museum/learn/cultures/international-collection/ancient-egyptian/how-were-ancient-egyptians-mummified/). |
| Écriture et construction égyptiennes | Abandon des règles universelles de lecture et des affirmations sur l'invention de la construction sans mortier. On conserve les thèmes utiles sans reprendre des chiffres spectaculaires non vérifiés sur les pyramides. |
| Sculpture grecque | Distinction entre kouros et korè, puis évolutions. Pas de règle affirmant l'absence absolue de nu féminin. [Art archaïque](https://www.metmuseum.org/essays/greek-art-in-the-archaic-period), [Aphrodite, notice du Met](https://www.metmuseum.org/art/collection/search/253504). |
| Ordres grecs | Les cannelures ne sont pas exclusives à l'ionique ; l'ordre dépasse la seule forme du chapiteau. [Architecture en Grèce ancienne, Met](https://www.metmuseum.org/essays/architecture-in-ancient-greece). |
| Mobilier grec | La photographie du klismos est présentée comme une reprise postérieure, sans lui attribuer une datation ou un auteur non documentés. [Notice comparative d'une reprise vers 1825, Met](https://www.metmuseum.org/art/collection/search/1658). |
| Rome et les représentations | Abandon des généralisations sur le bronze remplaçant la pierre et sur toutes les images féminines. On étudie les fonctions et les choix d'image. [Portrait romain, Met](https://www.metmuseum.org/essays/roman-portrait-sculpture-the-stylistic-cycle). |
| Décors romains | Distinction entre tesselles, peinture et autres revêtements ; aucune règle générale de fragilité. [Peinture romaine, Met](https://www.metmuseum.org/essays/roman-painting). |
| Architecture romaine | Différence de fonction entre théâtre et amphithéâtre, ainsi qu'entre pont-aqueduc et édifice de spectacle. [Théâtre et amphithéâtre, Met](https://www.metmuseum.org/it/essays/theater-and-amphitheater-in-the-roman-world), [pont du Gard, UNESCO](https://whc.unesco.org/en/list/344/), [Panthéon, Turismo Roma](https://turismoroma.it/en/node/1107). |

Les images de plafonds modernes des diapositives consacrées aux dieux ne sont pas utilisées comme représentations antiques. Une photographie d'objet sans notice précise reçoit une légende limitée à ce que le support permet d'affirmer. La date du modèle, celle de l'objet conservé et celle d'une reprise sont explicitement distinguées.

## Reprendre les contenus

- Textes et quiz : `app/content/courses/egypte.json`, `grece.json`, `rome.json`.
- Catalogue des parcours : `app/content/courses/catalogue.json`.
- Illustrations, légendes, source PDF/page/index : `app/content/course_media.json`.
- Registre de provenance : `docs/course-asset-register.csv`.
- Validation structurelle : `python tools/validate_courses.py`.

Les cours ne recopient pas les fiches de révision. Les fiches restent leur propre rubrique et leur propre format de lecture. Les ressources externes sont facultatives et identifiées comme nécessitant Internet ; aucune n'est chargée automatiquement.
