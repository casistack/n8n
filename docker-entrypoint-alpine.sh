#!/bin/sh
set -e

# Debug information
echo "Current user: $(whoami)"
echo "Current PATH: $PATH"
echo "n8n location: $(which n8n)"
echo "n8n executable permissions: $(ls -l $(which n8n))"
echo "n8n symlink target: $(readlink -f $(which n8n))"
echo "n8n directory contents: $(ls -l $(dirname $(which n8n)))"

# Verify Node.js and npm are available
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"
echo "NPM global packages:"
npm list -g --depth=0

if [ -d /opt/custom-certificates ]; then
  echo "Trusting custom certificates from /opt/custom-certificates."
  export NODE_OPTIONS="--use-openssl-ca $NODE_OPTIONS"
  export SSL_CERT_DIR=/opt/custom-certificates
  c_rehash /opt/custom-certificates
fi

# Check if n8n is available
if ! command -v n8n > /dev/null 2>&1; then
    echo "Error: n8n command not found"
    exit 1
fi

# Check if Chromium is available
if [ -f "$PUPPETEER_EXECUTABLE_PATH" ]; then
  echo "Chromium found at $PUPPETEER_EXECUTABLE_PATH"
else
  echo "Error: Chromium not found at $PUPPETEER_EXECUTABLE_PATH"
  exit 1
fi

# Set up Chromium flags
export CHROMIUM_FLAGS="--no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage --disable-gpu --user-data-dir=/home/node/.config/chromium"

# Configure Puppeteer to use these flags
export PUPPETEER_ADDITIONAL_ARGS="$CHROMIUM_FLAGS"

# Ensure the Chromium user data directory exists and has correct permissions
mkdir -p /home/node/.config/chromium
chown -R node:node /home/node/.config/chromium

echo "Attempting to run n8n:"
n8n --version

# Simplified package installation
install_packages() {
    local package_dir="$1"
    local install_dir="$2"
    
    if [ -d "$package_dir" ] && [ "$(ls -A $package_dir)" ]; then
        for package in $package_dir/*.tgz; do
            echo "Installing $package"
            npm install --prefix "$install_dir" "$package"
        done
        echo "Custom packages installed/updated."
    else
        echo "No custom packages found in $package_dir"
    fi
}

# Install packages from mypackages directory
install_packages "/data/mypackages" "/home/node/.n8n/nodes"

# Execute the main command
exec "$@"
