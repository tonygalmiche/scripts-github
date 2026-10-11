#!/usr/bin/env bash
#
# installation-modules-facturation-electronique.sh - Récupère avec clone-module.sh
# les modules OCA/Akretion nécessaires à la facturation électronique (Odoo 18.0),
# selon le cas d'installation souhaité.
#
# Les clones et les liens sont créés dans les dossiers définis dans config.sh.
#
# Usage :
#   installation-modules-facturation-electronique.sh <cas:1|2|3>
#     1 : génération d'une facture Factur-X/EN16931, sans envoi sur la PA
#     2 : cas 1 + envoi de la facture sur la PA
#     3 : cas 2 + réception des factures fournisseurs depuis la PA
#
set -euo pipefail

usage() {
    echo "Usage : $0 <cas:1|2|3>"
    echo "  1 : génération Factur-X/EN16931, sans envoi sur la PA"
    echo "  2 : cas 1 + envoi de la facture sur la PA"
    echo "  3 : cas 2 + réception des factures fournisseurs depuis la PA"
    exit 1
}

CAS="${1:-}"
case "$CAS" in
    1|2|3) ;;
    *) usage ;;
esac

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
CLONE_MODULE="${SCRIPT_DIR}/clone-module.sh"

# Modules au format <owner>/<repo>/<branche>/<module>
CAS1_MODULES=(
    akretion/fr-einvoicing/18.0/account_invoice_en16931
    akretion/fr-einvoicing/18.0/l10n_fr_account_invoice_en16931
    OCA/l10n-france/18.0/l10n_fr_siret
    OCA/l10n-france/18.0/l10n_fr_siret_account
    OCA/community-data-files/18.0/uom_unece
    OCA/community-data-files/18.0/account_payment_unece
    OCA/community-data-files/18.0/base_unece
    OCA/community-data-files/18.0/account_tax_unece
    OCA/intrastat-extrastat/18.0/intrastat_base
    OCA/server-tools/18.0/base_view_inheritance_extension
    OCA/account-payment/18.0/account_payment_method_base
)
CAS2_MODULES=(
    akretion/fr-einvoicing/18.0/l10n_fr_einvoicing
)
CAS3_MODULES=(
    akretion/fr-einvoicing/18.0/l10n_fr_einvoicing_import
    # PR #810 non mergée dans OCA/l10n-france : fork Akretion
    akretion/l10n-france/18-add-l10n_fr_account_invoice_import/l10n_fr_account_invoice_import
    OCA/edi/18.0/account_invoice_import
    OCA/edi/18.0/account_invoice_import_facturx
    OCA/edi/18.0/base_facturx
    OCA/edi/18.0/base_business_document_import
)

MODULES=("${CAS1_MODULES[@]}")
[ "$CAS" -ge 2 ] && MODULES+=("${CAS2_MODULES[@]}")
[ "$CAS" -ge 3 ] && MODULES+=("${CAS3_MODULES[@]}")

echo "== Cas d'installation ${CAS} : ${#MODULES[@]} module(s) =="

ERREURS=()
NOMS=()
for path in "${MODULES[@]}"; do
    IFS=/ read -r owner repo branch module <<< "$path"
    NOMS+=("$module")
    echo
    if ! "$CLONE_MODULE" "https://github.com/${owner}/${repo}/tree/${branch}/${module}"; then
        ERREURS+=("$module")
    fi
done

# Librairies Python demandées par les modules (external_dependencies de leur manifest)
source "${SCRIPT_DIR}/config.sh"
LIBS=$(python3 -I - "$ADDONS_DIR" "${NOMS[@]}" <<'EOF'
import ast, os, re, sys
addons_dir, libs = sys.argv[1], {}
for module in sys.argv[2:]:
    manifest = os.path.join(addons_dir, module, "__manifest__.py")
    if not os.path.isfile(manifest):
        continue
    with open(manifest) as f:
        python = ast.literal_eval(f.read()).get("external_dependencies", {}).get("python", [])
    for spec in python:
        nom = re.split(r"[<>=!~ ]", spec, maxsplit=1)[0]
        if len(spec) > len(libs.get(nom, "")):  # garde la version minimale si elle est précisée
            libs[nom] = spec
print(" ".join(f"'{spec}'" for spec in sorted(libs.values())))
EOF
)

echo
if [ ${#ERREURS[@]} -gt 0 ]; then
    echo "== Terminé avec ${#ERREURS[@]} erreur(s) : ${ERREURS[*]} =="
    exit 1
fi
echo "== Terminé =="
if [ -n "$LIBS" ]; then
    echo "- Installer ou mettre à jour les librairies Python dans l'environnement d'Odoo :"
    echo "  pip install --upgrade ${LIBS}"
fi
echo "- Mettre à jour la liste des applications dans Odoo, puis installer les modules"
