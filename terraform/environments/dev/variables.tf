variable "workspace_id" {
  description = "Infisical Workspace ID"
  type        = string
}

variable "instances" {
  description = "Incus instances configuration"
  type = map(object({
    name    = string
    type    = optional(string, "container")
    image   = optional(string, "images:ubuntu/jammy/cloud")
    running = optional(bool, true)
    config  = optional(map(any), {})
  }))
}

variable "infisical_client_id" {
  description = "Infisical Machine Identity client ID"
  type        = string
}

variable "infisical_client_secret" {
  description = "Infisical Machine Identity client secret"
  type        = string
  sensitive   = true
}
