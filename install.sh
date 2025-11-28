#!/usr/bin/env bash
set -e

### ============================
###  C-STAR ONE-SHOT INSTALLER
### ============================

REPO_URL="https://github.com/MoriiStar/c-star.git"
APP_NAME="cstar"
APP_DIR="/opt/cstar"
SERVER_DIR="$APP_DIR/server"
ENV_FILE="$SERVER_DIR/.env"
NGINX_SITE="/etc/nginx/sites-available/$APP_NAME"

# ---------- رنگ‌ها ----------
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

log()   { echo -e "${BLUE}>>>${RESET} $1"; }
info()  { echo -e "${YELLOW}[*]${RESET} $1"; }
ok()    { echo -e "${GREEN}[OK]${RESET} $1"; }
err()   { echo -e "${RED}[ERR]${RESET} $1" >&2; }

# ---------- دریافت IPv4 ----------
get_ipv4() {
  hostname -I 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\./){print $i; exit}}' ||
  curl -4s https://api.ipify.org 2>/dev/null || echo "YOUR-IP"
}

clear
echo "====== C-STAR AUTO INSTALL ======"

SERVER_IP=$(get_ipv4)
echo -e "${YELLOW}Detected IPv4:${RESET} $SERVER_IP"

# ---------- ورودی‌ها ----------
read -p "Enter PORT (default 3000): " APP_PORT
APP_PORT=${APP_PORT:-3000}

read -p "Enter ADMIN ID: " ADMIN_ID
read -p "Enter BOT TOKEN: " BOT_TOKEN
read -p "Enter CHAT ID: " CHAT_ID

read -p "Enter DOMAIN (leave empty for NO domain / HTTP only): " APP_DOMAIN
ENABLE_SSL=false
if [[ -n "$APP_DOMAIN" ]]; then
  read -p "Enable HTTPS/SSL for $APP_DOMAIN ? (y/N): " SSL_ANS
  [[ "$SSL_ANS" == "y" || "$SSL_ANS" == "Y" ]] && ENABLE_SSL=true
fi

echo
log "Installing system dependencies..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl git nginx ufw \
  software-properties-common

# ---------- Node.js ----------
if ! command -v node >/dev/null 2>&1; then
  log "Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
else
  ok "Node.js already installed: $(node -v)"
fi

# ---------- PM2 ----------
if ! command -v pm2 >/dev/null 2>&1; then
  log "Installing PM2..."
  npm install -g pm2
else
  ok "PM2 already installed"
fi

# ---------- پروژه ----------
log "Preparing project directory at $APP_DIR..."
if [[ -d "$APP_DIR" ]]; then
  info "$APP_DIR already exists. Removing old directory..."
  rm -rf "$APP_DIR"
fi
mkdir -p "$APP_DIR"

log "Cloning project from GitHub..."
git clone "$REPO_URL" "$APP_DIR"

# ---------- .env ----------
log "Creating .env file..."
mkdir -p "$SERVER_DIR"

cat > "$ENV_FILE" <<EOF
PORT=$APP_PORT
ADMIN_ID=$ADMIN_ID
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID

# مابقی متغیرها اگر لازم شد اینجا اضافه کن
EOF

ok ".env created at $ENV_FILE"

# ---------- نصب وابستگی‌های backend ----------
if [[ -f "$SERVER_DIR/package.json" ]]; then
  log "Installing backend dependencies..."
  cd "$SERVER_DIR"
  npm install --production
else
  err "package.json not found in $SERVER_DIR"
  err "Backend dependencies could NOT be installed. Check your repo structure."
fi

# ---------- راه‌اندازی PM2 ----------
log "Starting backend service with PM2..."
cd "$SERVER_DIR"

# اگر از قبل هست، استاپش کن
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
  pm2 stop "$APP_NAME" || true
  pm2 delete "$APP_NAME" || true
fi

pm2 start app.js --name "$APP_NAME"
pm2 save
pm2 startup systemd -u root --hp /root >/dev/null 2>&1 || true

ok "PM2 process started (name: $APP_NAME)"

# ---------- تنظیم Nginx ----------
log "Configuring nginx..."

# ساخت کانفیگ براساس این‌که دامنه هست یا نه
if [[ -n "$APP_DOMAIN" ]]; then
  cat > "$NGINX_SITE" <<EOF
server {
    listen 80;
    server_name $APP_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    access_log /var/log/nginx/${APP_NAME}_access.log;
    error_log  /var/log/nginx/${APP_NAME}_error.log;
}
EOF
else
  # فقط با IP و HTTP
  cat > "$NGINX_SITE" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    access_log /var/log/nginx/${APP_NAME}_access.log;
    error_log  /var/log/nginx/${APP_NAME}_error.log;
}
EOF
fi

ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/$APP_NAME

# حذف default
if [[ -f /etc/nginx/sites-enabled/default ]]; then
  rm -f /etc/nginx/sites-enabled/default
fi

nginx -t
systemctl restart nginx
ok "nginx basic config applied."

# ---------- SSL (اختیاری) ----------
if $ENABLE_SSL; then
  log "Installing Certbot for automatic SSL..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx

  log "Requesting Let's Encrypt certificate for $APP_DOMAIN ..."
  # این کامند سرتیفیکیت می‌گیرد و ریدایرکت https را هم خودش تنظیم می‌کند
  if certbot --nginx -d "$APP_DOMAIN" --non-interactive --agree-tos -m "admin@$APP_DOMAIN" --redirect; then
    ok "SSL certificate installed successfully."
  else
    err "Certbot failed to get a certificate. Check DNS / firewall."
  fi

  nginx -t && systemctl restart nginx || err "nginx reload failed after SSL."
fi

echo
echo "================================"
echo -e "🎉 ${GREEN}INSTALLATION COMPLETE!${RESET}"
echo -e "📦 PM2 STATUS:"
pm2 list

echo
if [[ -n "$APP_DOMAIN" && $ENABLE_SSL == true ]]; then
  echo -e "🌐 YOUR PANEL IS LIVE AT:"
  echo -e "👉  ${GREEN}https://$APP_DOMAIN${RESET}"
else
  echo -e "🌐 YOUR PANEL IS LIVE AT:"
  echo -e "👉  ${GREEN}http://$SERVER_IP:$APP_PORT${RESET}"
fi
echo "================================"
