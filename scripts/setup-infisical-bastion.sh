#!/bin/bash
# ==============================================================================
# Script de instalación de Infisical en Bastion
# ==============================================================================
# Este script instala y configura Infisical como servicio de gestión de secretos
# en el host bastion usando Docker.
#
# Uso:
#   ./scripts/setup-infisical-bastion.sh
#
# Variables de entorno opcionales:
#   INFISICAL_VERSION - Versión de la imagen Docker (default: latest)
#   INFISICAL_PORT    - Puerto para exponer el servicio (default: 8080)
# ==============================================================================

set -euo pipefail

# Configuración
INFISICAL_VERSION="${INFISICAL_VERSION:-latest}"
INFISICAL_PORT="${INFISICAL_PORT:-8080}"
INFISICAL_DATA_DIR="/opt/infisical"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de utilidad
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que se ejecuta como usuario no-root
if [ "$EUID" -eq 0 ]; then
    log_error "No ejecutar este script como root. Se solicitará sudo cuando sea necesario."
    exit 1
fi

# Instalación de Docker
log_info "Verificando instalación de Docker..."
DOCKER_INSTALLED=false
if ! command -v docker &> /dev/null; then
    log_info "Docker no encontrado. Instalando..."
    sudo apt-get update -qq
    sudo apt-get install -y docker.io docker-compose
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker "${USER}"
    DOCKER_INSTALLED=true
    log_info "Docker instalado correctamente"
else
    log_info "Docker ya está instalado: $(docker --version)"
fi

# Verificar permisos de Docker
log_info "Verificando permisos de Docker..."
if ! docker ps &> /dev/null; then
    if [ "${DOCKER_INSTALLED}" = true ]; then
        log_error "Docker fue instalado pero requiere reiniciar la sesión"
        echo ""
        echo "================================================================================"
        echo "ACCIÓN REQUERIDA:"
        echo "================================================================================"
        echo ""
        echo "El usuario '${USER}' fue agregado al grupo 'docker', pero los cambios"
        echo "no surten efecto hasta que cierre sesión y vuelva a entrar."
        echo ""
        echo "Por favor ejecute:"
        echo ""
        echo "  1. Salir de la sesión actual:"
        echo "     exit"
        echo ""
        echo "  2. Volver a conectarse:"
        echo "     vagrant ssh bastion  # (o su método de conexión)"
        echo ""
        echo "  3. Re-ejecutar este script:"
        echo "     cd /home/vagrant/infra"
        echo "     ./scripts/setup-infisical-bastion.sh"
        echo ""
        echo "================================================================================"
        exit 1
    else
        log_warn "No tiene permisos para usar Docker sin sudo"
        echo ""
        echo "Opciones:"
        echo "  1. Cerrar sesión y volver a entrar (RECOMENDADO)"
        echo "  2. Ejecutar: newgrp docker  (temporal, solo esta sesión)"
        echo "  3. Continuar usando sudo (no recomendado)"
        echo ""
        read -p "¿Desea continuar usando sudo? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Instalación cancelada. Por favor cierre sesión y vuelva a entrar."
            exit 0
        fi
        log_warn "Continuando con sudo..."
        DOCKER_CMD="sudo docker"
        COMPOSE_CMD="sudo docker-compose"
    fi
else
    DOCKER_CMD="docker"
    COMPOSE_CMD="docker-compose"
fi

# Crear estructura de directorios
log_info "Creando directorio de datos en ${INFISICAL_DATA_DIR}..."
sudo mkdir -p "${INFISICAL_DATA_DIR}/data"
sudo chown -R "${USER}:${USER}" "${INFISICAL_DATA_DIR}"

# Generar docker-compose.yml
log_info "Generando configuración docker-compose..."

# Generar secretos aleatorios si no existen
if [ ! -f "${INFISICAL_DATA_DIR}/.env.secrets" ]; then
    log_info "Generando secretos para Infisical..."
    AUTH_SECRET=$(openssl rand -hex 32)
    ENCRYPTION_KEY=$(openssl rand -hex 16)
    DB_PASSWORD=$(openssl rand -hex 16)

    cat > "${INFISICAL_DATA_DIR}/.env.secrets" << EOF
AUTH_SECRET=${AUTH_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
DB_PASSWORD=${DB_PASSWORD}
EOF
    chmod 600 "${INFISICAL_DATA_DIR}/.env.secrets"
else
    log_info "Usando secretos existentes..."
    source "${INFISICAL_DATA_DIR}/.env.secrets"
fi

cat > "${INFISICAL_DATA_DIR}/docker-compose.yml" << EOF
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: infisical-postgres
    restart: unless-stopped
    volumes:
      - ${INFISICAL_DATA_DIR}/postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=infisical
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=infisical
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U infisical"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - infisical-net

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: infisical-redis
    restart: unless-stopped
    command: redis-server --requirepass ${DB_PASSWORD}
    volumes:
      - ${INFISICAL_DATA_DIR}/redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - infisical-net

  # Infisical Application
  infisical:
    image: infisical/infisical:${INFISICAL_VERSION}
    container_name: infisical
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "127.0.0.1:${INFISICAL_PORT}:8080"
    environment:
      # Database
      - DB_CONNECTION_URI=postgres://infisical:${DB_PASSWORD}@postgres:5432/infisical

      # Redis
      - REDIS_URL=redis://default:${DB_PASSWORD}@redis:6379

      # Secrets (generados automáticamente)
      - AUTH_SECRET=${AUTH_SECRET}
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}

      # Configuration
      - NODE_ENV=production
      - TELEMETRY_ENABLED=false
      - SITE_URL=http://localhost:${INFISICAL_PORT}

    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/api/status"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - infisical-net

networks:
  infisical-net:
    driver: bridge
EOF

# Detener contenedor existente si está corriendo
if ${DOCKER_CMD} ps -a --format '{{.Names}}' | grep -q '^infisical$'; then
    log_warn "Contenedor existente detectado. Deteniendo..."
    cd "${INFISICAL_DATA_DIR}"
    ${COMPOSE_CMD} down
fi

# Iniciar Infisical
log_info "Iniciando Infisical..."
cd "${INFISICAL_DATA_DIR}"
${COMPOSE_CMD} up -d

# Esperar a que el servicio esté listo
log_info "Esperando a que Infisical esté disponible..."
TIMEOUT=60
ELAPSED=0
until curl -sf "http://localhost:${INFISICAL_PORT}/api/status" > /dev/null 2>&1; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        log_error "Timeout esperando a que Infisical inicie"
        docker logs infisical
        exit 1
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

# Verificar estado
log_info "Verificando estado del servicio..."
CONTAINER_STATUS=$(${DOCKER_CMD} inspect -f '{{.State.Health.Status}}' infisical 2>/dev/null || echo "unknown")

echo ""
echo "================================================================================"
log_info "Infisical instalado correctamente"
echo "================================================================================"
echo ""
echo "Información del servicio:"
echo "  URL:              http://localhost:${INFISICAL_PORT}"
echo "  Estado:           $(${DOCKER_CMD} ps --filter name=infisical --format '{{.Status}}')"
echo "  Health:           ${CONTAINER_STATUS}"
echo "  Directorio datos: ${INFISICAL_DATA_DIR}/data"
echo ""
echo "Comandos útiles:"
echo "  Ver logs:         ${DOCKER_CMD} logs -f infisical"
echo "  Reiniciar:        cd ${INFISICAL_DATA_DIR} && ${COMPOSE_CMD} restart"
echo "  Detener:          cd ${INFISICAL_DATA_DIR} && ${COMPOSE_CMD} down"
echo "  Estado:           ${DOCKER_CMD} ps --filter name=infisical"
echo ""
echo "Próximos pasos:"
echo "  1. Acceder a http://localhost:${INFISICAL_PORT} para crear una cuenta"
echo "  2. Crear un proyecto para dev/staging"
echo "  3. Generar un Service Token para Terragrunt"
echo "  4. Exportar el token: export INFISICAL_TOKEN=<tu-token>"
echo ""
echo "================================================================================"
