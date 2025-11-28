#!/bin/bash
set -e

echo "🔥 نصب C-STAR PRO ..."

# --------------------------
# 1) نصب پکیج‌های لازم
# --------------------------
apt update -y
apt install -y nginx git curl sqlite3

# نصب Node.js اگر وجود ندارد
if ! command -v node > /dev/null; then
    echo "📦 نصب NodeJS 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
fi

# --------------------------
# 2) کلون پروژه
# --------------------------
echo "📥 دانلود پروژه در /opt/cstar ..."
rm -rf /opt/cstar
git clone https://github.com/MoriiStar/c-star /opt/cstar
cd /opt/cstar

# --------------------------
# 3) نصب وابستگی‌ها
# --------------------------
npm install

# --------------------------
# 4) ساخت دیتابیس
# --------------------------
echo "🗄 ایجاد دیتابیس..."
node server/database/init.js

# --------------------------
# 5) تنظیم nginx
# --------------------------
echo "⚙️ تنظیم nginx..."
rm -f /etc/nginx/sites-enabled/default
cp nginx.conf /etc/nginx/sites-available/cstar
ln -sf /etc/nginx/sites-available/cstar /etc/nginx/sites-enabled/cstar
systemctl restart nginx

# --------------------------
# 6) اجرای pm2
# --------------------------
npm install -g pm2
pm2 stop cstar 2>/dev/null || true
pm2 start server/app.js --name cstar
pm2 save

echo "✅ نصب کامل شد!"
echo "🌍 آدرس سایت: http://YOUR-IP/"
