variable "workspace_id" {
  description = "Workspace ID (Project ID) en Infisical"
  type        = string
}

variable "env_slug" {
  description = "Environment slug (dev, staging, prod)"
  type        = string
}

variable "folder_path" {
  description = "Folder path en Infisical"
  type        = string
  default     = "/"
}

variable "secrets" {
  description = "Secretos a obtener (quedan en state, sensitive)"
  type = list(object({
    name        = string
    folder_path = optional(string)
  }))
  default = []
}

variable "ephemeral_secrets" {
  description = "Secretos efímeros a obtener (NO quedan en state)"
  type = list(object({
    name        = string
    folder_path = optional(string)
  }))
  default = []
}
