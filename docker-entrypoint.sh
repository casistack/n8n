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

# Check if Chromium is available
if [ -f "$PUPPETEER_EXECUTABLE_PATH" ]; then
  echo "Chromium found at $PUPPETEER_EXECUTABLE_PATH"
else
  echo "Error: Chromium not found at $PUPPETEER_EXECUTABLE_PATH"
  exit 1
fi

echo "Attempting to run n8n:"
n8n --version

# New package installation logic
# Function to compare versions
version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

# Function to extract version from filename
extract_version() {
    echo "$1" | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+)\.tgz$/\1/'
}

# Function to install packages
install_packages() {
    local package_dir="$1"
    local install_dir="$2"
    
    # Create an associative array to store the latest version of each package
    declare -A latest_versions

    # Check if there are any .tgz files in the package directory
    if ls $package_dir/*.tgz 1> /dev/null 2>&1; then
        for package in $package_dir/*.tgz; do
            base_name=$(basename "$package" .tgz | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+$//')
            version=$(extract_version "$package")
            
            if [[ -z "${latest_versions[$base_name]}" ]] || version_gt "$version" "${latest_versions[$base_name]}"; then
                latest_versions[$base_name]="$version"
            fi
        done

        for base_name in "${!latest_versions[@]}"; do
            latest_version="${latest_versions[$base_name]}"
            latest_package="$package_dir/${base_name}-${latest_version}.tgz"
            echo "Installing $base_name version $latest_version"
            npm install --prefix $install_dir $latest_package
        done
        echo "Latest versions of custom packages installed/updated."
    else
        echo "No custom packages found in $package_dir"
    fi
}

# Install packages from mypackages directory
install_packages "/data/mypackages" "/home/node/.n8n/nodes"

# Execute the main command
exec "$@"
