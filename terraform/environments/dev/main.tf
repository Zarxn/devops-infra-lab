module "secrets" {
  source = "../../modules/infisical"

  workspace_id = var.workspace_id
  env_slug     = "dev"
  folder_path  = "/"

  secrets = [
    { name = "SSH_PUBLIC_KEY" }
  ]
}

module "incus_instance" {
  source = "../../modules/incus_instance"

  instances = var.instances

  cloud_init_user_data = templatefile("${path.module}/../../cloud-init/cloud-init.yaml", {
    ssh_public_key = module.secrets.secrets["SSH_PUBLIC_KEY"]
  })
}
