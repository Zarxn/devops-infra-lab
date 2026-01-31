data "infisical_secrets" "secrets" {
  for_each = { for s in var.secrets : s.name => s }

  env_slug     = var.env_slug
  workspace_id = var.workspace_id
  folder_path  = coalesce(each.value.folder_path, var.folder_path)
}

ephemeral "infisical_secret" "ephemeral" {
  for_each = { for s in var.ephemeral_secrets : s.name => s }

  name         = each.value.name
  workspace_id = var.workspace_id
  env_slug     = var.env_slug
  folder_path  = coalesce(each.value.folder_path, var.folder_path)
}

locals {
  secrets_map = {
    for name, data in data.infisical_secrets.secrets :
    name => data.secrets[name].value
  }
}
