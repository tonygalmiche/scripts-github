# scripts-github

Scripts pour tester en local des modules Odoo publiés sur Github (OCA ou autre).

- `clone-module.sh <url>` : clone un dépôt à une branche donnée et crée un lien vers le module demandé.
  Exemple : `clone-module https://github.com/OCA/field-service/tree/18.0/fieldservice`
- `clone-pr.sh <url>` : clone une pull request et crée un lien vers chaque module qu'elle modifie.
  Exemple : `clone-pr https://github.com/OCA/reporting-engine/pull/1203`

Un seul clone par dépôt et par branche (ou par PR) ; relancer le script le met à jour
(refusé s'il contient des modifications locales).

## Installation

```bash
cp config.exemple.sh config.sh    # puis adapter DEPOTS_DIR et ADDONS_DIR
ln -s "$PWD/clone-module.sh" ~/.local/bin/clone-module
ln -s "$PWD/clone-pr.sh" ~/.local/bin/clone-pr
```

- `DEPOTS_DIR` : dossier des clones ;
- `ADDONS_DIR` : dossier des addons de la base de test (à mettre dans l'`addons_path`),
  où sont créés les liens (relatifs) vers les modules des clones.

`clone-pr.sh` utilise l'API Github : définir `GITHUB_TOKEN` évite la limite de l'API non authentifiée.
