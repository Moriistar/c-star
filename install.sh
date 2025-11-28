#!/bin/bash

echo -e "\n====== C-STAR AUTO INSTALL ======\n"

#############################################
# Detect Server IP Address
#############################################
SERVER_IP=$(curl -s ifconfig.me)
echo -e "Detected Server IP: $SERVER_IP\n"

#############################################
# USER INPUTS
#############################################
read -p "Enter PORT (default 3000): " PORT
PORT=${PORT:-3000}

read -p "Enter ADMIN ID: " ADMIN_ID
read -p "Enter BOT TOKEN: " BOT_TOKEN
read -p "Enter CHAT ID: " CHAT_ID

#############################################
# INSTALL REQUIREMENTS
#############################################
echo -e "\n>>> Installing system dependencies...\n"

apt update -y
apt install -y curl git nginx

#############################################
# Install Node.js + npm
#############################################
echo -e "\n>>> Installing Node.js...\n"

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

#############################################
# Install PM2
#############################################
echo -e "\n>>> Installing PM2...\n"
npm install -g pm2

#############################################
# CREATE PROJECT DIRECTORY
#############################################
echo -e "\n>>> Creating project folders...\n"

mkdir -p /opt/cstar
rm -rf /opt/cstar/*

#############################################
# CLONE PROJECT
#############################################
echo -e "\n>>> Downloading project from GitHub...\n"

git clone https://github.com/MoriiStar/c-star /opt/cstar

if [ ! -d "/opt/cstar/server" ]; then
    echo "ERROR: Project not cloned correctly!"
    exit 1
fi

#############################################
# CREATE .env FILE
#############################################
echo -e "\n>>> Creating .env file...\n"

cat <<EOF >/opt/cstar/.env
PORT=$PORT
ADMIN_ID=$ADMIN_ID
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
DB_PATH=/opt/cstar/database/database.sqlite
EOF

#############################################
# INSTALL BACKEND DEPENDENCIES
#############################################
echo -e "\n>>> Installing Node.js dependencies...\n"

cd /opt/cstar/server
npm install

#############################################
# START PM2 SERVICE
#############################################
echo -e "\n>>> Starting PM2 service...\n"

pm2 start app.js --name cstar
pm2 save
pm2 startup -u root --hp /root >/dev/null

#############################################
# CONFIGURE NGINX
#############################################
echo -e "\n>>> Configuring nginx...\n"

cp /opt/cstar/nginx.conf /etc/nginx/sites-available/cstar

# Replace "API_PORT" in nginx.conf
sed -i "s|API_PORT|$PORT|g" /etc/nginx/sites-available/cstar

ln -sf /etc/nginx/sites-available/cstar /etc/nginx/sites-enabled/cstar

nginx -t && systemctl restart nginx

#############################################
# DONE
#############################################
echo -e "\n======================================"
echo -e " 🎉 INSTALLATION COMPLETE!"
echo -e " 🌍 YOUR PROJECT IS LIVE AT:"
echo -e " 👉 http://$SERVER_IP:$PORT"
echo -e "======================================\n"
