resource "incus_instance" "main" {
  for_each = var.instances
  name     = each.value.name
  type = each.value.type
  image    = each.value.image
  running = each.value.running
  config = merge(
    each.value.config,
    {
      "cloud-init.user-data" = var.cloud_init_user_data
    }
  )
}