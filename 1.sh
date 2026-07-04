#!/usr/bin/env bash
set -e

WALLET="48PBd6PodhS4AbafdeBMijb8QjEu6A3c43oryNyTNVj28vQZeky9pb618hzeEw4vbBaxukF7EuE46MHr1JQq1xTKTTtn4Fp"
POOL="pool.supportxmr.com:3333"

echo "[1/6] Installing packages..."
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y curl wget tar screen

echo "[2/6] Creating 16GB swap..."

if ! swapon --show | grep -q "/swapfile"; then
    if command -v fallocate >/dev/null 2>&1; then
        fallocate -l 16G /swapfile
    else
        dd if=/dev/zero of=/swapfile bs=1M count=16384 status=progress
    fi

    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    grep -q "/swapfile" /etc/fstab || \
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

echo "[3/6] Downloading latest XMRig..."

LATEST=$(curl -fsSL https://api.github.com/repos/xmrig/xmrig/releases/latest | grep tag_name | cut -d '"' -f4)

FILE="xmrig-${LATEST#v}-linux-static-x64.tar.gz"

cd /root

rm -rf xmrig-* xmrig.tar.gz

wget -q -O xmrig.tar.gz \
"https://github.com/xmrig/xmrig/releases/download/${LATEST}/${FILE}"

echo "[4/6] Extracting..."

tar -xzf xmrig.tar.gz

DIR=$(find /root -maxdepth 1 -type d -name "xmrig-*" | head -n1)

cd "$DIR"

chmod +x xmrig

echo "[5/6] Creating config..."

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

echo "[6/6] Starting XMRig in screen..."

screen -wipe >/dev/null 2>&1 || true
screen -S xmrig -X quit >/dev/null 2>&1 || true

screen -dmS xmrig bash -c "
cd $DIR
./xmrig
"

sleep 2

echo
echo "======================================"
echo "XMRig started!"
echo
echo "Swap:"
free -h | grep Swap
echo
echo "To attach:"
echo "screen -r xmrig"
echo
echo "To detach:"
echo "Ctrl+A then D"
echo "======================================"
