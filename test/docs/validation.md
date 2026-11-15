# Vérification du prototype — 15 novembre 2026

Environnement : Windows x86_64, Godot 4.7.2.stable.official.ed1daf0bf, renderer Compatibility / OpenGL 3.3, NVIDIA GTX 1060 6 Go.

## Résultats

- Tests fonctionnels `tests/run_tests.gd` : **18 vérifications réussies, 0 échec**, code de sortie 0.
- Entrées `tests/ui_input.gd` : **4 vérifications réussies, 0 échec**, code de sortie 0. Navigation, réponse au quiz, sélection puis placement d'une carte et glisser-déposer natif de Godot. Événements injectés dans Godot, pas d'automatisation des entrées Windows.
- Captures `tests/render_smoke.gd` : cours, quiz et frise rendus avec OpenGL et inspectés. La page de cours défile verticalement. Les commandes de la frise sont visibles dans le viewport de référence 1440 × 900.
- Export Windows : exécutable + paquet PCK, code de sortie 0, utilisant le binaire éditeur comme modèle personnalisé faute de modèles d'export optimisés installés.
- Exécutable livré lancé depuis `builds/windows`, sans argument de chemin vers le projet source : **code de sortie 0**. Le catalogue, les trois illustrations et l'écriture d'une sauvegarde locale ont été vérifiés par `-- --verify-build`.
- Archive ZIP extraite dans un dossier distinct, hors de l'arborescence du projet : les quatre fichiers distribués suffisent au même test, **code de sortie 0**, catalogue et sauvegarde locale disponibles. Archive : 87 707 580 octets, sans progression personnelle.
- Le code de l'application ne contient aucun client HTTP, socket ou chargement de ressource distante. Les seuls URL sont les références, ouvertes par le navigateur sur action explicite. La connexion système n'a pas été désactivée pendant ces tests.

## Limites et observations

L'outil de capture de fenêtre Windows a expiré ; la vérification visuelle utilise des captures du viewport produites par Godot. Les essais ne remplacent pas une validation manuelle de l'application sur d'autres ordinateurs.

Dans le contexte restreint d'exécution, Godot signale au démarrage qu'il ne peut pas lire le magasin de certificats système. Les commandes éditeur signalent aussi l'impossibilité d'enregistrer leurs préférences dans AppData. Ces messages proviennent du moteur dans cet environnement ; ils n'empêchent ni les tests, ni le rendu, ni l'export portable et ne sont pas des requêtes réseau de l'application. Un lancement hors du contexte restreint n'a pas produit ces messages dans son journal.

La progression de développement est stockée dans `.local/progress.json`. Les tests fonctionnels utilisent un autre fichier. La distribution conserve sa progression dans son propre dossier `data/` et l'archive initiale ne contient aucun résultat personnel.

L'éditeur administrateur, la vidéo, la frise historique complète, les exports macOS/Linux et la signature du paquet n'ont pas été implémentés ou testés.
