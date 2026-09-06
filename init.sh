#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "============================================="
echo "🤖 Starting Ollama Runner Endpoint Auto-Setup"
echo "============================================="

# 1. Install Ollama if not present
if ! command -v ollama &> /dev/null; then
    echo "📦 Ollama not found. Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "✅ Ollama is already installed."
fi

# 2. Configure systemd to expose the endpoint (0.0.0.0)
echo "🔧 Configuring systemd environment overrides..."
SYSTEMD_DIR="/etc/systemd/system/ollama.service.d"
sudo mkdir -p "$SYSTEMD_DIR"

# Create a drop-in file to avoid touching the core package service file
sudo tee "$SYSTEMD_DIR/override.conf" > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
EOF

# 3. Reload systemd and restart the service
echo "🔄 Reloading systemd daemon and restarting Ollama..."
sudo systemctl daemon-reload
sudo systemctl restart ollama

# 4. Open the firewall for the endpoint
if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "🛡️ UFW Firewall is active. Opening port 11434..."
    sudo ufw allow 11434/tcp comment 'Ollama Runner Endpoint'
    sudo ufw reload
else
    echo "ℹ️ UFW Firewall is not active or not installed. Skipping port binding."
fi

# 5. Fetch and print the Host IP address for GitHub Actions Configuration
HOST_IP=$(hostname -I | awk '{print $1}')
echo "============================================="
echo "🎉 Setup Completed Successfully!"
echo "============================================="
echo "🌐 Local Endpoint:  http://127.0.0.1:11434"
echo "🔗 Runner Endpoint: http://$HOST_IP:11434"
echo "============================================="

# 6. Self-Verification check
echo "🧪 Running endpoint health check..."
sleep 3
if curl -s "http://127.0.0" > /dev/null; then
    echo "✅ Success! Ollama is actively running and exposed."
else
    echo "❌ Error: Ollama failed to respond. Check log via: journalctl -u ollama"
fi
