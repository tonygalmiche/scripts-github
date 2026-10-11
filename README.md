# scripts-github

Scripts pour installer facilement des modules Odoo publiés sur Github (OCA ou autre),
sur un serveur client comme sur un poste de développement (test d'un module ou d'une PR).

Un seul clone par dépôt et par branche (ou par PR) ; relancer un script le met à jour
(refusé s'il contient des modifications locales).

## Installation

```bash
cp config.exemple.sh config.sh    # puis adapter DEPOTS_DIR et ADDONS_DIR
ln -s "$PWD/clone-module.sh" ~/.local/bin/clone-module
ln -s "$PWD/clone-pr.sh" ~/.local/bin/clone-pr
```

Sur un serveur, les liens peuvent aussi être créés dans `/usr/local/bin`.

- `DEPOTS_DIR` : dossier des clones ;
- `ADDONS_DIR` : dossier d'addons d'Odoo (à mettre dans l'`addons_path`),
  où sont créés les liens (relatifs) vers les modules des clones.

## clone-module.sh

Clone un dépôt à une branche donnée et crée un lien vers le module demandé.

```bash
clone-module https://github.com/OCA/edi/tree/18.0/base_facturx
```

Résultat : le clone `DEPOTS_DIR/edi-18.0/` et le lien `ADDONS_DIR/base_facturx -> DEPOTS_DIR/edi-18.0/base_facturx`.

## clone-pr.sh

Clone une pull request et crée un lien vers chaque module qu'elle modifie.

```bash
clone-pr https://github.com/OCA/reporting-engine/pull/1203
```

Résultat : le clone `DEPOTS_DIR/reporting-engine-pr1203/` (branche `pr-1203`) et un lien dans `ADDONS_DIR` par module modifié.

Utilise l'API Github : définir `GITHUB_TOKEN` évite la limite de l'API non authentifiée.

## installation-modules-facturation-electronique.sh

Récupère avec `clone-module.sh` les modules OCA/Akretion de la facturation électronique (Odoo 18.0),
selon le cas d'installation :

```bash
./installation-modules-facturation-electronique.sh <cas:1|2|3>
```

- `1` : génération Factur-X/EN16931, sans envoi sur la PA ;
- `2` : cas 1 + envoi de la facture sur la PA ;
- `3` : cas 2 + réception des factures fournisseurs depuis la PA.

Un module n'est pas encore dans une branche `18.0` : il est pris sur une branche d'un fork
Akretion, en attente de fusion dans OCA (une branche de PR peut encore changer, être
réécrite ou supprimée avant la fusion) :

| Module (cas) | Branche (PR OCA) |
|---|---|
| `l10n_fr_account_invoice_import` (cas 3) | `akretion/l10n-france` `18-add-l10n_fr_account_invoice_import` ([l10n-france#810](https://github.com/OCA/l10n-france/pull/810)) |

Une fois la PR fusionnée, remplacer la ligne du module dans le script par la branche `18.0` du dépôt OCA.

> **Avertissement sur le cas 3** : depuis le 10/10/2026, `l10n_fr_einvoicing_import`
> (`akretion/fr-einvoicing` 18.0) dépend de `l10n_fr_account_invoice_import`, qui n'existe
> que dans la PR [l10n-france#810](https://github.com/OCA/l10n-france/pull/810), non fusionnée.
> Le cas 3 repose donc sur du code en cours de développement. Les deux modules sont en
> `auto_install` : ils s'installent avec la dernière de leurs dépendances, mais pas lors
> de la mise à jour de la liste des applications.
> Ce module n'est utilisé que par le cas 3.
