# Incus Instance Module

This module manages Incus instances (containers or virtual machines) with cloud-init configuration.

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_incus"></a> [incus](#requirement\_incus) | ~> 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_incus"></a> [incus](#provider\_incus) | ~> 1.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [incus_instance.main](https://registry.terraform.io/providers/lxc/incus/latest/docs/resources/instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_init_user_data"></a> [cloud\_init\_user\_data](#input\_cloud\_init\_user\_data) | Raw cloud-init user-data content | `string` | n/a | yes |
| <a name="input_instances"></a> [instances](#input\_instances) | Configuration fot the incus instances to be deployed | <pre>map(object(<br>    {<br><br>      name    = string<br>      type    = optional(string, "container")<br>      image   = optional(string, "images:ubuntu/jammy/cloud")<br>      running = optional(bool, true)<br>      config  = optional(map(any), {})<br><br>  }))</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
