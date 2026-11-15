# Culture_Artistique — Architecture et feuille de route

Version : 0.2 — 15 novembre 2026

Statut : document de référence initial, à faire évoluer avec les décisions du projet.

Ce document décrit l'application à construire. Il ne signifie pas que les fonctionnalités sont déjà réalisées. Les demandes confirmées sont distinguées des propositions techniques et des décisions encore ouvertes.

## 1. Vision du projet

Créer une application de culture artistique permettant de comprendre les époques, de reconnaître leurs caractéristiques et de vérifier ses connaissances par des jeux. Le premier contexte pédagogique est le BMA ébénisterie : les cours relient histoire, arts, architecture, mobilier, décors, matériaux et techniques.

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
| Navigation | Trois boutons principaux : Cours, Jeux, Crédits. |
| Fin de période | Un bouton donne accès aux quiz portant sur la période étudiée. |
| Correction | Une mauvaise réponse reçoit une explication pédagogique. |
| Dépôt | Dépôt GitHub `NathanMelbeck/Culture_Artistique`, cloné à la racine du projet. |
| Prototype | Conservé dans `test/` comme référence ; ce dossier ne constitue pas l'architecture définitive. |

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
- **COU-09 — Lecture suivie** : enregistrer les cours lus et la dernière position de lecture.

Pour un regroupement comme Antiquité, un récapitulatif pourra conduire à un quiz couvrant ses périodes. Un cours consacré à Rome devra conduire en priorité aux questions pertinentes pour Rome.

Le plan de cours recommandé, adaptable selon les sujets, comprend :

1. Situation dans le temps et dans l'espace.
2. Contexte historique et culturel.
3. Caractéristiques artistiques.
4. Architecture, œuvres et personnes de référence.
5. Mobilier, matériaux et techniques.
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

Un lecteur YouTube ou un lien de streaming ne satisfait pas MED-04 : la vidéo nécessaire au cours doit être disponible localement.

### 3.5. Espace Jeux

Chaque jeu comprend : choix du périmètre, consigne, session, correction, résultat et possibilité de recommencer. Il est accessible depuis le menu Jeux et, lorsque cela a un sens pédagogique, depuis un cours.

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

- **FRI-01 — Frise incomplète** : afficher une frise déjà structurée avec des éléments manquants.
- **FRI-02 — Éléments possibles** : compléter des noms de périodes, dates, événements ou caractéristiques selon la consigne.
- **FRI-03 — Interaction** : commencer avec une banque de réponses à sélectionner ou déplacer ; la saisie libre reste une extension possible.
- **FRI-04 — Correction** : donner la solution attendue, son explication et un lien vers le contenu utile.
- **FRI-05 — Résultat et reprise** : afficher le résultat et permettre une nouvelle tentative.

La différence avec Timeline est pédagogique : Timeline demande de piocher puis d'insérer successivement des cartes dans un ordre chronologique dont les dates restent cachées ; la frise à remplir demande de compléter une structure existante. Les dates éventuellement affichées ou demandées dans ce second jeu suivent sa propre consigne.

### 3.6. Progression locale

- **PRO-01 — Lecture** : conserver les cours lus et le dernier cours consulté.
- **PRO-02 — Résultats** : conserver le meilleur résultat et les notions à retravailler pour les activités réalisées.
- **PRO-03 — Distinction** : ne pas confondre « cours lu » et « connaissances vérifiées par un exercice ».
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
- `video` : référence à une vidéo locale ;
- `callout` : synthèse, définition ou point à retenir ;
- `internal_link` : lien vers une entité du catalogue ;
- `reference` : référence documentaire ;
- `exercise_link` : passage vers une activité avec son contexte.

Le lecteur Godot rend chaque type avec un composant dédié. Un nouveau cours n'exige pas une nouvelle scène ni du code spécifique à son époque.

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
| `CourseService` | Construire le parcours d'une période ou d'un regroupement et préparer les blocs à afficher. |
| `SearchService` | Normaliser la requête, consulter l'index local et classer les résultats. |
| `QuizSession` | Choisir les questions, suivre une session et calculer son résultat. |
| `TimelineSession` | Gérer la pioche, la carte du tour, le plateau ordonné et les phases du tour ; vérifier chaque insertion avec les dates réelles des cartes voisines, sans les transmettre aux composants visuels. |
| `FillTimelineSession` | Gérer les emplacements manquants et la correction de la frise à remplir, indépendamment des règles de pioche de Timeline. |
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

Arborescence proposée, à créer progressivement. Seuls le document présent et le prototype `test/` existent à ce stade ; cette liste n'est pas un inventaire de fichiers déjà implémentés.

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

### Étape 2 — Parcours complet cours → quiz

- [ ] Construire le moteur de quiz textuel et visuel.
- [ ] Relier la fin de période à son ensemble de questions.
- [ ] Ajouter les explications, les retours au cours et les résultats.
- [ ] Vérifier la navigation aller-retour et la conservation de la lecture.
- [ ] Afficher les crédits des ressources réellement utilisées.

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
- [ ] Implémenter la frise à remplir comme jeu distinct.
- [ ] Prévoir les explications et les liens vers les contenus de révision.
- [ ] Vérifier les interactions à la souris et au clavier.
- [ ] Tester les intervalles, approximations et réponses multiples acceptables.

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
| Relancer l'application | Les résultats et cours lus sont restaurés. |
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
| Frise à remplir | Confirmer la forme des blancs et les éléments affichés ou demandés dans ce jeu distinct. |
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
