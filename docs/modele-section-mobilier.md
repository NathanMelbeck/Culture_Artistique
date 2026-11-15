# Rubrique commune : Le Mobilier

Chaque période du catalogue possède une rubrique intitulée exactement **Le Mobilier**, identifiée par `section: "mobilier"`. Le champ `id` du chapitre reste stable : les liens des quiz ne dépendent pas de son titre. Les cours existants gardent donc leurs identifiants actuels, y compris `motifs-mobilier` pour la Grèce.

Cette rubrique couvre les métiers de l’ameublement : structure, menuiserie et ébénisterie, décor, tapisserie d’ameublement, garnitures, textiles et confection/couture selon les sources disponibles pour la période. Une matière ou une technique ne doit être attribuée à un objet que si elle est documentée. Les domaines peu conservés sont expliqués avec leurs limites plutôt que complétés par une restitution présentée comme certaine.

## Contenu à préparer pour une période

1. Types et usages : sièges, tables, lits, meubles de rangement, équipements et aménagements pertinents.
2. Caractéristiques de reconnaissance : silhouettes, proportions, piètements, dossiers, traverses, assemblages documentés, décors et matières.
3. Assises et parties souples : tressage, sanglage, rembourrage, coussins, étoffes, tentures, passementerie et coutures lorsqu’ils sont attestés. Distinguer un textile conservé, une représentation et une restauration.
4. Plusieurs exemples commentés, illustrés et sourcés : varier les types, les fonctions, les niveaux de richesse et les moments de la période. Le minimum de validation est de quatre études d’exemple, chacune avec au moins trois caractéristiques observables ; ce minimum ne constitue pas une limite au nombre d’exemples.
5. Comparaisons : éléments communs à plusieurs périodes, différences significatives et restaurations documentées. Les réinterprétations, adaptations et meubles de style fabriqués plus tard sont exclus comme exemples de la période étudiée.

Pour chaque exemple, donner le nom, la fonction, l’image lisible et zoomable, les caractéristiques à observer et une référence précise. Lorsque les informations sont connues, la légende indique date, matériaux, institution, inventaire et provenance. Les métadonnées conservent également l’URL de l’image, les droits, le crédit et les éventuelles modifications. Seuls les objets originaux de la période, leurs représentations d’époque et les reproductions fidèles documentées sont admis. Une représentation d’époque doit être légendée comme telle : elle n’est pas un meuble conservé. Un original restauré reste utilisable si la notice distingue les parties anciennes des compléments modernes.

## Authenticité des exemples, pour toutes les périodes

- **Original de la période** (`original`) : objet identifié par une notice, y compris un fragment ou un objet restauré dont les compléments sont explicités.
- **Représentation d’époque** (`period_representation`) : meuble figuré dans une peinture, un vase, une sculpture ou un document réalisé à l’époque étudiée. La légende précise la nature du témoignage.
- **Reproduction fidèle documentée** (`faithful_reproduction`) : copie dont le modèle original est identifié et dont la fidélité est attestée par une source. Mentionner son statut et ses limites.

Une ressemblance de silhouette, une mention « inspiré de », « néo- », « de style » ou le nom d’un modèle antique ne suffit jamais à rendre un objet admissible pour une autre période. Une chaise de 1825 réinterprétant le klismos ne doit donc pas illustrer le mobilier grec antique. La même règle vaut pour chaque style et chaque époque. Elle s’applique aux illustrations, exemples, questions et ressources de comparaison proposées aux élèves.

Pour les médias de mobilier, renseigner `historical_status` et `subject_periods` (identifiants des périodes réellement documentées). Pour une reproduction, ajouter `model_url`, `fidelity_url` et `fidelity_note`. Le validateur refuse les statuts de réinterprétation, les associations à une autre période et les reproductions sans ces justificatifs. La qualification et les sources doivent être vérifiées éditorialement : ces champs ne constituent pas une expertise automatique de l’image.

## Format réutilisable

La rubrique utilise les mêmes blocs que les autres cours. `furniture_example` ajoute une présentation commune : titre, statut, description, figure, caractéristiques et notice. Aucune scène propre à une époque n’est nécessaire.

```json
{
  "id": "mobilier",
  "section": "mobilier",
  "title": "Le Mobilier",
  "intro": "Présentation du mobilier de la période.",
  "blocks": [
    {
      "type": "furniture_example",
      "id": "identifiant-stable-de-lexemple",
      "title": "Nom de l’objet ou du type étudié",
      "status_label": "Meuble conservé",
      "description": "Usage, contexte et intérêt de cet exemple.",
      "media": "identifiant-du-media",
      "characteristics": [
        "Une caractéristique de forme ou de structure.",
        "Une caractéristique de décor ou de matière documentée.",
        "Une caractéristique d’assise, de garniture ou une autre particularité pertinente."
      ],
      "reference": {
        "title": "Institution — notice de l’objet",
        "text": "Ce que la source permet d’affirmer, avec les restaurations et les incertitudes utiles.",
        "url": "https://exemple.invalid/notice"
      }
    }
  ]
}
```

Cet extrait montre un seul bloc à adapter et à compléter jusqu’au minimum d’exemples. Les valeurs de démonstration doivent être remplacées par des objets et des sources vérifiés. Le lien de la référence doit correspondre à la provenance enregistrée pour l’image dans `app/content/course_media.json`.

Les pages d’un document de préparation peuvent être conservées dans `source_pages` lorsqu’elles existent ; elles ne sont pas affichées aux élèves. Les règles communes et les minimums sont déclarés dans `app/content/courses/catalogue.json`, sous `editorial_requirements.furniture_section`. Exécuter `python tools/validate_courses.py` avant d’intégrer un nouveau cours : une rubrique absente, mal nommée, insuffisamment illustrée ou sans caractéristiques et références complètes provoque une erreur.
