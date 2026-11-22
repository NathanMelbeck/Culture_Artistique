# Culture_Artistique — Architecture et feuille de route

Version : 0.31 — 22 novembre 2026

Statut : document de référence initial, à faire évoluer avec les décisions du projet.

Ce document décrit l'application à construire. Il ne signifie pas que les fonctionnalités sont déjà réalisées. Les demandes confirmées sont distinguées des propositions techniques et des décisions encore ouvertes.

## 1. Vision du projet

Créer une application de culture artistique permettant de comprendre les époques, de reconnaître leurs caractéristiques et de vérifier ses connaissances par des jeux. L’application est spécialisée dans les métiers de l’ameublement : ébénisterie, menuiserie, tapisserie d’ameublement et confection/couture. Les cours relient histoire, arts, architecture, mobilier, décors, matériaux et techniques.

Le catalogue a vocation à couvrir progressivement toutes les périodes de l’Antiquité à l’époque contemporaine, avec un premier horizon autour de 2020. Le Moyen Âge et la Renaissance sont les prochaines étapes. Des périodes et des événements postérieurs à 2020 pourront rejoindre les cours, les fiches, les jeux et la collection au fil des années.

L'application doit permettre d'apprendre à partir d'une période, mais aussi de retrouver une période à partir d'un objet, d'un artiste, d'un terme ou d'un détail caractéristique.

Le parcours principal est :

```text
Menu principal
├── Cours
│   ├── Regroupement : Antiquité
│   │   ├── Égypte antique
│   │   ├── Grèce antique
│   │   └── Rome antique
│   ├── Accès direct à une période
│   ├── Recherche et filtres
│   └── Cours d'une période → Quiz de cette période → Correction
├── Fiche (barre du haut) → Période → Lecture intégrée des fiches de révision
├── Jeux
│   ├── Quiz
│   ├── Timeline : piocher et insérer une carte, dates cachées
│   └── Frise à remplir
└── Crédits
```

## 2. Contraintes confirmées

| Sujet | Règle à respecter |
|---|---|
| Usage | Ordinateur principalement ; navigation à la souris et au clavier. |
| Technologie de travail | Godot avec GDScript, sur la base du prototype validé. Version installée lors du test : 4.7.2 stable. |
| Fonctionnement local | Les cours, images, vidéos incluses et jeux fonctionnent sans connexion Internet dès le premier lancement. |
| Distribution | L'utilisateur reçoit une application exécutable. Il n'installe ni Godot, ni un serveur, ni des outils de développement. |
| Références externes | Les liens ouvrent le navigateur et peuvent nécessiter Internet. Ils sont identifiables avant le clic. |
| Administration | Nathan est le seul administrateur et le seul auteur autorisé à modifier ou ajouter le contenu officiel. |
| Invités | Ils peuvent consulter les cours, regarder les vidéos et jouer, sans fonctions de modification du catalogue officiel. |
| Comptes | Aucun compte en ligne nécessaire pour utiliser l'application. |
| Progression | Sauvegarde locale, indépendante du contenu distribué. |
| Navigation | Trois cartes principales : Cours, Jeux, Crédits ; un accès Fiche dans la barre du haut pour les fiches de révision par période. |
| Fin de période | Un bouton donne accès aux quiz portant sur la période étudiée. |
| Correction | Une mauvaise réponse reçoit une explication pédagogique. |
| Dépôt | Dépôt GitHub `NathanMelbeck/Culture_Artistique`, cloné à la racine du projet. |
| Prototype | Conservé dans `test/` comme référence ; ce dossier ne constitue pas l'architecture définitive. |
| Visuels des objets et lieux | Utiliser des photographies ou dessins existants et documentés, avec des droits de réutilisation vérifiés ; ne pas recréer les meubles, œuvres ou architectures en illustration. Les petites icônes et formes de l'interface peuvent être originales. |
| Fidélité historique du mobilier | Pour toutes les périodes, utiliser des originaux documentés, des représentations d’époque ou des reproductions fidèles dont le modèle et la fidélité sont sourcés. Exclure les réinterprétations, adaptations et meubles de style d’une autre époque comme exemples. Identifier les parties restaurées des objets anciens. |
| Niveau des cours | Contenu technique et détaillé : employer et expliquer les mots techniques propres au sujet de chaque section, avec des illustrations et repères légendés lorsque cela aide à comprendre. Cette règle vaut pour les modifications et tous les futurs cours. |
| Niveau des fiches de révision | Présenter seulement le minimum essentiel à savoir ; les développements et le vocabulaire technique détaillé appartiennent aux cours. |
| Accord avant de coder | Avant toute prochaine modification du code, demander confirmation explicite à Nathan et attendre sa réponse. La validation des règles ci-dessous prépare une prochaine session ; elle ne vaut pas autorisation de les implémenter maintenant. |
| Références des jeux | Pour chaque jeu actuel ou futur, choisir ensemble avec Nathan de véritables jeux de référence. Décrire concrètement leur apport au gameplay, à l'apparence et à la fluidité des interactions dans les spécifications. Les inspirations sont retenues avec Nathan avant la conception ou la refonte concernée. |

L'installation et les mises à jour de l'application doivent elles aussi pouvoir se faire avec des fichiers transmis localement. Le développement peut utiliser Internet ; l'exécution de l'application n'en dépend pas.

## 3. Fonctionnalités à réaliser

Les identifiants ci-dessous serviront à relier les tâches, les versions et les critères de validation.

### 3.1. Menu principal et navigation

- **NAV-01 — Menu principal** : afficher Cours, Jeux et Crédits comme trois destinations principales.
- **NAV-02 — Retour** : proposer un retour à l'écran précédent et au menu principal depuis chaque destination.
- **NAV-03 — Contexte** : indiquer la position dans le parcours, par exemple `Cours > Antiquité > Rome antique`.
- **NAV-04 — Continuité** : retrouver la période sélectionnée et la position de lecture en revenant d'un exercice.
- **NAV-05 — Lisibilité** : adapter les panneaux à la taille de la fenêtre et permettre le défilement des cours longs.
- **NAV-06 — Clavier** : rendre les actions importantes accessibles par Tab, Entrée et Espace, avec un focus visible.

L'accès futur à l'outil d'édition sera séparé de ces trois destinations destinées aux invités.

### 3.2. Catalogue des cours

- **COU-01 — Regroupements** : choisir un ensemble pédagogique, notamment Antiquité.
- **COU-02 — Périodes directes** : ouvrir directement Égypte, Grèce ou Rome sans devoir parcourir tout le regroupement.
- **COU-03 — Vue d'ensemble** : un regroupement présente ses périodes, leurs liens et les cours disponibles.
- **COU-04 — Filtres** : préparer le filtrage par période, civilisation ou aire géographique, domaine artistique et type de contenu.
- **COU-05 — Plusieurs cours** : une période peut contenir plusieurs chapitres, ordonnés et identifiables.
- **COU-06 — Cours enrichis** : afficher du texte structuré, des images légendées, des vidéos locales, des notions à retenir et des références.
- **COU-07 — Liens internes** : ouvrir une fiche de vocabulaire, un artiste, un objet ou un autre cours depuis un contenu.
- **COU-08 — Fin de période** : afficher « Vérifier mes connaissances » à la fin du parcours de la période et transmettre son contexte au quiz.
- **COU-09 — Continuité de lecture** : conserver la position pendant la session, sans bouton ni statut « lu ». Le suivi des cours lus est retiré pour le moment.

**COU-10 — Le Mobilier** : chaque période actuelle ou future comprend une rubrique portant exactement ce titre. Elle couvre tous les métiers de l’ameublement, avec des exemples variés et leurs caractéristiques illustrées et sourcées. La validation exige au moins quatre études d’exemple, chacune avec une image, trois caractéristiques et une notice correspondante. Les parties textiles, garnitures et coutures sont développées selon leur documentation et leur importance à l’époque. Le [modèle de rubrique](docs/modele-section-mobilier.md) décrit la préparation et le format réutilisable.

Pour un regroupement comme Antiquité, un récapitulatif pourra conduire à un quiz couvrant ses périodes. Un cours consacré à Rome devra conduire en priorité aux questions pertinentes pour Rome.

Le plan de cours recommandé, adaptable selon les sujets, comprend :

1. Situation dans le temps et dans l'espace.
2. Contexte historique et culturel.
3. Caractéristiques artistiques.
4. Architecture, œuvres et personnes de référence.
5. **Le Mobilier** : rubrique obligatoire de chaque période, avec structure, décor, matériaux, assises, garnitures, textiles et couture selon les sources.
6. Motifs et indices de reconnaissance visuelle.
7. Synthèse, dates et notions essentielles.
8. Exercices et références.

### 3.3. Recherche par spécificité — évolution prévue

- **REC-01 — Recherche locale** : saisir un nom, un terme, un objet, une technique ou une caractéristique sans connexion Internet.
- **REC-02 — Relations** : retrouver les périodes et cours associés, même si la requête n'est pas le titre d'un cours.
- **REC-03 — Variantes** : gérer majuscules, accents, apostrophes et variantes renseignées dans le catalogue.
- **REC-04 — Résultats expliqués** : préciser ce qui correspond à la recherche et pourquoi une période est proposée.
- **REC-05 — Navigation** : ouvrir la fiche correspondante, la période associée ou le cours pertinent.
- **REC-06 — Absence de résultat** : afficher un message utile et permettre de modifier la requête ou de revenir aux filtres.

Exemples de comportements attendus :

| Recherche | Résultat attendu |
|---|---|
| `romain` | Rome antique et les cours associés grâce aux alias renseignés. |
| `sgabello` | Fiche du terme ou du meuble, puis période(s) et cours documentés dans le catalogue. |
| `Léonard de Vinci` | Fiche de la personne, puis Renaissance et cours associés dans le catalogue. |
| `leonard de vinci` | Mêmes associations que la saisie accentuée. |
| Un motif décoratif | Notion, exemples visuels et périodes où ce motif est documenté. |

Une correspondance peut concerner plusieurs périodes. La recherche ne doit pas attribuer systématiquement une caractéristique à une seule époque et ne nécessite pas d'IA en ligne.

L'interface complète de recherche est une évolution ultérieure, mais les relations et alias doivent être prévus dès les premiers contenus.

### 3.4. Références et vidéos

- **MED-01 — Sources** : associer aux cours et aux fiches des références identifiables : titre, organisme ou auteur, lien et contexte d'utilisation.
- **MED-02 — Ouverture externe** : ouvrir les références dans le navigateur après une action explicite.
- **MED-03 — Indication Internet** : afficher qu'une référence nécessite Internet ; son indisponibilité ne bloque jamais le cours.
- **MED-04 — Vidéos intégrées** : lire une vidéo directement dans le cours à partir d'un fichier livré avec l'application.
- **MED-05 — Commandes vidéo** : lecture, pause, reprise, volume, déplacement dans la vidéo et affichage agrandi ou plein écran.
- **MED-06 — Sous-titres** : prévoir un média de sous-titres local et/ou une transcription associée dans le modèle ; le niveau de prise en charge initial reste à choisir.
- **MED-07 — Chargement à la demande** : ne charger la vidéo que lorsque le cours en a besoin ; arrêter sa lecture en quittant l'écran.
- **MED-08 — Média manquant** : expliquer l'indisponibilité du média et conserver l'accès au reste du cours.
- **MED-09 — Crédits des médias** : relier chaque image et vidéo à son auteur, sa provenance et ses informations de réutilisation.
- **MED-10 — Images lisibles** : conserver les proportions, adapter la taille au contenu et permettre zoom et défilement dans l’application ; privilégier une source en meilleure définition lorsqu’elle existe.
- **MED-11 — Preuves dans le cours** : justifier les techniques ou faits qui demandent une explication par des objets identifiés et des sources fiables. Les légendes décrivent le sujet ; la traçabilité vers les documents de préparation reste dans les métadonnées internes.
- **MED-12 — Reconnaissance des styles** : donner les caractéristiques concrètes du mobilier de chaque période et des exemples documentés ; employer uniquement des originaux de la période, des représentations d’époque ou des reproductions fidèles documentées, et signaler les restaurations. Les liens complémentaires portent le titre « Autres ressources ».

Un lecteur YouTube ou un lien de streaming ne satisfait pas MED-04 : la vidéo nécessaire au cours doit être disponible localement.

### 3.5. Espace Jeux

Chaque jeu comprend : choix du périmètre, consigne, session, correction, résultat et possibilité de recommencer. Il est accessible depuis le menu Jeux et, lorsque cela a un sens pédagogique, depuis un cours.

- **JEU-01 — Inspirations choisies ensemble** : pour tout jeu actuel ou futur, proposer et sélectionner avec Nathan de véritables jeux de référence. Documenter ce qui en est retenu : mécaniques, rythme, présentation, manipulation, animations et retours visuels. Ces références doivent orienter concrètement la conception pour obtenir un gameplay intéressant, une présentation soignée et des interactions fluides ; l'identité finale reste propre au projet.
- **JEU-02 — Expérience de jeu intégrée** : chaque jeu peut posséder sa propre ambiance, son plateau et son langage visuel, tout en restant dans l'application et accessible depuis sa navigation. Travailler la cohérence entre les écrans, les éléments jouables, les commandes et les animations ; vérifier le confort et le plaisir de jeu avec Nathan.

#### Quiz

- **QUI-01 — Quiz textuels** : proposer des questions à choix unique au premier stade.
- **QUI-02 — Quiz visuels** : poser une question à partir d'un meuble, d'une œuvre ou d'un détail illustré.
- **QUI-03 — Périmètre** : sélectionner une période ou un regroupement ; le quiz de fin de période réutilise le même moteur.
- **QUI-04 — Explication** : après la réponse, indiquer la correction et expliquer les indices à retenir, particulièrement en cas d'erreur.
- **QUI-05 — Retour au savoir** : proposer un lien vers le cours ou la notion qui permet de comprendre la réponse.
- **QUI-06 — Résultat** : afficher le nombre de bonnes réponses et les notions à retravailler.
- **QUI-07 — Nouvelle tentative** : permettre de rejouer sans écraser le meilleur résultat enregistré.

Les questions à réponses multiples ou à réponse libre sont des extensions possibles, pas une obligation de la première version. Aucune mécanique de chronomètre, de vies ou de pénalité n'est imposée à ce stade.

#### Timeline avec cartes

**Règle confirmée : le joueur pioche une carte à la fois et doit l'insérer au bon endroit parmi les cartes déjà placées sur le plateau, sans voir les dates.** Il choisit une position avant toutes les cartes, après toutes les cartes ou entre deux cartes voisines. Le moteur vérifie cet ordre à partir des dates réelles conservées dans les données.

- **TIM-01 — Pioche** : tirer une seule nouvelle carte par tour. Sa face visible présente une spécificité, une personne, un meuble, une œuvre ou un événement ; sa date réelle n'est pas affichée.
- **TIM-02 — Insertion** : placer la carte piochée dans l'un des espaces disponibles, avant, après ou entre les cartes déjà posées, par glisser-déposer ou par sélection puis clic.
- **TIM-03 — Dates cachées** : ne montrer les dates ni sur la carte piochée, ni sur les cartes du plateau, ni dans une graduation, une infobulle ou un autre indice de l'interface de jeu. Le plateau représente uniquement l'ordre chronologique ; les distances entre cartes ne représentent pas des durées.
- **TIM-04 — Vérification** : comparer la date réelle de la carte aux dates des cartes voisines de l'emplacement choisi. En cas d'erreur, expliquer la relation chronologique attendue, par exemple « cet objet se situe après cette œuvre et avant cet événement », sans afficher les dates dans le jeu.
- **TIM-05 — Tours successifs** : traiter la réponse puis permettre la prochaine pioche. Les cartes déjà validées conservent leur ordre ; le joueur positionne uniquement la carte du tour en cours, sans réorganiser librement tout le plateau.
- **TIM-06 — Chronologie nuancée** : prévoir les égalités et les datations approximatives ; accepter les emplacements équivalents historiquement justifiés ou écarter les cartes dont la datation est trop ambiguë pour cet exercice.

Déroulement d'un tour :

1. Le joueur pioche une carte.
2. Il observe son texte ou son illustration, sans date visible.
3. Il choisit un espace d'insertion sur le plateau existant.
4. Le moteur vérifie sa proposition avec les dates réelles.
5. Le jeu donne un retour pédagogique et traite l'issue du tour avant la pioche suivante.

Exemple d'interface :

```text
Pioche → [ Carte à positionner — date cachée ]

Plateau :
   +   [ Carte A ]   +   [ Carte B ]   +   [ Carte C ]   +
       avant A        entre A et B      entre B et C       après C
```

Les `+` représentent les quatre positions possibles autour de trois cartes. La préparation du plateau initial, la conséquence d'une erreur et la condition de fin de partie restent à décider ; elles ne changent pas la règle d'insertion avec dates cachées.

#### Frise à remplir

- **FRI-01 — Périodes** : choisir un regroupement (Antiquité), une période ou plusieurs périodes. La sélection inclut automatiquement toutes les périodes intermédiaires selon l’ordre pédagogique du catalogue ; choisir Égypte et Art nouveau inclura donc toutes celles ajoutées entre ces deux périodes. Les périodes peuvent se chevaucher.
- **FRI-02 — Bornes** : reprendre les dates de début et de fin indiquées dans les en-têtes des fiches de révision correspondantes, pour les périodes actuelles et futures. Commencer par une frise vide. Demander le début le plus ancien de la sélection, puis sa fin la plus tardive, avec cinq propositions pour chaque question. Une erreur permet de réessayer jusqu’à obtenir la bonne réponse ; aucune carte n’est distribuée avant les deux bonnes réponses. Les bornes des styles sont distinctes des dates historiques des événements : les cartes hors de leur intervalle de style sont exclues de la partie, sans modifier leur datation.
- **FRI-03 — Association** : afficher des emplacements vides portant leurs dates et des cartes décrivant les débuts et fins des périodes ou des événements précis, sans date visible sur la carte. Le joueur glisse chaque carte sur un emplacement. Une sélection puis un clic sur la date fournit aussi une interaction au clavier et à la souris.
- **FRI-04 — Main et pioche** : disposer la main en bas de l’écran, avec au maximum sept cartes. Après les bornes, distribuer uniquement les repères de période selon FRI-10, sans compléter la main avec des événements. Une fois tous ces repères validés, distribuer les événements jusqu’à sept cartes. Compléter ensuite automatiquement la main après chaque placement depuis la main ; une défausse pioche une remplaçante parmi les cartes autorisées dans la phase courante.
- **FRI-05 — Défausse recyclée** : la carte défaussée retourne dans la pioche, qui est remélangée ; aucun événement n’est éliminé. Piocher sa remplaçante avant de la remettre dans le paquet évite de recevoir immédiatement la même carte. Lorsque la pioche est vide, il n’y a plus de renouvellement possible par défausse.
- **FRI-06 — Déplacements et échanges** : autoriser les corrections avant validation. Une carte de la main posée sur une carte occupée rend la précédente à la main ; déplacer une carte du plateau sur une autre échange les deux. Reprendre une carte en main est possible s’il reste une place. Ces manipulations ne créent ni ne suppriment de carte.
- **FRI-07 — Validation finale** : le bouton Valider apparaît seulement lorsque toutes les cartes sont sur la frise et que les repères de période sont correctement placés. Marquer les bonnes associations en vert et les mauvaises en rouge, avec des symboles pour ne pas dépendre de la couleur seule. Les événements attendent cette validation finale ; les repères de période sont contrôlés immédiatement selon FRI-11.
- **FRI-08 — Correction et reprise** : afficher le nombre d’associations correctes et, au clic sur une carte, son repère attendu, son explication sourcée et un lien vers le cours associé. Pour une carte de début ou fin de période, ouvrir plutôt la fiche de révision correspondante dans le lecteur intégré hors ligne. Permettre une nouvelle tentative, qui recommence par les bornes. Conserver la partie lors des changements de rubrique pendant la session.
- **FRI-09 — Chronologie et lisibilité** : qualifier les dates approximatives, les intervalles, les dates traditionnelles et les bornes conventionnelles. Accepter les emplacements de dates équivalentes. Afficher les dates dans l’ordre avec un espacement de lecture non proportionnel aux durées, une frise défilante et un défilement au bord pendant le glisser-déposer.
- **FRI-10 — Phase initiale réservée aux périodes** : les premières cartes piochées sont les repères de début et de fin restant à placer parmi les périodes retenues, y compris les périodes intermédiaires ajoutées automatiquement. Produire les cartes à partir des bornes des fiches, avec les intitulés « Début de la période » et « Fin de la période », sans afficher leurs dates sur les faces. Exclure toute carte de période dont la date correspond à l’une des deux bornes extérieures déjà trouvées pour cette sélection, ainsi que son emplacement vide : le filtre dépend du preset de la partie, pas du nom de la période. Avec Grèce seule, début Grèce et fin Grèce sont donc exclus ; avec toute l’Antiquité, début Égypte et fin Rome sont exclus. Les périodes partageant une borne extérieure sont toutes concernées. Tant que tous les repères intérieurs ne sont pas correctement placés, aucune carte d’événement ne peut être distribuée, même avec moins de sept cartes en main. Si plus de sept repères sont nécessaires, les poses et défausses alimentent la main uniquement avec ces repères ; ceux encore jamais piochés gardent leur priorité après mélange. Dès que tous sont validés, la main est automatiquement complétée avec les événements. Sans repère intérieur, cette phase est sautée.
- **FRI-11 — Contrôle immédiat des périodes** : chaque pose ou échange recalcule la validité des repères de période concernés. Un bon repère colore sa date en vert, avec un symbole de confirmation. Un mauvais repère colore sa carte en rouge ; un petit bouton sur cette carte la renvoie dans la pioche remélangée et libère son emplacement. La carte renvoyée reste dans la pioche jusqu’à une nouvelle pioche ; un bouton « Piocher » est proposé si la main a de la place et qu’une carte autorisée est disponible, pour permettre de continuer même après avoir mal placé tous les repères. Un repère correctement placé se verrouille pour toute la partie, y compris lors de la seconde tentative.

**Évolutions de la frise**

- **FRI-12 — Choix après validation finale** : en présence d'erreurs, proposer deux actions distinctes. **« Voir les erreurs »** corrige automatiquement le placement des cartes incorrectes, conserve les bonnes cartes et distingue visuellement toutes les cartes déplacées par cette correction. Conserver le placement initial pour permettre de comparer ce que le joueur avait fait à la réponse exacte ; ne pas remplacer silencieusement son essai par la solution. **« Refaire uniquement les mauvaises »** conserve les bonnes cartes en place et permet de replacer seulement les mauvaises, sans refaire les questions de bornes ni révéler automatiquement leur solution. Permettre ensuite de valider cette nouvelle tentative. Le choix doit précéder toute correction automatique.
- **FRI-13 — Repères verrouillés et périodes en couleur** : dès qu'un repère de période est correctement placé, le verrouiller : il ne peut plus être déplacé, échangé, repris en main ni renvoyé en pioche. Attribuer un code couleur identifiable à chaque période et surligner son intervalle complet sur la frise. Lorsque des périodes se chevauchent, afficher leurs couleurs en bandes superposées verticalement, les unes au-dessus des autres, en conservant chaque couleur visible. Les noms ou une légende permettent d'associer les bandes aux périodes ; distinguer ces couleurs des états de réponse verte ou rouge.
- **FRI-14 — Taille du paquet.** Le réglage initial propose dix événements, dans les limites de la sélection. Le joueur peut modifier ce nombre ou choisir « Tous ».

  **Préparation du paquet.** L’écran présente le nombre d’événements disponibles. Si les périodes retenues offrent moins d’événements que le nombre demandé, afficher le nombre disponible. Avant la distribution, tirer ce nombre d’événements distincts parmi les cartes éligibles. Seuls ces événements et leurs emplacements datés entrent dans la partie. Les deux questions de bornes et les repères intérieurs suivent leurs règles habituelles. Le récapitulatif affiche le total à poser, par exemple « 10 événements + 8 repères = 18 cartes à poser », et présente séparément les deux questions de bornes. Les récompenses de collection portent sur les cartes rencontrées dans cette partie.
- **FRI-15 — Refonte visuelle en véritable jeu de cartes** : revoir presque entièrement l'apparence de la frise pour lui donner l'immersion d'un jeu à part entière, tout en la conservant intégrée à l'application. Les références choisies avec Nathan sont **TFT (Teamfight Tactics), Balatro et Hearthstone**. Travailler ensemble le plateau, la main, la pioche, les cartes, leurs contours et leur relief, les boutons, la typographie, les couleurs, les transitions, les animations et les retours de sélection, de réussite et d'erreur. Cette direction est validée, mais sa réalisation nécessite l'accord préalable avant de coder.

**Écran de préparation à refondre.** Donner au choix des périodes la même direction artistique que le plateau de Chroniques. Piste de maquette : présenter les périodes sous forme de cartes sélectionnables, reprendre leurs couleurs et réserver un emplacement au réglage du nombre d’événements. Le bouton de lancement récapitule le défi. Les périodes incluses automatiquement doivent être reconnaissables.

Construire le sélecteur à partir des grandes époques et des périodes du catalogue, avec un accès direct à chaque période. Déduire de la sélection courante les périodes intermédiaires, les bornes issues des fiches et le nombre de cartes disponibles. Ainsi, l’ajout d’une période contemporaine actualise aussi le sélecteur, le calcul du paquet et la collection. Les identifiants stables des cartes permettent de conserver les exemplaires normaux et dorés déjà acquis.

**Répartition des événements entre périodes.** Soit N le nombre d’événements à placer et P le nombre de périodes retenues ayant des événements jouables. Les repères de période sont comptés séparément. Viser deux événements distincts par période retenue. Lorsqu’une période ne contient qu’une seule carte, le minimum devient la somme des stocks de chaque période plafonnés à deux. Une carte commune à plusieurs périodes ne compte qu’une fois dans la répartition et dans le paquet.

1. Calculer la moyenne N/P. Réserver à chaque période 70 % de cette moyenne, arrondis à l’entier inférieur, avec un minimum de deux événements dans la limite du stock.
2. Répartir les places restantes une à une par tirage. Donner à chaque période un poids égal au nombre de places qu’il lui reste jusqu’à 130 % de la moyenne, arrondis à l’entier supérieur, ou jusqu’à épuisement de son stock.
3. Si toutes les périodes ont atteint leur plafond ou épuisé leur stock avant d’atteindre le total, attribuer la place suivante à une période encore disponible ayant le moins de cartes attribuées. Tirer au sort en cas d’égalité et poursuivre jusqu’à N.

Pour 30 événements sur trois périodes suffisamment fournies, chaque période reçoit de 7 à 13 cartes. Des répartitions comme 7/12/11, 9/10/11 ou 10/10/10 sont possibles. Avec seulement 5 événements disponibles dans la première période, 5/12/13 devient possible. Les seuils de 70 % et 130 % sont des valeurs à essayer en jeu.

**Cas à vérifier sur l’écran de préparation.** Pour une demande de 50 événements et des stocks de 5, 30 et 30 événements distincts, une répartition possible est 5/22/23. La première période apporte ses cinq cartes. Les deux autres absorbent le complément, quitte à dépasser le plafond d’équilibrage pour atteindre 50. Si les stocks sont de 5, 12 et 20, le maximum jouable est 37. Si le joueur avait réglé 50 avant de changer sa sélection, ramener le réglage à 37 et lui indiquer « 37 événements disponibles pour ces périodes » avant le lancement. Il peut jouer les 37 ou élargir sa sélection. Pour une période qui ne compte qu’un seul événement jouable, l’inclure discrètement et répartir le complément entre les autres périodes. Afficher le total global à poser. Le cas d’une période sans événement reste distinct. Le mode consacré aux seules bornes est indépendant de ce minimum.

**Modes jouables dans Godot**

- **Frise classique.** Le joueur associe les cartes aux emplacements datés préparés pour la partie. Il peut aussi déposer une carte dans la zone « Saisir une date » du plateau pour entrer son année.
- **Repères de périodes.** Le paquet contient exclusivement le début et la fin de chaque période choisie, bornes extérieures comprises. Les dates viennent des fiches de révision. Un clic sur une carte en main l’agrandit au centre. Le joueur saisit l’année et choisit « avant J.-C. » ou « après J.-C. », avec « après J.-C. » par défaut.
- **Frise libre.** L’axe commence sans cases de réponse prédéfinies. Déposer une carte sur l’axe lui attribue l’année indiquée au point de dépôt. Passer par la zone de saisie lui attribue l’année entrée. Dans les deux cas, la carte crée son emplacement à cette date. Ce mode distribue les événements choisis et utilise les bornes des fiches comme extrémités de l’axe. La déplacer ensuite actualise sa position et libère complètement l’ancien endroit. Si d’autres cartes occupent encore l’ancienne année, elles y restent. Vérifier qu’une carte déplacée plusieurs fois figure une seule fois sur la frise et ne laisse aucune case vide.

**Précisions validées pour la saisie des dates**

- En mode Repères, distribuer les cartes dès le début. Révéler chaque borne après une réponse correcte, puis afficher la bande de la période une fois ses deux bornes retrouvées.
- En frise libre, afficher l’année visée pendant le glissement. Après le dépôt, permettre de la modifier au clavier par un clic sur l’année. Corriger les événements à la validation finale.
- Pour une date exacte, accepter l’année de référence. Pour un intervalle, accepter chacune des années comprises entre ses deux bornes incluses. Pour une datation approximative, définir dans le catalogue la plage acceptée selon la source. Appliquer le même critère historique au clavier et par glissement. Le catalogue porte les années admises dans `accepted_from` et `accepted_to`. Quand la source ne donne qu’une année de référence, le jeu utilise cette année. Pour les éléments ioniques de Sardes, la notice locale du Met (252453) indique de 300 à 280 av. J.-C.

**Autocomplétion de la frise classique.** Suggérer les dates des emplacements de la partie à partir de la saisie et de l’ère choisie. Pour une même saisie, les suggestions sont identiques quelle que soit la carte en main. Une année comprise dans un intervalle du plateau permet de retrouver cet emplacement. Si aucune date ne correspond à la saisie confirmée, garder la carte ouverte et afficher « Aucune date correspondante sur cette frise. » Une date existante reçoit la carte selon les règles habituelles de placement et de correction.

Au bilan, le joueur peut marquer une carte **« À revoir »**. Une prochaine partie compatible peut reprendre une ou deux cartes marquées parmi les événements demandés.

**FRI-16 — Rareté des cartes Événement**

Le bandeau supérieur d’un **repère de période** garde la couleur de sa période. Sur une **carte Événement**, ce même bandeau affiche la couleur de sa rareté pour que la carte garde son époque à deviner. La palette s’inspire de Hearthstone et s’applique au bandeau existant.

| Rareté | Couleur | Critère de classement |
|---|---|---|
| Commune | Gris argenté | L’événement donne du contexte à la frise. |
| Rare | Bleu | C’est un exemple précis que le joueur devrait reconnaître, comme la fabrication de la chaise de Reniseneb. |
| Épique | Violet | C’est une référence à laquelle le cours revient pour expliquer un sujet, comme l’inauguration du Colisée. |
| Légendaire | Orange | C’est un événement phare du chapitre, emblématique dans la culture générale ou dans l’histoire de l’ameublement, comme le début de la réalisation de *La Joconde* pour la Renaissance. |

Attribuer une rareté fixe à **l’événement formulé sur chaque carte**. Pour choisir le rang, considérer sa notoriété culturelle, sa place dans les métiers de l’ameublement et le moment que le cours veut faire retenir. Pour le Parthénon, le **début de la construction est rare** et **l’achèvement est légendaire** : le monument abouti sert de référence pour étudier ses proportions, ses colonnes et son décor. Pour un autre chantier, le début pourrait porter le rang supérieur si l’introduction d’une technique constitue le fait marquant.

Le rang figure dans les données de l’événement et s’applique à chaque apparition de la carte, quels que soient les autres événements sélectionnés et la difficulté de la partie. Toutes les cartes du paquet restent à placer selon les règles de pioche habituelles.

| Référence visuelle validée pour la frise | Apport retenu |
|---|---|
| TFT (Teamfight Tactics) | Pour chaque question de borne, présenter les cinq propositions comme des cartes au centre de l'écran, avec contours et mise en valeur au survol ou à la sélection. Assombrir temporairement l'arrière-plan pour concentrer l'attention sur le choix. Choisir d'abord le début, puis la fin, avant de revenir au plateau ; conserver les nouvelles tentatives prévues par FRI-02. |
| Balatro | Travailler la présence de la main et de la pioche, la lisibilité des cartes et la fluidité de leur distribution et de leur manipulation. |
| Hearthstone | Travailler la présence du plateau, le relief des cartes, les animations et les effets de sélection ou de validation. |

Ces inspirations guident une direction graphique commune propre à Culture Artistique. Les sept écrans de la maquette locale `design/maquette-frise-v2` servent de référence au jeu Godot. Les dates proposées, la main et le bilan dépendent de la partie.

La différence avec Timeline est pédagogique : Timeline demande de piocher puis d’insérer successivement des cartes dans un ordre dont les dates restent cachées ; la frise à remplir demande d’associer une main de cartes sans date à des emplacements datés, après avoir retrouvé les bornes. Leurs règles de pioche et de validation sont indépendantes.

Première version locale : Égypte, Grèce et Rome. Le catalogue conserve vingt-quatre événements sourcés ; dix-neuf entrent dans les bornes des fiches (cinq égyptiens, sept grecs et sept romains). Quatre repères intérieurs de début et fin de période complètent le paquet pour toute l’Antiquité, soit vingt-trois cartes à placer, après exclusion des deux bornes déjà trouvées. Les bornes sont respectivement −4000 à −400, −1100 à −100 et −800 à 400. Le catalogue `app/content/games/chronology.json` contient périodes, ordre pédagogique, bornes, provenance de l’en-tête, choix, événements et sources. `tools/validate_chronology.py` compare les bornes aux PDF originaux et vérifie leur empreinte par rapport au catalogue des fiches. `ChronologyRepository` résout la sélection, filtre les événements et produit les repères intérieurs de période à partir des bornes du preset ; `FriezeSession` gère les bornes, la main, la priorité d’ouverture de pioche, les échanges et le résultat ; les composants de carte, de main et d’emplacement gèrent l’interaction Godot. L’ajout de périodes et d’événements se fait dans les données, sans créer une scène par période. La partie et son résultat sont conservés en mémoire pendant la session ; leur persistance après fermeture reste à ajouter.

### 3.6. Progression locale

**PRO-07 — Collection de cartes de Chroniques**

La collection recense les événements et les repères de période. Chaque carte possède deux finitions à collectionner, normale et dorée, dans l’esprit de Hearthstone. Les deux partagent le même événement ou repère. Ainsi, le début du chantier du Parthénon peut être **rare et doré** et son achèvement **légendaire et normal**. Le bandeau continue de porter l’information prévue par FRI-16. Les acquisitions sont enregistrées localement avec l’identifiant stable de la carte.

**Lots de normales.** Le premier bilan d’une partie terminée attribue automatiquement des normales inédites tirées au hasard parmi les cartes travaillées, même si le joueur a fait une erreur. De 1 à 5 cartes travaillées, le lot contient au maximum 1 normale, de 6 à 9 il en contient 2, de 10 à 14 il en contient 3 et de 15 à 19 il en contient 4. À partir de 20, chaque tranche de 5 ajoute une normale. Les deux questions extérieures du classique comptent. Chaque carte compte une fois. Si les découvertes possibles sont moins nombreuses, le joueur les reçoit toutes.

**Maîtrise.** Une normale possédée au début de la partie devient dorée à 7 marques. En classique, la première réponse correcte à une borne, la première pose correcte d’un repère ou un événement juste à la première validation rapporte 1 marque. En frise libre et en mode Repères, la réussite correspondante rapporte 2 marques. Une erreur conserve le solde. Le total est plafonné à 7. Les nouvelles normales commencent à zéro et pourront progresser à la partie suivante. Le bilan détaille les gains et peut être consulté de nouveau. Refaire les erreurs conserve les récompenses initiales.

**Anciennes collections.** Une dorée déjà acquise conserve sa finition et donne accès à sa normale. Pour une ancienne normale en cours de progression, chaque réussite enregistrée vaut une marque. Une carte encore cachée débute à zéro lors de son acquisition.

Pour que la collection soit complétable, chaque carte annoncée comme disponible doit avoir une occasion de jeu ou un autre moyen d’obtention indiqué. En particulier, les questions de bornes offrent une occasion d’obtenir les repères extérieurs qui sont exclus de la pioche. Le catalogue peut signaler séparément les cartes dont le contenu jouable est encore à venir.

- **PRO-01 — Lecture** : retrouver le chapitre et sa position pendant la session ; ne pas enregistrer de statut « lu ».
- **PRO-02 — Résultats** : conserver le meilleur résultat et les notions à retravailler pour les activités réalisées.
- **PRO-03 — Résultats distincts de la navigation** : changer de chapitre ne valide aucune connaissance et ne marque aucun contenu comme lu.
- **PRO-04 — Persistance** : retrouver sa progression après fermeture et relancement.
- **PRO-05 — Mise à jour** : conserver la progression lors d'une mise à jour des contenus grâce à des identifiants stables.
- **PRO-06 — Robustesse** : gérer un fichier de sauvegarde absent, ancien ou invalide sans faire planter l'application.

Une synchronisation entre ordinateurs et des comptes individuels en ligne ne sont pas prévus. Un export/import manuel de progression pourra être ajouté si nécessaire.

### 3.7. Crédits

- **CRE-01 — Accès principal** : ouvrir les crédits depuis le troisième bouton du menu.
- **CRE-02 — Projet** : présenter l'auteur, les contributeurs et la version de l'application.
- **CRE-03 — Ressources** : lister les crédits des images, vidéos, sons, polices et autres ressources utilisées.
- **CRE-04 — Moteur et composants** : inclure les mentions de Godot et des éventuels composants tiers.
- **CRE-05 — Local** : rendre les informations de crédits consultables sans connexion ; leurs liens externes restent facultatifs.

Les crédits et les références d'un cours utilisent les mêmes fiches de provenance pour éviter des listes contradictoires.

### 3.8. Administration et publication des contenus

- **ADM-01 — Édition réservée** : fournir à Nathan un outil séparé pour créer et modifier le catalogue officiel.
- **ADM-02 — Gestion structurée** : gérer regroupements, périodes, cours, personnes, notions, références, médias et exercices.
- **ADM-03 — Composition** : créer les cours par blocs de contenu et relier les exercices à leurs notions et périodes.
- **ADM-04 — Prévisualisation** : prévisualiser un cours et jouer un exercice avant publication.
- **ADM-05 — Validation** : détecter les références rompues, médias manquants et questions sans correction.
- **ADM-06 — Publication** : distinguer les brouillons des contenus publiés et produire un paquet utilisable hors ligne.
- **ADM-07 — Mise à jour** : distribuer un nouveau paquet de contenus ou une nouvelle version sans écraser les sauvegardes des invités.

La méthode initiale d'édition reste à décider : formulaires simples, éditeur visuel complet ou préparation structurée des fichiers. Le lecteur doit fonctionner indépendamment de ce choix.

Le contrôle porte sur la version officielle publiée : une personne possédant une copie locale conserve matériellement la maîtrise de ses fichiers. Un mot de passe embarqué ne doit pas être présenté comme une protection absolue contre leur modification.

### 3.9. Fiches de révision intégrées

- **FIC-01 — Accès** : ouvrir la rubrique depuis le bouton « Fiche » de la barre du haut.
- **FIC-02 — Périodes** : choisir une période dans une liste classée, avec recherche par nom et alias ; utiliser un sélecteur compact dans les petites fenêtres.
- **FIC-03 — Lecture locale** : consulter les pages directement dans le lecteur Godot, sans ouvrir de PDF dans un logiciel externe et sans connexion Internet.
- **FIC-04 — Commandes** : changer de page, agrandir/réduire la fiche, adapter sa largeur et faire défiler ses détails.
- **FIC-05 — Parcours** : passer à la fiche précédente ou suivante et conserver fiche/page/zoom lors d'un retour depuis le menu pendant la session.
- **FIC-06 — Sources** : conserver les PDF fournis dans `fiche_revision/`, leur provenance et leur mise en page. Les supports `documents_support_cours/` sont une source distincte pour les futurs cours.
- **FIC-07 — Préparation** : préparer les pages et un manifeste à l'avance, pour qu'un lecteur distribué n'ait besoin ni de Python, ni de Poppler, ni des PDF sources.

Première implémentation : 17 fiches, 34 pages rendues en WebP haute définition et référencées dans `app/content/revision_sheets.json`. Les pages sont affichées comme images à l'intérieur d'une interface Godot ; cette étape n'implémente pas la sélection du texte ni sa recomposition en blocs de cours. La reprise est conservée pendant la session, sans nouvelle sauvegarde personnelle sur disque.

## 4. Organisation des connaissances

### 4.1. Regroupements et périodes

« Antiquité » sera d'abord un **regroupement pédagogique** pointant vers Égypte antique, Grèce antique et Rome antique. Ce regroupement sert à naviguer et à choisir le périmètre des exercices.

Une **période** représente un sujet historique ou artistique doté de ses propres métadonnées : nom, alias, description, aire géographique et datations éventuelles. Les subdivisions pourront être ajoutées sans modifier les écrans de base.

Un regroupement n'est pas obligatoirement une période et un cours peut concerner plusieurs périodes. Il faut donc éviter un modèle rigide du type « un cours possède exactement une époque et un artiste exactement un style ».

### 4.2. Entités du catalogue

| Entité | Rôle et champs essentiels |
|---|---|
| Regroupement | `id`, titre, description, périodes membres, ordre pédagogique. |
| Période | `id`, titre, alias, description, régions, début/fin et précision de datation. |
| Cours | `id`, titre, résumé, périodes, domaines, ordre, objectifs, blocs, notions, références, statut. |
| Notion | `id`, terme, alias, définition, type (objet, motif, technique…), périodes et cours associés. |
| Personne | `id`, nom, variantes, présentation, périodes, notions, œuvres et cours associés. |
| Œuvre ou objet | `id`, titre, type, personnes associées si connues, périodes, datation, matériaux, médias et sources. |
| Repère chronologique | `id`, titre, date ou intervalle, degré de précision, périodes, notion/œuvre/personne associée, sources. |
| Média | `id`, type, chemin local, légende, texte alternatif, durée si pertinente, sous-titres/transcription, provenance. |
| Référence | `id`, titre, auteur/organisme, URL éventuelle, notice locale et informations de crédit. |
| Question | `id`, type, énoncé, choix/réponse, explication, médias, périodes, notions et cours de révision. |
| Carte de Timeline | `id`, libellé visible sans date, médias, repère chronologique associé, explication et liens de révision. La date réelle est obtenue depuis le repère pour la validation uniquement. |
| Exercice de frise | `id`, type, consigne, périmètre, repères/cartes/emplacements, règle de validation, explications. |

Les types de domaines proposés comprennent mobilier, architecture, peinture, sculpture, décor, matériaux et techniques. Cette liste est une donnée de catalogue, pas une succession de conditions dans l'interface.

### 4.3. Relations et réutilisation

```text
Regroupement → Périodes → Cours
                         ↕
              Notions / Personnes / Œuvres
                         ↕
                Repères chronologiques

Questions et exercices → mêmes identifiants de périodes et de notions
Cours et exercices    → mêmes médias et références
Recherche             → index construit depuis ce catalogue
Progression           → résultats liés aux identifiants de cours et d'exercices
```

Une seule fiche décrit une notion. Les cours et jeux y font référence par identifiant. Une carte de Timeline peut toutefois posséder un libellé pédagogique propre, sans recopier la notice historique complète.

Pour Timeline, séparer la face visible de la carte et ses données de correction. Le composant visuel reçoit uniquement le libellé, les médias et les informations autorisées pendant le jeu ; la session conserve l'accès au repère et à sa date réelle. Le texte et les illustrations des cartes doivent être relus pour ne pas révéler cette date.

Les identifiants sont stables et indépendants des titres affichés. Renommer « Rome antique » ne doit pas casser les exercices ou les sauvegardes.

### 4.4. Structure des cours par blocs

Prévoir des blocs typés plutôt qu'un grand texte contenant des commandes spéciales :

- `heading` : titre ou sous-titre ;
- `paragraph` : paragraphe mis en forme ;
- `image` : référence à un média et légende ;
- `furniture_example` : étude de mobilier avec statut, description, image, caractéristiques et source ;
- `column_example` : type de colonne, description courte, illustration individuelle et trois indices de reconnaissance ;
- `annotated_image` : image existante avec repères en lettres et définitions françaises ; cadrage normalisé facultatif et hauteur de lecture explicite ;
- `video` : référence à une vidéo locale ;
- `callout` : synthèse, définition ou point à retenir ;
- `internal_link` : lien vers une entité du catalogue ;
- `reference` : référence documentaire ;
- `source` : justification placée près d’une affirmation, avec titre, explication et lien de la preuve ;
- `exercise_link` : passage vers une activité avec son contexte.

Le lecteur Godot rend chaque type avec un composant dédié. Un nouveau cours n'exige pas une nouvelle scène ni du code spécifique à son époque.

Pour les deux blocs illustrés ci-dessus, `media` résout la notice commune. `region: [x, y, largeur, hauteur]` utilise des valeurs entre 0 et 1 dans l’image source. Les `markers` donnent un `label`, une `definition`, un `point` et éventuellement un `label_point`, relatifs à l’image affichée après cadrage. Le lecteur applique le cadrage et les repères ; le fichier source reste intact. Les repères restent associés au détail dans le zoom. Les dessins de référence postérieurs sont identifiés comme tels (`visual_role: reference_diagram`), avec auteur et licence, et ne sont pas présentés comme des originaux antiques.

### 4.5. Dates et validation historique

- Distinguer date précise, année approximative et intervalle.
- Associer les datations à leur contexte géographique lorsque nécessaire.
- Conserver la précision et la source ; ne pas transformer un intervalle en fausse date exacte.
- Centraliser le tri, l'affichage avant/après J.-C. et les conversions ; ne pas disperser les conventions de calendrier dans les jeux.
- Pour une éventuelle frise de consultation ou pour une frise à remplir à échelle temporelle, gérer zoom et intervalles longs sans rendre les périodes récentes illisibles. Timeline utilise un plateau ordonné sans échelle de durée ni dates visibles.
- Pour Timeline, associer chaque carte à un repère de datation documenté et explicite dans les données, puis vérifier son insertion entre ses voisins à partir des dates réelles. L'interface de jeu ne doit pas afficher ces valeurs.
- Prévoir plusieurs réponses acceptables lorsque des dates ou périodes se chevauchent ; retirer d'un exercice toute association trop ambiguë pour sa règle.

## 5. Architecture technique proposée

Cette section fixe une direction de travail. Les noms précis des classes pourront évoluer tant que les responsabilités restent séparées.

### 5.1. Principe de séparation

```text
Interface Godot : scènes et composants de présentation
                         ↓ actions / résultats
Services : navigation, cours, recherche, sessions de jeux, progression
                         ↓ données et règles
Modèles et validation : catalogue, datations, réponses acceptables
                         ↓ lecture / écriture
Dépôts : contenus locaux, médias, progression et paquets de mise à jour
```

Les scènes affichent les données et transmettent les actions. Elles ne lisent pas chacune leurs propres fichiers JSON et ne contiennent pas les règles historiques des quiz.

### 5.2. Responsabilités

| Élément | Responsabilité |
|---|---|
| `ContentRepository` | Charger le catalogue, résoudre un identifiant, fournir périodes, cours et relations. |
| `MediaRepository` | Résoudre les médias locaux et exposer leurs métadonnées, sans téléchargement automatique. |
| `RevisionRepository` | Charger le catalogue des fiches de révision, leurs métadonnées de période et les pages locales préparées. |
| `CourseService` | Construire le parcours d'une période ou d'un regroupement et préparer les blocs à afficher. |
| `SearchService` | Normaliser la requête, consulter l'index local et classer les résultats. |
| `QuizSession` | Choisir les questions, suivre une session et calculer son résultat. |
| `TimelineSession` | Gérer la pioche, la carte du tour, le plateau ordonné et les phases du tour ; vérifier chaque insertion avec les dates réelles des cartes voisines, sans les transmettre aux composants visuels. |
| `FriezeSession` | Gérer les bornes, la phase réservée aux périodes avec contrôle immédiat, puis la main de sept cartes, la pioche, les emplacements et la correction finale des événements, indépendamment de Timeline. |
| `ChronologyRepository` | Charger les périodes et événements sourcés, inclure les périodes intermédiaires et formater les repères chronologiques. |
| `ChronologyService` | Centraliser les dates, intervalles, affichages et règles temporelles communes. |
| `ProgressRepository` | Lire, valider et enregistrer la progression locale. |
| `NavigationService` | Gérer les écrans, l'historique et le contexte de période/cours/exercice. |
| `ContentValidator` | Vérifier le catalogue et les médias avant publication. |
| Outil administrateur | Éditer, prévisualiser et publier en utilisant les mêmes modèles et validations. |

L'interface communique par signaux et appels explicites à ces services. Limiter les singletons aux services réellement partagés, notamment la navigation et l'accès au catalogue ; ne pas rendre tous les écrans globaux.

### 5.3. Stockage local

Proposition initiale : catalogue en fichiers JSON structurés, avec un schéma versionné, puis conversion en modèles GDScript au chargement. Ce format permet de relire et versionner les données sans créer une scène Godot pour chaque cours.

Prévoir des fichiers séparés par catégorie et, si le volume le justifie, par entité. Éviter un unique fichier contenant tous les textes, médias, jeux et résultats personnels.

Les chemins des médias doivent être relatifs à un emplacement connu du paquet et passer par `MediaRepository`. Aucun chemin absolu du poste de développement ne doit être nécessaire chez un invité.

La progression utilise un fichier séparé, avec sa propre version de schéma. Le dépôt de progression choisit son emplacement : dossier utilisateur pour une installation classique, ou dossier `data/` voisin du programme pour un mode portable accessible en écriture. Le choix de mode reste configurable et ne modifie pas les écrans.

L'enregistrement doit éviter d'écraser une sauvegarde valide avec une écriture incomplète, et prévoir la migration des versions anciennes. Aucun besoin de Supabase, de base de données distante ou de serveur pour cette architecture.

### 5.4. Recherche locale

Construire un index à partir des titres, noms, alias, termes, descriptions et relations du catalogue publié. Un index simple en mémoire est suffisant comme point de départ ; une base spécialisée ne sera envisagée que si le volume l'exige.

Ordre de pertinence proposé : correspondance exacte sur un titre ou alias, correspondance sur une notion ou personne liée, puis correspondance dans le contenu textuel.

La normalisation doit traiter les accents, la casse et la ponctuation. Les variantes sémantiques ou orthographiques importantes sont renseignées comme alias. La tolérance générale aux fautes de frappe n'est pas garantie dans la première version.

### 5.5. Vidéos et ressources volumineuses

Prévoir un composant `VideoBlock` dédié. Le texte du cours référence un identifiant de média ; le composant n'a pas à connaître le chemin physique ni la méthode de distribution.

Le prototype utilise Godot 4.7.2. La documentation du lecteur intégré prévoit Ogg Theora (`.ogv`) ; le pipeline initial devra donc convertir et tester les vidéos dans un format effectivement pris en charge. Une autre solution de décodage restera isolée dans le composant vidéo si elle devient nécessaire.

Source technique : [documentation Godot sur la lecture vidéo](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html).

La cible de distribution est un paquet autonome, pas nécessairement un exécutable unique. Des vidéos nombreuses peuvent justifier un dossier de médias ou un paquet de contenus distinct, livré avec l'application. Un contrôle doit confirmer la présence de toutes les dépendances locales avant publication.

### 5.6. Publication et mises à jour

Le catalogue publié possède une version et un manifeste listant ses fichiers. Les brouillons et les fonctions d'édition ne sont pas distribués dans le lecteur invité.

L'outil administrateur produit un paquet validé. Une nouvelle version de l'application ou un import de paquet pourra mettre à jour le savoir, mais ne devra pas remplacer la progression personnelle.

Le format précis des paquets de mise à jour reste à décider. Le manifeste, les identifiants stables et la séparation contenu/progression sont nécessaires dès le départ.

## 6. Arborescence cible

Arborescence proposée, à créer progressivement. Le lecteur `app/` commence par le menu, la navigation et les crédits ; la maquette est dans `design/` et le prototype reste dans `test/`. Les ressources déjà embarquées par le lecteur sont sous `app/assets/` et leurs notices sous `app/content/`. Le reste de cette arborescence décrit la cible, pas un inventaire de fonctionnalités réalisées.

```text
Culture_Artistique/
├── ARCHITECTURE_ET_FEUILLE_DE_ROUTE.md
├── README.md
├── app/                          Application lecteur Godot
│   ├── project.godot
│   ├── scenes/
│   │   ├── main_menu/
│   │   ├── courses/
│   │   ├── games/
│   │   │   ├── quiz/
│   │   │   ├── timeline/
│   │   │   └── fill_timeline/
│   │   └── credits/
│   ├── components/               Composants visuels et blocs de cours
│   ├── domain/                   Modèles et règles de validation
│   ├── services/                 Cas d'usage, recherche et navigation
│   ├── repositories/             Accès au contenu, médias et progression
│   └── theme/                    Typographie, couleurs, espacements
├── content/                      Sources éditoriales du catalogue
│   ├── manifest.json
│   ├── groups/
│   ├── periods/
│   ├── courses/
│   ├── concepts/
│   ├── people/
│   ├── works/
│   ├── chronology/
│   ├── questions/
│   ├── exercises/
│   ├── references/
│   └── media/                    Notices des médias, pas leurs gros fichiers
├── media/                        Fichiers images, vidéos et sous-titres
├── authoring/                    Outil administrateur à développer
├── tools/                        Validation et préparation des paquets
├── tests/                        Tests de la future application
├── docs/                         Décisions, formats et procédures
├── builds/                       Livrables générés, exclus de Git
└── test/                         Prototype existant conservé comme référence
```

Le dossier `content/` source est préparé par l'outil de publication puis inclus dans les ressources distribuées au lecteur. Un programme exporté ne dépend pas des dossiers du dépôt de développement.

Le prototype `test/` conserve ses propres `tests/` et `builds/`. Ces noms ne doivent pas être confondus avec les dossiers futurs à la racine.

## 7. Règles pour garder un code simple

1. Une seule source de vérité pour les périodes, notions, références et médias.
2. Aucun écran codé spécialement pour Rome, l'Égypte ou un autre sujet.
3. Un seul moteur de quiz pour l'espace Jeux et les boutons de fin de période.
4. Les exercices déclarent leurs données ; les règles de correction restent dans les sessions de jeu. Timeline sépare l'état de pioche, le plateau et la datation réelle de la face visible des cartes.
5. Une scène ou un composant réutilisable par type de bloc de cours.
6. Des relations par identifiants stables, jamais par comparaison de titres affichés.
7. Un accès centralisé aux fichiers, aux chemins et aux sauvegardes.
8. Un état de session distinct de la progression enregistrée.
9. Des fonctions de normalisation et de chronologie communes, testables indépendamment de l'affichage.
10. Des composants chargés à la demande ; ne pas charger toutes les vidéos et images au lancement.
11. Aucun compte administrateur en ligne ni serveur nécessaire au fonctionnement du lecteur.
12. Ne pas intégrer les gros exécutables, caches, journaux ou sauvegardes personnelles aux commits du code source. La méthode de stockage/versionnement des vidéos devra être définie avant leur ajout massif au dépôt.

## 8. Étapes de réalisation

### Étape 0 — Prototype de faisabilité : réalisée

Le prototype conservé dans `test/` démontre la lecture de cours, le quiz visuel, le classement de cartes et la sauvegarde locale. Les tests précédents comprennent 18 vérifications fonctionnelles, 4 vérifications d'interaction et le lancement d'une distribution portable isolée.

Ce prototype ne comprend ni l'administration, ni les vidéos intégrées, ni la recherche complète, ni la frise historique détaillée.

### Étape 1 — Fondations et premier parcours

- [ ] Confirmer ce document et les décisions ouvertes qui bloquent l'implémentation.
- [ ] Créer l'application lecteur avec son menu Cours / Jeux / Crédits.
- [ ] Définir le schéma versionné, les identifiants et la validation du catalogue.
- [ ] Modéliser Antiquité comme regroupement avec Égypte, Grèce et Rome accessibles directement.
- [ ] Afficher un premier cours par blocs, avec illustration et référence externe.
- [ ] Définir les liens vers notions, personnes et périodes pour préparer la recherche.
- [ ] Mettre en place le dépôt de progression locale.

### Étape 2 — Parcours complet cours → quiz : cours d’Antiquité intégrés à `main`

- [x] Construire le moteur de quiz textuel et visuel (choix unique).
- [x] Relier la fin de période à son ensemble de questions : Égypte, Grèce, Rome, quatre questions chacune.
- [x] Ajouter les explications, les retours au chapitre utile et les résultats.
- [x] Vérifier la navigation aller-retour et la conservation de la lecture pendant la session.
- [x] Afficher les crédits des ressources réellement utilisées.

Les trois cours natifs intégrés à `main` comprennent huit chapitres pour l’Égypte, six pour la Grèce et sept pour Rome, 35 illustrations existantes, douze études de mobilier commentées et une sauvegarde locale des meilleurs scores, sans suivi des chapitres lus. Le texte est rédigé à partir des thèmes des supports et complété par des vérifications muséales ; les supports ne sont pas affichés comme pages de cours. Les futurs enrichissements restent à relire avec Nathan. Les vidéos et le jeu Timeline ne sont pas encore réalisés ; la première frise à remplir est détaillée à l’étape 4.

La sculpture égyptienne et les colonnes égyptiennes disposent de chapitres dédiés ; les ordres grecs sont développés et un chapitre de colonnes romaines est ajouté. Les trois quiz totalisent dix-sept questions. Le catalogue calcule ses compteurs ; le sommaire peut défiler pour conserver les commandes accessibles lorsque les parcours s’allongent. Les identifiants existants des chapitres et des questions sont conservés. Les exemples ajoutés suivent les mêmes règles de provenance, de fidélité et de lisibilité que le mobilier.

Les quatorze types de colonnes sont illustrés individuellement et les termes techniques essentiels sont situés sur des images légendées. Le catalogue déclare les types attendus par période ; le validateur impose une illustration et trois indices pour chacun. Les schémas de référence sont distincts des preuves photographiques d’originaux, et les limites des montages de musée restent signalées.

### Étape 3 — Vidéo hors ligne et distribution

- [ ] Préparer un média vidéo local représentatif et son crédit.
- [ ] Construire le lecteur intégré avec ses commandes.
- [ ] Vérifier le format, la lisibilité et la lecture sur la machine cible.
- [ ] Produire un paquet autonome complet, sans dépendance à un chemin du développeur.
- [ ] Vérifier l'installation ou l'extraction et l'utilisation sans Internet.

La vidéo est une fonctionnalité obligatoire de l'application prévue ; son positionnement à cette étape ne la rend pas facultative.

### Étape 4 — Jeux chronologiques

- [ ] Implémenter Timeline : une carte piochée par tour, puis insertion avant, après ou entre les cartes du plateau.
- [ ] Conserver les dates réelles pour la validation et vérifier qu'elles restent absentes de toute l'interface de Timeline.
- [ ] Gérer la succession des tours et la stabilité des cartes déjà validées.
- [x] Implémenter la frise à remplir comme jeu distinct : sélection, bornes, main de sept cartes, pioche automatique et défausse recyclée.
- [x] Pour la frise : explications, sources et liens vers les cours, reprise de session et nouvelle tentative.
- [x] Pour la frise : vérifier le glisser-déposer réel et la sélection par clic/clavier.
- [x] Pour la frise : tester les intervalles, approximations et dates équivalentes.
- [ ] Réaliser ces mêmes vérifications pour le futur jeu Timeline.
- [ ] Enregistrer les résultats de frise après fermeture de l’application.

### Étape 5 — Recherche et filtres avancés

- [ ] Construire l'index local depuis le catalogue existant.
- [ ] Ajouter la barre de recherche et les filtres combinables.
- [ ] Tester les requêtes par période, terme, objet, personne et caractéristique.
- [ ] Afficher les associations multiples et le motif de correspondance.

### Étape 6 — Administration et enrichissement

- [ ] Créer l'outil d'édition réservé à Nathan selon le mode choisi.
- [ ] Ajouter prévisualisation, brouillons, validation et publication.
- [ ] Compléter les cours et les exercices avec des contenus relus et sourcés.
- [ ] Intégrer progressivement les repères de l'autre chat, après relecture.
- [ ] Vérifier les mises à jour de contenu sans perte de progression.
- [ ] Finaliser les livrables Windows ; envisager les autres systèmes selon le besoin.

Cette étape désigne l'interface d'administration aboutie. Une méthode d'ajout de contenu structurée et reproductible est nécessaire dès l'étape 1.

### Prochaine reprise — priorités mises à jour le 22 novembre 2026

- [ ] Discuter de la navigation au bilan de la frise. « Quitter » permet de sortir du jeu une fois la partie terminée. « Voir la collection » quitte la frise et ouvre directement la collection.
- [ ] Prévoir un bouton « Quitter » accessible en permanence pendant la partie, dès le choix des bornes. Préciser ensemble la destination et le devenir d’une partie interrompue.

- [ ] Avant toute modification du code, demander confirmation explicite à Nathan et attendre son accord, conformément à sa consigne du 17 novembre 2026.
- [x] Intégrer FRI-12 et FRI-13 dans Godot avec le choix de correction, la seconde tentative, le verrouillage des repères et les bandes de périodes.
- [x] Intégrer les sept écrans de la maquette FRI-15 dans le parcours de la frise.
- [x] Intégrer les récompenses normales et dorées, le suivi local de la maîtrise et la sélection « À revoir ».
- [x] Collection · Le dos commun Marqueterie masque les cartes à découvrir, y compris au survol. La normale acquise révèle la carte. En partie, les cartes sont lisibles dès la pioche.
- [x] Finition dorée · Une normale qui atteint 7 marques passe en doré dans la collection, en main et sur la frise. Le bandeau garde sa couleur de rareté ou de période.
- [ ] Ajuster avec Nathan le rythme d’acquisition après essai.
- [x] Intégrer la préparation de Chroniques, le choix du mode, la taille du paquet et le tirage pondéré avec redistribution.
- [x] Attribuer les raretés du catalogue et distinguer le bandeau des événements de celui des repères de période.
- [x] Proposer dix événements par défaut et le choix du paquet complet (FRI-14).
- [ ] Enrichir les cours existants avec les nouvelles ressources que Nathan fournira : comparer les apports au contenu actuel, compléter les explications et les exemples, vérifier les sources et la lisibilité des illustrations.
- [ ] Préparer puis ajouter les cours du Moyen Âge et de la Renaissance à partir des ressources disponibles et à recevoir. Conserver des cours techniques et détaillés, la rubrique « Le Mobilier », les exemples authentiques sourcés et le fonctionnement hors ligne. Les fiches de révision restent centrées sur l'essentiel.

**Frise — décisions et piste restante :** le joueur choisit une carte, l'associe à un repère puis utilise le retour du jeu pour ajuster son raisonnement. La réussite doit donner envie de poursuivre ; une erreur doit permettre une correction compréhensible sans imposer de refaire tout le début de partie.

| Statut | Évolution | Effet recherché et critère d'essai |
|---|---|---|
| Implémenté dans Godot | FRI-12 : choisir entre voir la correction automatique et refaire seulement les mauvaises cartes. | Vérifier que le choix est proposé avant de montrer la solution ; que les bonnes cartes restent en place ; que la correction automatique identifie les cartes changées et permet de comparer l'essai initial à la solution ; que la nouvelle tentative ne révèle pas les réponses attendues. |
| Implémenté dans Godot | FRI-14 : partie courte en plus du paquet complet. | Réduire la longueur des premières parties. Mesurer la durée et recueillir le ressenti de Nathan avant de fixer le nombre définitif. |
| Implémenté dans Godot | FRI-13 : verrouiller les repères validés et surligner chaque période avec sa couleur ; empiler les bandes dans les zones de chevauchement. | Vérifier qu'un bon repère ne peut plus être déplacé, que chaque intervalle est identifiable et que toutes les couleurs des périodes simultanées restent visibles. |
| Implémenté dans Godot | FRI-15 : refonte visuelle inspirée de TFT, Balatro et Hearthstone. | Vérifier les choix de bornes au centre sur des cartes avec fond assombri, la cohérence du plateau et de la main, la lisibilité des états et la fluidité des manipulations ; recueillir le ressenti de Nathan sur l'immersion. |
| Proposition non validée | Faciliter le repérage sur les longues frises : vue d'ensemble et accès rapide à une zone ou à un emplacement libre. | Réduire les allers-retours de défilement ; vérifier qu'une carte peut être placée loin dans la frise sans perdre sa position. Les chevauchements entre périodes restent visibles. |

Le mode court reste à réaliser. Demander l'accord de Nathan avant de commencer à coder. La proposition de navigation reste à discuter. Les essais devront distinguer la compréhension des consignes, la difficulté historique et la gêne liée à l'interface ; le plaisir de jeu se jugera avec les retours de Nathan.

## 9. Critères de validation

| Parcours | Résultat à démontrer |
|---|---|
| Choisir Antiquité | L'utilisateur voit Égypte, Grèce et Rome et peut ouvrir leurs cours. |
| Choisir Rome directement | Il accède au même contenu, avec les mêmes identifiants et la même progression. |
| Filtrer les cours | Les résultats correspondent aux métadonnées et les filtres peuvent être retirés. |
| Rechercher un terme comme `sgabello` | Les associations renseignées dans le catalogue conduisent aux périodes et cours pertinents. |
| Rechercher `leonard de vinci` | La variante sans accent retrouve la personne et ses associations. |
| Ouvrir une vidéo sans Internet | La lecture intégrée, la pause, le déplacement et le volume fonctionnent depuis les fichiers livrés. |
| Ouvrir une référence externe | Le navigateur s'ouvre après le clic ; une absence de connexion ne casse pas l'application. |
| Finir les cours d'une période | Le bouton de quiz ouvre les questions correspondant au périmètre étudié. |
| Se tromper au quiz | La correction explique la réponse et donne accès au savoir utile. |
| Revenir au cours | La période et la position de lecture sont retrouvées. |
| Piocher dans Timeline | Une seule nouvelle carte est proposée pour le tour, sans date visible. |
| Insérer une carte dans Timeline | Le joueur peut choisir avant, après ou entre les cartes existantes, à la souris ou par sélection, sans changer l'ordre des cartes déjà validées. |
| Vérifier l'insertion | Le moteur utilise les dates réelles des cartes voisines et reconnaît les positions chronologiquement acceptables. |
| Corriger une erreur dans Timeline | L'explication indique les relations avant/après attendues sans révéler les dates dans l'interface du jeu. |
| Piocher à nouveau | Le jeu traite l'issue du tour avant de proposer une nouvelle carte ; aucune pioche supplémentaire n'est possible pendant un placement en cours. |
| Garder les dates cachées | Aucune date réelle n'apparaît sur la carte piochée, les cartes du plateau, les infobulles ou une graduation ; l'espacement ne révèle pas les écarts de durée. |
| Corriger une frise | La règle utilisée est explicite et les réponses historiquement acceptables sont reconnues. |
| Relancer l'application | Les résultats des exercices sont restaurés ; aucun statut de cours lu n’est proposé. |
| Mettre à jour le contenu | Les résultats personnels ne sont pas remplacés par le paquet publié. |
| Ouvrir les crédits | Les mentions essentielles sont accessibles hors ligne. |
| Utiliser une copie invitée | Les fonctions de consultation et de jeu sont disponibles sans outil d'édition du catalogue officiel. |
| Tester un livrable isolé | Il démarre sans Godot installé et sans accès au dépôt source. |

Les vérifications porteront d'abord sur les relations entre données, le filtrage, la correction, les sauvegardes et les parcours complets. Les captures ou tests sans affichage ne suffisent pas à valider la lecture vidéo et le confort d'utilisation : des essais sur l'application exportée sont nécessaires.

## 10. Décisions encore ouvertes

Ces points ne remettent pas en cause les fonctionnalités demandées ; ils précisent leur réalisation.

| Décision | Proposition initiale / question à trancher |
|---|---|
| Nom affiché | `Culture_Artistique` est le nom du dépôt. « Atelier des Époques » est seulement le nom du prototype pour l'instant. |
| Systèmes à distribuer | Windows en premier ; confirmer si les invités ont aussi besoin de macOS ou Linux. |
| Édition des cours | Choisir le niveau d'éditeur visuel et le format d'entrée utilisable par Nathan. |
| Périmètre pédagogique initial | Choisir la profondeur des cours de l'Antiquité à la Renaissance avant de les rédiger intégralement. |
| Autres critères de cours | Valider les premiers filtres affichés parmi domaine, région/civilisation et type de contenu. |
| Quiz | Définir le nombre de questions par session et le mode de présentation de la correction. |
| Validation des connaissances | Définir s'il existe un seuil de réussite ; ne pas bloquer l'accès aux cours par défaut. |
| Timeline | Définir le plateau initial, la conséquence d'une erreur et la condition de fin de partie. La pioche successive, l'insertion avant/après/entre et les dates cachées sont confirmées. |
| Frise à remplir | Règles validées le 17 novembre 2026 : bornes avec nouvelles tentatives, emplacements datés, main de sept cartes, pioche automatique et défausse remélangée. Étendre ensuite le catalogue d’événements aux nouvelles périodes. |
| Vidéos | Choisir les premiers contenus, leur qualité, leur taille et les sous-titres/transcriptions disponibles. |
| Progression | Choisir le mode de stockage par défaut et l'éventuel export/import manuel. |
| Mise à jour des contenus | Choisir entre nouvelle distribution complète et import de paquets. |
| Médias et Git | Définir le stockage des vidéos et ressources volumineuses avant de les versionner. |

## 11. Suivi du document

Pour chaque nouvelle fonctionnalité :

1. La rattacher à un identifiant existant ou ajouter un nouvel identifiant.
2. Décrire le parcours utilisateur et les données nécessaires.
3. Définir un critère de validation observable.
4. La placer dans une étape de réalisation.
5. Noter les décisions qui changent l'architecture et mettre à jour ce document.

Une fonctionnalité n'est marquée terminée qu'après vérification de son comportement dans le contexte prévu. Les hypothèses ou propositions restent identifiées comme telles tant qu'elles ne sont pas validées.

### Historique

| Date | Version | Modification |
|---|---|---|
| 15 novembre 2026 | 0.1 | Création du cadrage fonctionnel, du modèle de connaissances, de l'architecture et de la feuille de route. |
| 15 novembre 2026 | 0.2 | Précision des règles de Timeline : pioche carte par carte, insertion dans le plateau existant et validation par dates réelles non affichées. Adaptation du modèle, des services et des critères de validation. |
| 17 novembre 2026 | 0.12 | Règles validées et première version de la frise à remplir : sélection avec périodes intermédiaires, bornes à retrouver, main de sept cartes et pioche/défausse recyclée ; vingt-quatre événements sourcés et correction intégrée. |
| 17 novembre 2026 | 0.13 | Bornes des styles reprises des en-têtes des fiches de révision ; provenance PDF vérifiée et cartes hors intervalle exclues sans changement de datation. Dix-neuf événements jouables. |
| 17 novembre 2026 | 0.14 | Les premières cartes piochées sont les débuts et fins des périodes sélectionnées ; priorité conservée après défausse et renvoi vers la fiche intégrée dans la correction. |
| 17 novembre 2026 | 0.15 | Exclusion des cartes de période et emplacements correspondant aux deux bornes déjà trouvées, calculée pour chaque sélection. Quatre repères intérieurs pour toute l’Antiquité ; aucun pour une période seule. |
| 17 novembre 2026 | 0.16 | Phase initiale exclusivement réservée aux repères de période jusqu’à leur bon placement ; contrôle immédiat, date verte, carte rouge renvoyable dans la pioche et distribution automatique des événements une fois les repères validés. |
| 17 novembre 2026 | 0.17 | Prochaine reprise : réflexion sur le gameplay de la frise, enrichissement des cours avec les nouvelles ressources de Nathan et ajout du Moyen Âge et de la Renaissance. Pistes de gameplay consignées comme propositions à valider. |
| 17 novembre 2026 | 0.18 | Validation du choix entre correction automatique avec comparaison et nouvelle tentative limitée aux erreurs ; verrouillage des repères et bandes colorées superposées pour les périodes ; mode court validé mais reporté. Confirmation explicite à demander avant toute prochaine modification du code. Aucune de ces évolutions n'est encore implémentée. |
| 17 novembre 2026 | 0.19 | Direction visuelle de la frise validée autour de TFT, Balatro et Hearthstone, dont les choix de bornes sous forme de cartes centrales sur fond assombri. Consigne durable : choisir ensemble les jeux de référence pour chaque jeu et documenter leurs apports au gameplay, aux graphismes et à la fluidité. Documentation uniquement. |
| 18 novembre 2026 | 0.20 | Intégration des sept écrans de Chroniques dans Godot. Correction comparative et seconde tentative testées sur la frise de toute la période antique. |
| 19 novembre 2026 | 0.21 | Règle FRI-16 validée. Classement des événements par caractère emblématique et couleurs de rareté prévus pour la prochaine session. |
| 19 novembre 2026 | 0.22 | Ajout de la collection de cartes normales et dorées. Proposition de progression par découverte et réussites répétées, à valider. |
| 19 novembre 2026 | 0.23 | Précision de FRI-14 pour limiter la taille du paquet de chaque partie à mesure que le catalogue grandit. |
| 19 novembre 2026 | 0.24 | Refonte demandée pour l’écran de préparation et proposition de répartition variable des événements entre les périodes. |
| 19 novembre 2026 | 0.25 | Couverture progressive de toutes les périodes jusqu’aux environs de 2020, avec extension possible au-delà. Sélecteur, répartition des événements et collection alimentés par le catalogue. |
| 19 novembre 2026 | 0.26 | Exemples de répartition pour 50 événements et comportement prévu lorsque le stock total de la sélection devient insuffisant. |
| 19 novembre 2026 | 0.27 | Distinction entre frise classique, entraînement aux bornes et frise libre à emplacements créés par les cartes. Minimum de deux événements par période dans les parties avec événements, total à poser et cartes à revoir. |
| 19 novembre 2026 | 0.28 | Révélation des bornes, placement libre et critères de datation validés. Exception pour un stock d’une carte et autocomplétion classique proposées. |
| 19 novembre 2026 | 0.29 | Préparation, trois modes jouables, saisie des années, tirage ajustable, raretés et collection locale intégrés dans Godot. |
| 22 novembre 2026 | 0.30 | Intégration du dos Marqueterie et de la finition dorée commune à la collection et au plateau. Le dos `app/assets/frieze/marquetry.png` reprend le dessin central de la planche de trois propositions générée pour Chroniques et choisie par Nathan. |
| 22 novembre 2026 | 0.31 | Lots de normales selon la taille de partie et dorure à sept marques sur les cartes déjà possédées. |
