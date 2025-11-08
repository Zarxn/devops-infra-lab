variable "instances" {


  description = "Configuration fot the incus instances to be deployed"
  type = map(object(
    {

      name   = string
      type   = optional(string, "container")
      image  = optional(string, "images:ubuntu/jammy/cloud")
      running = optional(bool, true)
      config = optional(map(any), {})
      
  }))

  
}

variable "cloud_init_user_data" {
  type = string
  description = "Raw cloud-init user-data content"

}

# variable "storage_pools" {

#   description = "Configuration for Incus Storage Pools"
#   type = map(object ({

#     name = string
#     driver = optional(string, "dir")
#     config = map(any)
#   }) )

# }