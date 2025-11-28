#!/bin/bash

echo "====== C-STAR AUTO INSTALL ======"

SERVER_IP=$(curl -s ifconfig.me)
echo "Detected Server IP: $SERVER_IP"

read -p "Enter PORT (default 3000): " PORT
PORT=${PORT:-3000}

read -p "Enter ADMIN ID: " ADMIN_ID
read -p "Enter BOT TOKEN: " BOT_TOKEN
read -p "Enter CHAT ID: " CHAT_ID

echo ""
echo ">>> Installing system dependencies..."
apt update -y
apt install -y curl git nginx

echo ""
echo ">>> Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo ""
echo ">>> Installing PM2..."
npm install -g pm2

echo ""
echo ">>> Creating project folders..."
rm -rf /opt/cstar
mkdir -p /opt/cstar

echo ""
echo ">>> Downloading project from GitHub..."
git clone https://github.com/MoriiStar/c-star.git /opt/cstar

if [ ! -f /opt/cstar/server/app.js ]; then
    echo "❌ ERROR: project not cloned correctly!"
    exit 1
fi

echo ""
echo ">>> Creating .env..."
cat <<EOF > /opt/cstar/.env
PORT=$PORT
ADMIN_ID=$ADMIN_ID
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
EOF

echo ""
echo ">>> Installing project dependencies..."
cd /opt/cstar/server
npm install

echo ""
echo ">>> Starting PM2..."
pm2 stop cstar >/dev/null 2>&1
pm2 start app.js --name cstar
pm2 save
pm2 startup -u root --hp /root

echo ""
echo ">>> Configuring nginx..."
cp /opt/cstar/nginx.conf /etc/nginx/sites-available/cstar
ln -sf /etc/nginx/sites-available/cstar /etc/nginx/sites-enabled/cstar
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo ""
echo "=============================="
echo "🎉 INSTALLATION COMPLETE!"
echo "🌐 YOUR PROJECT IS LIVE AT:"
echo "👉 http://$SERVER_IP:$PORT"
echo "=============================="
