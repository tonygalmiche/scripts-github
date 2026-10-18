# Mise en place de la facturation électronique (Odoo 18.0)

Vérifié le 18/10/2026 (cas 1 : dépendances des modules, Debian 13).

## Odoo 18.0

Clone git plutôt que zip, pour mettre à jour avec `git pull` :

```bash
# Si Odoo est déjà installé depuis un zip, le mettre de côté
systemctl stop odoo
mv /opt/odoo18 /opt/odoo18.zip-$(date +%F)

git clone --branch 18.0 --single-branch --depth 1 https://github.com/odoo/odoo.git /opt/odoo18
chown -R odoo:odoo /opt/odoo18
systemctl start odoo
```

## Préparation

En root (`/opt` appartient à root) :

```bash
git clone https://github.com/tonygalmiche/scripts-github.git /opt/scripts-github
chown -R odoo:odoo /opt/scripts-github
```

Le reste en `odoo` : clones, liens et librairies Python lui appartiennent directement.

```bash
su odoo
# Valeurs par défaut : /opt/addons/OCA et /opt/addons/facturation-electronique
cp /opt/scripts-github/config.exemple.sh /opt/scripts-github/config.sh
mkdir -p /opt/addons/OCA /opt/addons/facturation-electronique
exit
```

Ajouter `ADDONS_DIR` à l'`addons_path` des seules bases qui facturent, par exemple :

```ini
addons_path = /opt/odoo18/addons,/opt/addons,/opt/addons/facturation-electronique
```

## Cas 1 : génération Factur-X, sans envoi sur la PA

```bash
su odoo
/opt/scripts-github/installation-modules-facturation-electronique.sh 1
# Dans ~/.local, lu par le service Odoo (User=odoo)
pip install --user --break-system-packages 'factur-x>=7.5' 'python-stdnum'
exit
```

Saxon Server, en root :

```bash
# Java 21 sous Debian 13 (openjdk-17 n'y existe plus)
apt install default-jre-headless
mkdir -p /opt/saxon-server && cd /opt/saxon-server
wget https://github.com/willemvlh/saxon-server/releases/download/v1.15/saxon-server-1.15.jar
adduser --system --group --no-create-home saxon-server
chown -R saxon-server:saxon-server /opt/saxon-server

cat > /etc/systemd/system/saxon-server.service <<'EOF'
[Unit]
Description=Saxon Server
After=network.target

[Service]
User=saxon-server
Group=saxon-server
WorkingDirectory=/opt/saxon-server
ExecStart=/usr/bin/java -jar /opt/saxon-server/saxon-server-1.15.jar --insecure
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now saxon-server
```

Pare-feu : le port 5000 de Saxon ne doit jamais être ouvert sur Internet :

```bash
apt install ufw
# Avant ufw enable, sinon coupure SSH
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
# Rien pour le port 5000 : bloqué par défaut
# Odoo sur une autre machine : ufw allow from <IP_Odoo> to any port 5000 proto tcp
ufw enable
ufw status verbose
```

Odoo :

```bash
systemctl restart odoo
```

- Applications > Mettre à jour la liste des applications, puis installer `l10n_fr_account_invoice_en16931` (installe le cas 1).
- Comptabilité > Configuration > Paramètres : URL Saxon Server si autre que celle par défaut.

## Cas 2 : cas 1 + envoi de la facture sur la PA

```bash
su odoo
/opt/scripts-github/installation-modules-facturation-electronique.sh 2
pip install --user --break-system-packages 'pyfrctc>=0.23'
exit
systemctl restart odoo
```

- Mettre à jour la liste des applications, puis installer `l10n_fr_einvoicing`.

## Cas 3 : cas 2 + réception des factures fournisseurs depuis la PA

```bash
su odoo
/opt/scripts-github/installation-modules-facturation-electronique.sh 3
exit
systemctl restart odoo
```

- Mettre à jour la liste des applications, puis installer `l10n_fr_einvoicing_import`
  (installe aussi `l10n_fr_account_invoice_import` et `account_invoice_import`).

## Mise à jour

```bash
su odoo
git -C /opt/odoo18 pull
git -C /opt/scripts-github pull
/opt/scripts-github/installation-modules-facturation-electronique.sh <cas>
```

Puis la commande `pip` affichée à la fin, `systemctl restart odoo` et mise à jour des modules dans Odoo.

## Vérifier les librairies vues par Odoo

```bash
su odoo -s /bin/bash -c "pip3 show factur-x pyfrctc" | grep -E "Name|Version|Location"
```
