#!/bin/bash
# ==============================================================================
# Script de instalación del CLI de Infisical
# ==============================================================================
# Este script descarga e instala el CLI oficial de Infisical para interactuar
# con el servicio de gestión de secretos desde Terragrunt.
#
# Uso:
#   ./scripts/install-infisical-cli.sh
#
# Documentación:
#   https://infisical.com/docs/cli/overview
# ==============================================================================

set -euo pipefail

# Configuración
INFISICAL_VERSION="${INFISICAL_VERSION:-latest}"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR=$(mktemp -d)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detectar arquitectura
ARCH=$(uname -m)
case ${ARCH} in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        log_error "Arquitectura no soportada: ${ARCH}"
        exit 1
        ;;
esac

log_info "Arquitectura detectada: ${ARCH}"

# Verificar si ya está instalado
if command -v infisical &> /dev/null; then
    CURRENT_VERSION=$(infisical --version 2>&1 | grep -oP 'infisical version \K[0-9.]+' || echo "unknown")
    log_warn "Infisical CLI ya está instalado (versión: ${CURRENT_VERSION})"
    read -p "¿Desea reinstalar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Instalación cancelada"
        exit 0
    fi
fi

# Descargar el binario
log_info "Descargando Infisical CLI..."

if [ "${INFISICAL_VERSION}" = "latest" ]; then
    DOWNLOAD_URL="https://github.com/Infisical/infisical/releases/latest/download/infisical_${ARCH}"
else
    DOWNLOAD_URL="https://github.com/Infisical/infisical/releases/download/${INFISICAL_VERSION}/infisical_${ARCH}"
fi

cd "${TEMP_DIR}"
if ! curl -fsSL -o infisical "${DOWNLOAD_URL}"; then
    log_error "Error al descargar Infisical CLI desde ${DOWNLOAD_URL}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Hacer el binario ejecutable
chmod +x infisical

# Verificar que el binario funciona
log_info "Verificando binario..."
if ! ./infisical --version &> /dev/null; then
    log_error "El binario descargado no es válido"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Instalar en el sistema
log_info "Instalando en ${INSTALL_DIR}..."
sudo mv infisical "${INSTALL_DIR}/infisical"

# Limpiar
rm -rf "${TEMP_DIR}"

# Verificar instalación
INSTALLED_VERSION=$(infisical --version 2>&1 | grep -oP 'infisical version \K[0-9.]+' || echo "unknown")

echo ""
echo "================================================================================"
log_info "Infisical CLI instalado correctamente"
echo "================================================================================"
echo ""
echo "Versión instalada: ${INSTALLED_VERSION}"
echo "Ubicación:         $(which infisical)"
echo ""
echo "Comandos básicos:"
echo "  infisical --version              # Ver versión"
echo "  infisical login                  # Autenticarse interactivamente"
echo "  infisical secrets                # Listar secretos del proyecto"
echo "  infisical secrets get KEY        # Obtener un secreto específico"
echo ""
echo "Para usar con Terragrunt:"
echo "  1. Obtener un Service Token desde la UI de Infisical"
echo "  2. Exportar: export INFISICAL_TOKEN=<tu-token>"
echo "  3. Los archivos terragrunt.hcl usarán este token automáticamente"
echo ""
echo "Documentación: https://infisical.com/docs/cli/overview"
echo "================================================================================"
