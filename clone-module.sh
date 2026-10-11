#!/usr/bin/env bash
#
# clone-module.sh - Clone un dépôt Github (OCA ou autre), à une branche donnée, dans
#                   le dossier des dépôts et crée dans le dossier des addons un lien
#                   vers le module demandé.
#
# Les deux dossiers sont définis dans config.sh, à côté de ce script.
#
# Installation (une fois) : lien dans ~/.local/bin, qui est dans le PATH
#   ln -s <dossier de ce dépôt>/clone-module.sh ~/.local/bin/clone-module
#
# Usage :
#   clone-module https://github.com/OCA/field-service/tree/18.0/fieldservice
#
# Résultat :
#   DEPOTS_DIR/field-service-18.0/   clone complet du dépôt, branche 18.0
#   ADDONS_DIR/fieldservice -> DEPOTS_DIR/field-service-18.0/fieldservice  (lien relatif)
#
# Un seul clone par dépôt et par branche, partagé par tous ses modules : s'il
# existe déjà, il est mis à jour (refusé s'il contient des modifications locales)
# et seul le lien est ajouté.
#
set -euo pipefail

URL="${1:-}"
if [ -z "$URL" ]; then
    echo "Usage : $0 <url_github_tree>"
    echo "Exemple : $0 https://github.com/OCA/field-service/tree/18.0/fieldservice"
    exit 1
fi

if ! [[ "$URL" =~ ^https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/([^/]+)/?$ ]]; then
    echo "URL invalide : $URL"
    echo "Format attendu : https://github.com/<owner>/<repo>/tree/<branche>/<module>"
    exit 1
fi

OWNER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"
BRANCH="${BASH_REMATCH[3]}"
MODULE="${BASH_REMATCH[4]}"

CONFIG="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/config.sh"
if [ ! -f "$CONFIG" ]; then
    echo "Fichier de configuration ${CONFIG} introuvable : copier config.exemple.sh en config.sh et l'adapter."
    exit 1
fi
source "$CONFIG"
for dir in "$DEPOTS_DIR" "$ADDONS_DIR"; do
    if [ ! -d "$dir" ]; then
        echo "Dossier ${dir} introuvable (voir ${CONFIG})."
        exit 1
    fi
done

CLONE_DIR="${DEPOTS_DIR}/${REPO}-${BRANCH}"

# Lance une commande sans rien afficher, sauf sa sortie en cas d'erreur
silencieux() {
    local sortie
    if ! sortie=$("$@" 2>&1); then
        echo "$sortie"
        return 1
    fi
}

if [ -d "$CLONE_DIR" ]; then
    echo "- ${OWNER}/${REPO} ${BRANCH} ${MODULE} : mise à jour du clone"
    if [ -n "$(git -C "$CLONE_DIR" status --porcelain)" ]; then
        echo "Le clone contient des modifications locales : mise à jour annulée."
        git -C "$CLONE_DIR" status --short
        exit 1
    fi
    silencieux git -C "$CLONE_DIR" fetch origin "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
    silencieux git -C "$CLONE_DIR" checkout "$BRANCH"
    silencieux git -C "$CLONE_DIR" merge --ff-only "origin/${BRANCH}"
else
    echo "- ${OWNER}/${REPO} ${BRANCH} ${MODULE} : clone"
    silencieux git clone --filter=blob:none --single-branch --branch "$BRANCH" \
        "https://github.com/${OWNER}/${REPO}.git" "$CLONE_DIR"
fi

if [ ! -f "${CLONE_DIR}/${MODULE}/__manifest__.py" ]; then
    echo "Module ${MODULE} introuvable dans ${OWNER}/${REPO} (branche ${BRANCH})."
    exit 1
fi

target=$(realpath --relative-to="$ADDONS_DIR" "${CLONE_DIR}/${MODULE}")
link="${ADDONS_DIR}/${MODULE}"
if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "${MODULE} existe déjà dans ${ADDONS_DIR} et n'est pas un lien : laissé tel quel."
    exit 1
fi
ln -sfn "$target" "$link"

echo "- Lien : ${link} -> ${target}"
