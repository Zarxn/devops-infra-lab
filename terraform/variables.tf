variable "instances" {


  description = "Configuration fot the incus instances to be deployed"
  type = map(object(
    {

      name   = string
      type   = optional(string, "container")
      image  = optional(string, "images:ubuntu/jammy/cloud")
      config = optional(map(any), {})
  }))
}

variable "ssh_public_key" {

  description = "Public Key to be injected within the instances"
  type = string
  sensitive = true
}

# variable "storage_pools" {

#   description = "Configuration for Incus Storage Pools"
#   type = map(object ({

#     name = string
#     driver = optional(string, "dir")
#     config = map(any)
#   }) )

# }