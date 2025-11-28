#!/bin/bash

echo "🔄 آپدیت پروژه C-STAR PRO..."

cd /opt/cstar

git pull
npm install
node server/database/init.js

pm2 restart cstar

echo "✔ آپدیت کامل شد."
