# ==============================================================================
# CLUSTER K8S - AMBIENTE DE STAGING
# ==============================================================================
# Este archivo configura el despliegue del cluster Kubernetes para staging
# Staging usa configuraciones más robustas que dev, similares a producción
# Los secretos se obtienen de Infisical usando el CLI
# ==============================================================================

# Incluye la configuración raíz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# -----------------------------------------------------------------------------
# TERRAFORM SOURCE
# -----------------------------------------------------------------------------
terraform {
  source = "${get_repo_root()}/terraform/modules/incus_instance"
}

# -----------------------------------------------------------------------------
# LOCALS - GESTIÓN DE SECRETOS
# -----------------------------------------------------------------------------
locals {
  # Token de Infisical desde variable de entorno
  # Configurar con: export INFISICAL_TOKEN_STAGING="st.xxx.yyy.zzz"
  infisical_token = get_env("INFISICAL_TOKEN_STAGING", "")

  # ID del proyecto en Infisical para staging
  infisical_project_id = get_env("INFISICAL_PROJECT_ID_STAGING", "")

  # Dominio de Infisical
  infisical_domain = get_env("INFISICAL_DOMAIN", "")

  # Leer secretos desde Infisical usando el CLI
  ssh_public_key = local.infisical_token != "" ? run_cmd(
    "--terragrunt-quiet",
    "sh", "-c",
    "infisical secrets get SSH_PUBLIC_KEY --domain=${local.infisical_domain} --projectId=${local.infisical_project_id} --env=staging --token=${local.infisical_token} --silent --plain"
  ) : ""
  # Ruta al template de cloud-init
  cloud_init_template = "${get_repo_root()}/terraform/cloud-init/cloud-init.yaml"

  # Configuración del cluster específica para el ambiente staging
  cluster_config = {
    control_plane = {
      memory = "2560MiB"  # ~2.5GB
      cpu    = 2
    }
    workers = {
      memory = "2GiB"
      cpu    = 2
    }
  }
}

# -----------------------------------------------------------------------------
# INPUTS - Variables para el Módulo
# -----------------------------------------------------------------------------
inputs = {
  # Definición de las instancias del cluster de staging
  instances = {
    # Nodo Control Plane
    "staging-k8s-cp01" = {
      name    = "staging-k8s-cp01"
      type    = "virtual-machine"
      image   = "images:ubuntu/jammy/cloud"
      running = true
      config = {
        "limits.memory"  = local.cluster_config.control_plane.memory
        "limits.cpu"     = tostring(local.cluster_config.control_plane.cpu)
        "boot.autostart" = "true"
      }
    }

    # Nodo Worker 1
    "staging-k8s-worker01" = {
      name    = "staging-k8s-worker01"
      type    = "virtual-machine"
      image   = "images:ubuntu/jammy/cloud"
      running = true
      config = {
        "limits.memory"  = local.cluster_config.workers.memory
        "limits.cpu"     = tostring(local.cluster_config.workers.cpu)
        "boot.autostart" = "true"
      }
    }

    # Nodo Worker 2
    "staging-k8s-worker02" = {
      name    = "staging-k8s-worker02"
      type    = "virtual-machine"
      image   = "images:ubuntu/jammy/cloud"
      running = true
      config = {
        "limits.memory"  = local.cluster_config.workers.memory
        "limits.cpu"     = tostring(local.cluster_config.workers.cpu)
        "boot.autostart" = "true"
      }
    }
  }

  # Configuración de cloud-init con secreto desde Infisical
  cloud_init_user_data = templatefile(local.cloud_init_template, {
    ssh_public_key = local.ssh_public_key
  })
}
