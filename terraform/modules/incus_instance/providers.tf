# ==============================================================================
# PROVEEDOR INCUS
# ==============================================================================

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 1.0.0"
    }
  }
}

provider "incus" {
  default_remote               = "local"
  generate_client_certificates = true
}
