#!/bin/sh
set -e

# Debug information
echo "Current user: $(whoami)"
echo "Current PATH: $PATH"
echo "n8n location: $(which n8n)"
echo "n8n executable permissions: $(ls -l $(which n8n))"
echo "n8n version: $(n8n --version)"
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

exec "$@"
