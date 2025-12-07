# ==============================================================================
# STORAGE - AMBIENTE DE DESARROLLO
# ==============================================================================
# Este archivo configura el despliegue de storage pools para desarrollo
# NOTA: Actualmente es un placeholder ya que el módulo storage_pool aún no está
# completamente implementado
# ==============================================================================

# Incluye la configuración raíz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# -----------------------------------------------------------------------------
# TERRAFORM SOURCE
# -----------------------------------------------------------------------------
terraform {
  source = "${get_repo_root()}/terraform/modules/storage_pool"
}

# -----------------------------------------------------------------------------
# LOCALS
# -----------------------------------------------------------------------------
locals {
}

# -----------------------------------------------------------------------------
# INPUTS
# -----------------------------------------------------------------------------
# TODO: Descomentar y configurar cuando el módulo storage_pool esté completo
# inputs = {
#   storage_pools = {
#     "dev-default-pool" = {
#       name   = "dev-default-pool"
#       driver = "dir"
#       config = {
#         source = "/var/lib/incus/storage-pools/dev-default"
#       }
#     }
#   }
# }
