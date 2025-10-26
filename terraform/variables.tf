variable "instances" {


    description = "Configuration fot the incus instances to be deployed"
    type = map(object (
    {

        name = string
        image = optional(string, "images:ubuntu/22.04")
        config = map(any)
    }))
}


variable "storage_pools" {

  description = "Configuration for Incus Storage Pools"
  type = map(object ({

    name = string
    driver = optional(string, "dir")
    config = map(any)
  }) )

}