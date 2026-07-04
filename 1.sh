#!/usr/bin/env bash
set -e

WALLET="48PBd6PodhS4AbafdeBMijb8QjEu6A3c43oryNyTNVj28vQZeky9pb618hzeEw4vbBaxukF7EuE46MHr1JQq1xTKTTtn4Fp"
POOL="pool.supportxmr.com:3333"

echo "[1/5] Установка зависимостей..."
apt update -y
apt install -y curl wget tar

echo "[2/5] Получение последней версии XMRig..."

LATEST=$(curl -fsSL https://api.github.com/repos/xmrig/xmrig/releases/latest | grep '"tag_name"' | cut -d '"' -f4)

FILE="xmrig-${LATEST#v}-linux-static-x64.tar.gz"

cd /root

rm -rf xmrig-* xmrig.tar.gz

wget -O xmrig.tar.gz \
"https://github.com/xmrig/xmrig/releases/download/${LATEST}/${FILE}"

echo "[3/5] Распаковка..."
tar -xzf xmrig.tar.gz

DIR=$(find . -maxdepth 1 -type d -name "xmrig-*" | head -1)

cd "$DIR"

echo "[4/5] Создание config.json..."

cat > config.json <<EOF
{
    "autosave": true,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "donate-level": 1,
    "randomx": {
        "mode": "auto"
    },
    "pools": [
        {
            "algo": "rx/0",
            "coin": "monero",
            "url": "$POOL",
            "user": "$WALLET",
            "pass": "x",
            "keepalive": true
        }
    ]
}
EOF

echo "[5/5] Запуск..."

chmod +x xmrig

./xmrig
