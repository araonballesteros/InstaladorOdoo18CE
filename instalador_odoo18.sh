#!/bin/bash
# Instalador de Odoo 18 Community Edition para entorno de desarrollo
# Autor: Script adaptado para ejemplo

set -e

# Variables de configuración
OE_USER="odoo18"
OE_HOME="/opt/$OE_USER"
OE_HOME_EXT="$OE_HOME/$OE_USER-server"
OE_VERSION="18.0"
OE_SUPERADMIN="clave_superadmin"
OE_CONFIG="$OE_USER-server"
SERVICE_FILE="/etc/systemd/system/$OE_CONFIG.service"

echo "----- Actualizando el sistema -----"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y locales

sudo dpkg-reconfigure locales
sudo locale-gen C.UTF-8
sudo /usr/sbin/update-locale LANG=C.UTF-8

echo 'LC_ALL=C.UTF-8' | sudo tee -a /etc/environment

# Comprobar versiones de Python y PostgreSQL
echo "Version de Python:" $(python3 --version)
echo "Version de PostgreSQL:" $(psql --version)

echo "----- Instalando PostgreSQL -----"
sudo apt-get install -y postgresql

PG_VERSION=$(psql --version | awk '{print $3}' | cut -d'.' -f1,2)
POSTGRES_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
if [ -f "$POSTGRES_CONF" ]; then
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRES_CONF"
fi
sudo su - postgres -c "createuser -s $OE_USER" || true
sudo systemctl restart postgresql

echo "----- Creando usuario del sistema -----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --group $OE_USER
sudo mkdir -p /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

echo "----- Instalando dependencias básicas -----"
sudo apt-get install -y git wget python3 python3-pip python3-venv python3-dev build-essential \
    libxslt-dev libzip-dev libldap2-dev libsasl2-dev libjpeg-dev libpq-dev \
    node-less npm poppler-utils xfonts-75dpi xfonts-base

echo "----- Instalando wkhtmltopdf -----"
wget -q https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.6/wkhtmltox_0.12.6-1.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6-1.jammy_amd64.deb || sudo apt-get -f install -y
sudo dpkg -i wkhtmltox_0.12.6-1.jammy_amd64.deb
rm wkhtmltox_0.12.6-1.jammy_amd64.deb

echo "----- Descargando el código de Odoo -----"
sudo mkdir -p $OE_HOME
sudo chown $OE_USER:$OE_USER $OE_HOME
sudo -u $OE_USER git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT
sudo -u $OE_USER mkdir -p $OE_HOME/custom/addons

echo "----- Instalando dependencias de Python -----"
sudo pip3 install -r $OE_HOME_EXT/requirements.txt
sudo pip3 install pypdf2

echo "----- Configurando Odoo -----"
sudo cp $OE_HOME_EXT/debian/odoo.conf /etc/$OE_CONFIG.conf
sudo chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_CONFIG.conf
sudo sed -i '/db_user/d' /etc/$OE_CONFIG.conf
sudo sed -i '/admin_passwd/d' /etc/$OE_CONFIG.conf
sudo sed -i '/addons_path/d' /etc/$OE_CONFIG.conf

echo "db_user = $OE_USER" | sudo tee -a /etc/$OE_CONFIG.conf
echo "admin_passwd = $OE_SUPERADMIN" | sudo tee -a /etc/$OE_CONFIG.conf
echo "logfile = /var/log/$OE_USER/$OE_CONFIG.log" | sudo tee -a /etc/$OE_CONFIG.conf
echo "addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons" | sudo tee -a /etc/$OE_CONFIG.conf

sudo tee $SERVICE_FILE > /dev/null <<EOS
[Unit]
Description=Odoo18
Requires=postgresql.service
After=postgresql.service

[Service]
Type=simple
User=$OE_USER
Group=$OE_USER
ExecStart=/usr/bin/python3 $OE_HOME_EXT/odoo-bin -c /etc/$OE_CONFIG.conf

[Install]
WantedBy=multi-user.target
EOS

sudo systemctl daemon-reload
sudo systemctl enable $OE_CONFIG.service
sudo systemctl start $OE_CONFIG.service

echo "----- Instalación completada -----"
