#!/bin/bash
set -e

# Debug information
echo "Current user: $(whoami)"
echo "Current PATH: $PATH"
echo "n8n location: $(which n8n)"
echo "n8n executable permissions: $(ls -l $(which n8n))"
echo "n8n symlink target: $(readlink -f $(which n8n))"
echo "n8n directory contents: $(ls -l $(dirname $(which n8n)))"

# Load NVM environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Verify Node.js and npm are available
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"
echo "NPM global packages:"
npm list -g --depth=0

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

# Check and set correct permissions for the custom nodes directory
if [ -d "/home/node/.n8n/nodes" ]; then
  chown -R node:node /home/node/.n8n/nodes
fi


# Check if Chromium is available
if [ -f "$PUPPETEER_EXECUTABLE_PATH" ]; then
  echo "Chromium found at $PUPPETEER_EXECUTABLE_PATH"
else
  echo "Error: Chromium not found at $PUPPETEER_EXECUTABLE_PATH"
  exit 1
fi

echo "Attempting to run n8n:"
n8n --version

exec "$@"
