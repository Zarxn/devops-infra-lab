#!/bin/bash
set -e

echo "=========================================="
echo "Installing Development Tools for Terraform"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Install pre-commit
echo -e "${YELLOW}[1/4] Installing pre-commit framework...${NC}"
if command -v pre-commit &> /dev/null; then
    echo -e "${GREEN}✓ pre-commit already installed: $(pre-commit --version)${NC}"
else
    pip3 install pre-commit --user --break-system-packages
    echo -e "${GREEN}✓ pre-commit installed successfully${NC}"
fi
echo ""

# 2. Install terraform-docs
echo -e "${YELLOW}[2/4] Installing terraform-docs...${NC}"
if command -v terraform-docs &> /dev/null; then
    echo -e "${GREEN}✓ terraform-docs already installed: $(terraform-docs --version)${NC}"
else
    TERRAFORM_DOCS_VERSION="v0.18.0"
    wget -q https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz
    tar -xzf terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz
    chmod +x terraform-docs
    sudo mv terraform-docs /usr/local/bin/
    rm terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz
    echo -e "${GREEN}✓ terraform-docs installed successfully${NC}"
fi
echo ""

# 3. Install tflint
echo -e "${YELLOW}[3/4] Installing tflint...${NC}"
if command -v tflint &> /dev/null; then
    echo -e "${GREEN}✓ tflint already installed: $(tflint --version)${NC}"
else
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    echo -e "${GREEN}✓ tflint installed successfully${NC}"
fi
echo ""

# 4. Install checkov
echo -e "${YELLOW}[4/4] Installing checkov...${NC}"
if command -v checkov &> /dev/null; then
    echo -e "${GREEN}✓ checkov already installed: $(checkov --version)${NC}"
else
    pip3 install checkov --user --break-system-packages
    echo -e "${GREEN}✓ checkov installed successfully${NC}"
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✓ All tools installed successfully!${NC}"
echo "=========================================="
echo ""
echo "Installed tools:"
echo "  - pre-commit: $(pre-commit --version 2>/dev/null || echo 'Run: export PATH=\$HOME/.local/bin:\$PATH')"
echo "  - terraform-docs: $(terraform-docs --version 2>/dev/null || echo 'N/A')"
echo "  - tflint: $(tflint --version 2>/dev/null | head -n1 || echo 'N/A')"
echo "  - checkov: $(checkov --version 2>/dev/null || echo 'Run: export PATH=\$HOME/.local/bin:\$PATH')"
