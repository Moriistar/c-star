#!/bin/bash

echo "====== C-STAR PRO AUTO INSTALLATION (HTTPS + DOMAIN) ======"

########################################
# 1) GET SERVER PUBLIC IPv4
########################################
SERVER_IP=$(curl -4 -s ifconfig.me)
echo "Detected Server IPv4: $SERVER_IP"

########################################
# 2) ASK USER INPUTS
########################################
echo ""
read -p "Enter your DOMAIN (example: pay.example.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ ERROR: Domain cannot be empty!"
    exit 1
fi

read -p "Enter your Admin ID: " ADMIN_ID
read -p "Enter Bot Token: " BOT_TOKEN
read -p "Enter Telegram Chat ID: " CHAT_ID

read -p "Enter Email for SSL certificate (required): " EMAIL
EMAIL=${EMAIL:-admin@$DOMAIN}

PORT=3000   # internal API port

########################################
# 3) INSTALL SYSTEM DEPENDENCIES
########################################
echo ""
echo ">>> Installing system dependencies..."
apt update -y
apt install -y curl git nginx software-properties-common

########################################
# 4) INSTALL NODEJS + PM2
########################################
echo ""
echo ">>> Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

echo ">>> Installing PM2..."
npm install -g pm2

########################################
# 5) PREPARE PROJECT FOLDER
########################################
echo ""
echo ">>> Preparing project files..."
rm -rf /opt/cstar
mkdir -p /opt/cstar

echo ">>> Downloading project..."
git clone https://github.com/MoriiStar/c-star.git /opt/cstar

if [ ! -f /opt/cstar/server/app.js ]; then
    echo "❌ ERROR: Project clone failed!"
    exit 1
fi

########################################
# 6) CREATE ENV FILE
########################################
echo ""
echo ">>> Creating .env file..."

cat <<EOF >/opt/cstar/.env
PORT=$PORT
ADMIN_ID=$ADMIN_ID
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
DOMAIN=$DOMAIN
EOF

########################################
# 7) INSTALL BACKEND DEPENDENCIES
########################################
echo ""
echo ">>> Installing backend dependencies..."
cd /opt/cstar/server
npm install

########################################
# 8) START BACKEND WITH PM2
########################################
echo ""
echo ">>> Starting backend service..."
pm2 stop cstar 2>/dev/null
pm2 start app.js --name cstar
pm2 save
pm2 startup -u root --hp /root >/dev/null

########################################
# 9) CONFIGURE NGINX (HTTP)
########################################
echo ""
echo ">>> Configuring nginx..."

cat <<EOF >/etc/nginx/sites-available/cstar
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/cstar /etc/nginx/sites-enabled/cstar
nginx -t && systemctl restart nginx

########################################
# 10) INSTALL SSL CERTBOT
########################################
echo ""
echo ">>> Installing Certbot (Let's Encrypt SSL)..."
apt install -y certbot python3-certbot-nginx

echo ""
echo ">>> Generating SSL certificate..."

certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"

########################################
# 11) FORCE HTTPS REDIRECT
########################################
echo ""
echo ">>> Enabling HTTPS redirect..."

cat <<EOF >/etc/nginx/sites-available/cstar
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

nginx -t && systemctl restart nginx

########################################
# 12) DONE
########################################
echo ""
echo "======================================"
echo " 🎉 INSTALLATION COMPLETE!"
echo " 🌍 YOUR PANEL IS LIVE AT:"
echo " 👉 https://$DOMAIN"
echo "======================================"
