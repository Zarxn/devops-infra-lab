# Infisical Module

Módulo para obtener secretos desde Infisical con soporte para data sources y recursos efímeros.

## Uso

```hcl
module "secrets" {
  source = "../../modules/infisical"

  workspace_id = "project-id"
  env_slug     = "dev"
  folder_path  = "/"

  # Secretos persistentes (quedan en state como sensitive)
  secrets = [
    { name = "SSH_PUBLIC_KEY" }
  ]

  # Secretos efímeros (nunca en state)
  ephemeral_secrets = [
    { name = "DB_PASSWORD" }
  ]
}

# Uso de secretos
resource "example" "this" {
  ssh_key  = module.secrets.secrets["SSH_PUBLIC_KEY"]
  password = module.secrets.ephemeral_secrets["DB_PASSWORD"]
}
```

## Variables

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `workspace_id` | `string` | ID del proyecto en Infisical |
| `env_slug` | `string` | Ambiente (dev, staging, prod) |
| `folder_path` | `string` | Ruta de carpeta en Infisical |
| `secrets` | `list(object)` | Secretos persistentes |
| `ephemeral_secrets` | `list(object)` | Secretos efímeros |

## Outputs

| Output | Tipo | Descripción |
|--------|------|-------------|
| `secrets` | `map(string)` | Mapa de secretos persistentes |
| `ephemeral_secrets` | `map(string)` | Mapa de secretos efímeros |

## Autenticación

Configurar mediante variables de Terraform o entorno:

```bash
export TF_VAR_infisical_client_id="<client-id>"
export TF_VAR_infisical_client_secret="<client-secret>"
```
