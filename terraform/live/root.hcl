# ==============================================================================
# CONFIGURACIÓN RAÍZ DE TERRAGRUNT
# ==============================================================================
# Este archivo contiene la configuración compartida para todos los ambientes
# Define configuraciones comunes como el backend
# ==============================================================================

# Configura Terragrunt para almacenar automáticamente los archivos tfstate en un directorio local
remote_state {
  backend = "local"

  config = {
    # El state se guardará en: terraform/live/<ambiente>/<componente>/terraform.tfstate
    # Se usa get_parent_terragrunt_dir() para asegurar que el path sea absoluto y no relativo al cache
    path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
