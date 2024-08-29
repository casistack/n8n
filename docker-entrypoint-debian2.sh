#!/bin/bash
set -e

# Debug information
echo "Current user: $(whoami)"
echo "Current PATH: $PATH"
echo "n8n location: $(which n8n)"
echo "n8n version: $(n8n --version)"
echo "n8n executable permissions: $(ls -l $(which n8n))"
echo "n8n symlink target: $(readlink -f $(which n8n))"
echo "n8n directory contents: $(ls -l $(dirname $(which n8n)))"
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"
echo "NPM global packages:"
echo "NODE_PATH: $NODE_PATH"
npm list -g --depth=0

# Check n8n module paths
echo "n8n base nodes path: $(node -e "console.log(require.resolve('n8n-nodes-base'))")"
echo "n8n core path: $(node -e "console.log(require.resolve('n8n-core'))")"

# Function to compare versions
##version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

##install_custom_packages() {
    ##local package_dir="/data/mypackages"
    ##local install_dir="/home/node/.n8n/custom"
    
    ##if [ -d "$package_dir" ] && [ "$(ls -A $package_dir)" ]; then
      ##  for package in $package_dir/*.tgz; do
        ##    if [ -f "$package" ]; then
          ##      echo "Installing custom package: $(basename "$package")"
            ##    npm install --no-save --prefix "$install_dir" "$package"
            ##fi
        ##done
        ##echo "Custom packages installed."
    ##else
      ##  echo "No custom packages found in $package_dir"
    ##fi
##}

##install_custom_packages

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

# Check if n8n is available
if ! command -v n8n &> /dev/null; then
    echo "Error: n8n command not found"
    exit 1
fi

# Execute the main command
exec "$@"
