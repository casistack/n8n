#!/bin/bash
set -e

if ! command -v n8n &> /dev/null; then
    echo "Error: n8n command not found"
    exit 1
fi

n8n_path=$(command -v n8n)
n8n_package_json=/usr/local/lib/node_modules/n8n/package.json
n8n_version=$(node -p "require('$n8n_package_json').version")

echo "Starting n8n $n8n_version with Node $(node --version)"
echo "n8n executable: $n8n_path -> $(readlink -f "$n8n_path")"

# Check if Chromium is available
if [ -f "$PUPPETEER_EXECUTABLE_PATH" ]; then
  echo "Chromium found at $PUPPETEER_EXECUTABLE_PATH"
else
  echo "Error: Chromium not found at $PUPPETEER_EXECUTABLE_PATH"
  exit 1
fi

# Check for custom certificates
if [ -d /opt/custom-certificates ]; then
  echo "Trusting custom certificates from /opt/custom-certificates."
  export NODE_OPTIONS=--use-openssl-ca $NODE_OPTIONS
  export SSL_CERT_DIR=/opt/custom-certificates
  c_rehash /opt/custom-certificates
fi

echo "Cleaning up Chrome lock files..."
rm -f /data2/session-session/SingletonLock
rm -f /data2/session-session/SingletonCookie
rm -f /data2/session-session/SingletonSocket
rm -f /data2/session-session/DevToolsActivePort
echo "Chrome lock files cleaned up"

# Repair persisted ownership only when a mismatch exists.
if [ -d /home/node/.n8n ] && [ -n "$(find /home/node/.n8n \( ! -user node -o ! -group node \) -print -quit 2>/dev/null)" ]; then
    echo "Fixing ownership of /home/node/.n8n..."
    chown -R node:node /home/node/.n8n 2>/dev/null || echo "Warning: Could not change ownership of /home/node/.n8n"
fi

if [ -d /home/node/.n8n/nodes ] && [ -n "$(find /home/node/.n8n/nodes ! -type l ! -perm 0755 -print -quit 2>/dev/null)" ]; then
    echo "Fixing permissions for custom nodes directory..."
    chmod -R 755 /home/node/.n8n/nodes 2>/dev/null || echo "Warning: Could not fix permissions in nodes directory"
fi

# Fix permissions for /data2 directory (for WhatsApp sessions and other data)
if [ -d "/data2" ]; then
    if [ -n "$(find /data2 \( ! -user node -o ! -group node \) -print -quit 2>/dev/null)" ]; then
        echo "Fixing ownership of /data2 directory..."
        chown -R node:node /data2 2>/dev/null || echo "Warning: Could not change ownership of /data2 directory"
    fi

    if [ -n "$(find /data2 ! -type l ! -perm 0700 -print -quit 2>/dev/null)" ]; then
        echo "Enforcing secure permissions (700) on /data2..."
        chmod -R 700 /data2 2>/dev/null || echo "Warning: Could not fix permissions in /data2 directory"
    fi
fi

# Execute the main command as the node user (drop privileges)
exec gosu node "$@"
