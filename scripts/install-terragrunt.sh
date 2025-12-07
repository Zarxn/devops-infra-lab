#!/usr/bin/env bash
#
# Script: install-terragrunt.sh
# Description: Downloads and installs Terragrunt for Linux AMD64
# Usage: ./install-terragrunt.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
TERRAGRUNT_VERSION="latest"  # Can be changed to specific version like "v0.68.1"

echo -e "${YELLOW}=== Terragrunt Installation Script ===${NC}"
echo ""

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root or with sudo${NC}"
   echo "Usage: sudo $0"
   exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "Detected architecture: ${GREEN}linux_${ARCH}${NC}"
echo ""

# Get latest version if not specified
if [[ "$TERRAGRUNT_VERSION" == "latest" ]]; then
    echo "Fetching latest Terragrunt version..."
    TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "$TERRAGRUNT_VERSION" ]]; then
        echo -e "${RED}Failed to fetch latest version${NC}"
        exit 1
    fi
fi

echo -e "Installing Terragrunt ${GREEN}${TERRAGRUNT_VERSION}${NC}"
echo ""

# Download URL
DOWNLOAD_URL="https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH}"

echo "Downloading from: $DOWNLOAD_URL"
echo ""

# Download Terragrunt
TMP_FILE="/tmp/terragrunt_${ARCH}"
if curl -L -o "$TMP_FILE" "$DOWNLOAD_URL"; then
    echo -e "${GREEN}Download complete${NC}"
else
    echo -e "${RED}Download failed${NC}"
    rm -f "$TMP_FILE"
    exit 1
fi

# Make executable
chmod +x "$TMP_FILE"

# Move to install directory
echo "Installing to ${INSTALL_DIR}/terragrunt..."
mv "$TMP_FILE" "${INSTALL_DIR}/terragrunt"

# Verify installation
echo ""
echo -e "${YELLOW}Verifying installation...${NC}"
if command -v terragrunt &> /dev/null; then
    INSTALLED_VERSION=$(terragrunt --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓ Terragrunt successfully installed!${NC}"
    echo ""
    echo "Version: $INSTALLED_VERSION"
    echo "Location: $(which terragrunt)"
else
    echo -e "${RED}Installation verification failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "You can now use Terragrunt by running: terragrunt --help"
