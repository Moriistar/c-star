#!/bin/bash

echo -e "\n====== C-STAR AUTO INSTALL ======\n"

read -p "Enter PORT (default 3000): " PORT
PORT=${PORT:-3000}

read -p "Enter ADMIN ID: " ADMIN_ID
read -p "Enter BOT TOKEN: " BOT_TOKEN
read -p "Enter CHAT ID: " CHAT_ID

echo "Creating directories..."
mkdir -p /opt/cstar
rm -rf /opt/cstar/*

echo "Downloading project..."
git clone https://github.com/MoriiStar/c-star /opt/cstar

echo "Creating .env..."
cat <<EOF >/opt/cstar/.env
PORT=$PORT
ADMIN_ID=$ADMIN_ID
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
DB_PATH=/opt/cstar/database/database.sqlite
EOF

echo "Installing dependencies..."
cd /opt/cstar/server
npm install

echo "Configuring PM2..."
npm install -g pm2
pm2 start /opt/cstar/server/app.js --name cstar
pm2 save
pm2 startup

echo "Configuring nginx..."
cp /opt/cstar/nginx.conf /etc/nginx/sites-available/cstar

# Auto Port Replace
sed -i "s|API_PORT|$PORT|g" /etc/nginx/sites-available/cstar

ln -sf /etc/nginx/sites-available/cstar /etc/nginx/sites-enabled/cstar

nginx -t && systemctl restart nginx

echo -e "\nDone! Visit: http://YOUR-IP/\n"### 5) نصب Node Modules
cd /opt/cstar
npm install

### 6) نصب PM2
npm install -g pm2

### 7) راه‌اندازی سرویس با PM2
pm2 stop all
pm2 start server/app.js --name cstar
pm2 save
pm2 startup

### 8) کپی فایل NGINX
cp /opt/cstar/nginx.conf /etc/nginx/sites-available/cstar
ln -sf /etc/nginx/sites-available/cstar /etc/nginx/sites-enabled/cstar

### 9) تست و ریستارت nginx
nginx -t
systemctl restart nginx

echo "=========================================="
echo "    نصب با موفقیت انجام شد!"
echo "------------------------------------------"
echo "   آدرس پنل: http://YOUR-IP/"
echo "=========================================="
