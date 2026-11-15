"""Extract selected existing illustrations from the three Antiquity supports.

The original PDFs remain untouched. No historical object is redrawn.
Requires pypdf and Pillow on the development machine only.
"""
from pathlib import Path
import csv
import hashlib
import json
import logging
import sys

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
# id, support, PDF page (1-based), image index, title, caption, alternative text
ASSETS = [
    ("egypte-nil", "egypte", 2, 0, "Vallée du Nil", "Carte de la vallée du Nil extraite du support. Haute-Égypte en amont, Basse-Égypte dans le delta.", "Carte montrant le Nil, le delta au nord et la Nubie au sud."),
    ("egypte-temple", "egypte", 8, 1, "Une salle à colonnes", "Photographie d'une salle à colonnes d'un temple égyptien, issue du support. Le site et l'auteur ne sont pas précisés dans cette page.", "Alignements de colonnes massives portant un plafond en pierre, avec des reliefs sur leurs surfaces."),
    ("egypte-colonnes", "egypte", 11, 0, "Des chapiteaux végétaux", "Planche existante du support comparant plusieurs colonnes égyptiennes. Les couleurs relèvent de cette illustration didactique.", "Cinq colonnes dessinées avec des chapiteaux inspirés du papyrus, du palmier et du lotus."),
    ("egypte-peinture", "egypte", 14, 1, "Lire une scène peinte", "Scène de musiciens reproduite dans le support : observer les profils, les gestes et la relation entre image et écriture. Attribution non précisée dans la page.", "Trois musiciens peints, accompagnés de signes hiéroglyphiques."),
    ("egypte-coffre", "egypte", 17, 0, "Un coffre polychrome", "Photographie d'un coffre à décor polychrome provenant du support ; attribution et datation non précisées. Observer le volume, les panneaux et les motifs.", "Coffre sur pieds, à couvercle bombé, décoré de bandes bleues, dorées et de figures."),
    ("egypte-siege", "egypte", 18, 1, "Observer un siège", "Photographie de siège extraite du support. Le cours étudie sa structure et ses pieds ; l'attribution n'est pas déduite de l'image seule.", "Chaise en bois, avec un dossier rectangulaire ajouré et quatre pieds terminés en pattes animales."),
    ("grece-vase", "grece", 6, 0, "Un vase à figures noires", "Photographie de vase reproduite dans le support. Identification et datation non précisées ; observer la silhouette noire et les détails incisés.", "Vase grec à deux anses, avec des personnages noirs sur un fond orangé."),
    ("grece-ordres", "grece", 8, 0, "Comparer les trois ordres", "Schéma existant extrait du support : dorique, ionique et corinthien. Il présente des types de chapiteaux, pas trois édifices précis.", "Trois dessins de colonnes : chapiteau simple, volutes, puis feuillage d'acanthe."),
    ("grece-motifs", "grece", 9, 0, "Un répertoire de motifs", "Planche de motifs décoratifs du support : palmettes, ondes et frises répétées. Illustration documentaire, sans attribution précisée.", "Bandes verticales de motifs noirs et orangés, comprenant des palmettes et des ondes."),
    ("grece-klismos", "grece", 11, 0, "Le klismos et ses reprises", "Réinterprétation postérieure d'un klismos, photographiée dans le support. Ce siège n'est pas présenté comme un original grec antique.", "Chaise à pieds courbes, montants arrière inclinés et large dossier concave."),
    ("rome-colisee", "rome", 1, 0, "Le Colisée", "Photographie du Colisée de Rome extraite du support. Observer l'association des arcades et des ordres superposés.", "Vue extérieure du Colisée avec plusieurs niveaux d'arcades."),
    ("rome-mosaique", "rome", 4, 2, "Un décor en tesselles", "Détail de mosaïque reproduit dans le support. Provenance précise non indiquée ; observer les petites unités et leur assemblage en motifs.", "Mosaïque de tesselles formant une fleur dans un cadre géométrique."),
    ("rome-peinture", "rome", 4, 3, "Portrait et vie culturelle", "Portrait peint d'une femme tenant un stylet et des tablettes, reproduit dans le support. L'identité du modèle ne peut pas être affirmée à partir de ce document.", "Portrait féminin avec des tablettes dans une main et un stylet près de la bouche."),
    ("rome-aqueduc", "rome", 6, 1, "Le pont du Gard", "Photographie du pont du Gard extraite du support : les niveaux d'arcades portent le canal de l'aqueduc.", "Pont-aqueduc en pierre à trois niveaux d'arcades franchissant une rivière."),
    ("rome-curule", "rome", 7, 1, "Un siège à supports croisés", "Dessin documentaire existant du support, consacré à un siège de type curule et à ses supports. Il ne représente pas une pièce conservée identifiée.", "Dessin d'un siège sans dossier, avec des supports en X et des détails de son piètement."),
]


def main():
    logging.getLogger("pypdf").setLevel(logging.ERROR)
    sources = {}
    for path in (ROOT / "documents_support_cours").glob("*.pdf"):
        if "Antiquit" in path.name:
            key = "egypte" if "Egypte" in path.name else ("grece" if "Grece" in path.name else "rome")
            sources[key] = path
    readers = {key: PdfReader(path) for key, path in sources.items()}
    destination = ROOT / "app/assets/courses/antiquity"
    destination.mkdir(parents=True, exist_ok=True)
    media = {}
    for asset_id, support, page, image_index, title, caption, alt in ASSETS:
        image = readers[support].pages[page - 1].images[image_index]
        bitmap = image.image.convert("RGB")
        original_size = bitmap.size
        bitmap.thumbnail((2200, 2200))
        output = destination / (asset_id + ".webp")
        bitmap.save(output, "WEBP", quality=95, method=4)
        media[asset_id] = {
            "path": "res://" + output.relative_to(ROOT / "app").as_posix(),
            "title": title, "caption": caption, "alt": alt,
            "source": sources[support].relative_to(ROOT).as_posix(),
            "source_page": page, "source_image_index": image_index,
            "original_image_name": image.name, "original_size": original_size,
            "source_image_sha256": hashlib.sha256(image.data).hexdigest(),
            "credit": f"Support fourni par Nathan · page {page} · crédits d'origine conservés lorsqu'ils figurent dans l'image.",
            "rights": "Droits d'origine ; aucune nouvelle licence attribuée.",
            "modifications": "Image extraite du PDF, conversion WebP et réduction proportionnelle éventuelle ; aucun redessin."
        }
        print(asset_id, flush=True)
    (ROOT / "app/content/course_media.json").write_text(json.dumps(media, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with (ROOT / "docs/course-asset-register.csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["asset_id", "file_path", "source", "pdf_page", "image_index", "credit", "rights", "modifications"])
        for key, item in media.items():
            writer.writerow([key, item["path"], item["source"], item["source_page"], item["source_image_index"], item["credit"], item["rights"], item["modifications"]])
    print(f"{len(media)} illustrations existantes préparées.")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
