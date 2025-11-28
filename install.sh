#!/bin/bash

echo "=========================================="
echo "      C-STAR INSTALLER - PRO EDITION"
echo "=========================================="
sleep 1

### 1) دریافت اطلاعات از کاربر
read -p "ادمین یوزرنیم: " ADMIN_USER
read -p "ادمین پسورد: " ADMIN_PASS
read -p "توکن ربات تلگرام (BOT TOKEN): " BOT_TOKEN
read -p "چت آیدی (CHAT ID): " CHAT_ID
read -p "پورت سرویس (مثال: 3000): " PORT
read -p "رمز JWT_SECRET (هرچیزی): " JWT_SECRET

### 2) نصب پکیج‌های لازم
apt update -y
apt install nginx git curl nodejs npm -y

### 3) کلون پروژه
rm -rf /opt/cstar
git clone https://github.com/MoriiStar/c-star.git /opt/cstar

### 4) ساخت فایل ENV
cat <<EOF > /opt/cstar/.env
PORT=$PORT
ADMIN_USER=$ADMIN_USER
ADMIN_PASS=$ADMIN_PASS
JWT_SECRET=$JWT_SECRET
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
DB_FILE=./server/database/main.db
EOF

echo "[OK] فایل ENV ساخته شد"

### 5) نصب Node Modules
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
