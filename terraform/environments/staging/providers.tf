terraform {
  required_version = ">= 1.10.0"

  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = ">= 0.12.0"
    }
    incus = {
      source  = "lxc/incus"
      version = "~> 1.0.0"
    }
  }
}

provider "infisical" {
  host = "http://127.0.0.1:8080"
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

provider "incus" {
  generate_client_certificates = true
  default_remote               = "local"
}
