# Incus Instance Module

Módulo para gestionar instancias Incus (contenedores o VMs) con cloud-init.

## Uso

```hcl
module "incus_instance" {
  source = "../../modules/incus_instance"

  instances = {
    "my-vm" = {
      name    = "my-vm"
      type    = "virtual-machine"
      image   = "images:ubuntu/jammy/cloud"
      running = true
      config = {
        "limits.memory" = "2GiB"
        "limits.cpu"    = "2"
      }
    }
  }

  cloud_init_user_data = file("cloud-init.yaml")
}
```

## Variables

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `instances` | `map(object)` | Configuración de instancias |
| `cloud_init_user_data` | `string` | Contenido cloud-init |

## Recursos creados

- `incus_instance.main` - Instancias Incus
