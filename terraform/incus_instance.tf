module "incus_instance" {

  source    = "./modules/incus_instance"
  instances = var.instances
  # cloud_init_user_data = file("${path.root}/cloud-init/cloud-init.yaml")
  cloud_init_user_data = templatefile("${path.root}/cloud-init/cloud-init.yaml", {
    ssh_public_key = var.ssh_public_key
  })

}