#!/bin/bash

echo -e "\n====== C-STAR FULL AUTO INSTALL ======\n"

###########################################
# 1) Detect Server IP
###########################################
SERVER_IP=$(curl -s ifconfig.me)
echo -e "Detected Server IP: $SERVER_IP\n"

###########################################
# 2) Ask user inputs
###########################################
read -p "Enter PORT (default 3000): " PORT
PORT=${PORT:-3000}

read -p "Enter ADMIN ID: " ADMIN_ID
read -p "Enter BOT TOKEN: " BOT_TOKEN
read -p "Enter CHAT ID: " CHAT_ID

###########################################
# 3) Install all required packages
###########################################
echo -e "\n>>> Installing dependencies...\n"

apt update -y
apt install -y curl git nginx

# Install Node.js (Latest LTS)
echo -e "\n>>> Installing Node.js...\n"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# Install pm2
npm install -g pm2

###########################################
# 4) Prepare directories
###########################################
echo -e "\n>>> Creating project directory...\n"

mkdir -p /opt/cstar
rm -rf /opt/cstar/*

###########################################
# 5) Download project
###########################################
echo -e "\n>>> Downloading C-STAR project from GitHub...\n"

git clone https://github.com/MoriiStar/c-star /opt/cstar

###########################################
# 6) Create .env file
###########################################
echo -e "\n>>> Creating .env file...\n"

cat <<EOF >/opt/cstar/.env
PORT=$PORT
ADMIN_ID=$ADMIN_ID
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
DB_PATH=/opt/cstar/database/database.sqlite
EOF

###########################################
# 7) Install backend dependencies
###########################################
echo -e "\n>>> Installing server dependencies...\n"

cd /opt/cstar/server
npm install

###########################################
# 8) Start PM2 Service
###########################################
echo -e "\n>>> Starting PM2 service...\n"

pm2 start app.js --name cstar
pm2 save
pm2 startup -u root --hp /root

###########################################
# 9) Configure nginx
###########################################
echo -e "\n>>> Configuring nginx...\n"

cp /opt/cstar/nginx.conf /etc/nginx/sites-available/cstar

sed -i "s|API_PORT|$PORT|g" /etc/nginx/sites-available/cstar

ln -sf /etc/nginx/sites-available/cstar /etc/nginx/sites-enabled/cstar

nginx -t && systemctl restart nginx

###########################################
# 10) Finish
###########################################
echo -e "\n======================================"
echo -e " 🎉 Installation Completed Successfully!"
echo -e " 🌐 Open your system at:"
echo -e " 👉 http://$SERVER_IP:$PORT"
echo -e "======================================\n"
