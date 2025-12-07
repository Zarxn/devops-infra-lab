# Terragrunt Multi-Environment Infrastructure

Esta documentación explica cómo usar Terragrunt para gestionar múltiples ambientes (dev y staging) de clusters Kubernetes bare-metal utilizando Incus/LXC.

## Tabla de Contenidos

- [Introducción](#introducción)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Conceptos Clave de Terragrunt](#conceptos-clave-de-terragrunt)
- [Requisitos Previos](#requisitos-previos)
- [Comandos Básicos](#comandos-básicos)
- [Despliegue de Ambientes](#despliegue-de-ambientes)
- [Gestión de States](#gestión-de-states)
- [Troubleshooting](#troubleshooting)
- [Próximos Pasos](#próximos-pasos)

## Introducción

Este proyecto utiliza **Terragrunt** para implementar el principio **DRY (Don't Repeat Yourself)** en la gestión de infraestructura como código. En lugar de duplicar configuraciones de Terraform para cada ambiente, Terragrunt permite:

- Reutilizar módulos entre diferentes ambientes
- Aislar states por ambiente (dev, staging, prod)
- Gestionar configuraciones de forma jerárquica
- Simplificar workflows con comandos de alto nivel

## Estructura del Proyecto

```
terraform/
├── modules/                      # Módulos reutilizables de Terraform
│   ├── incus_instance/          # Módulo para crear instancias de Incus
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── storage_pool/            # Módulo para storage pools (WIP)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
├── cloud-init/                  # Templates de cloud-init
│   └── cloud-init.yaml
│
└── live/                        # Configuraciones "live" con Terragrunt
    ├── root.hcl                # Config raíz (backend, settings compartidos)
    │
    ├── dev/                     # Ambiente de DESARROLLO
    │   ├── k8s-cluster/
    │   │   ├── terragrunt.hcl  # Despliega cluster K8s de dev
    │   │   └── terraform.tfstate # State local persistente
    │   └── storage/
    │       └── terragrunt.hcl  # Storage pools de dev
    │
    └── staging/                 # Ambiente de STAGING
        ├── k8s-cluster/
        │   └── terragrunt.hcl  # Despliega cluster K8s de staging
        └── storage/
            └── terragrunt.hcl  # Storage pools de staging
```

### Jerarquía de Archivos Terragrunt

```
live/root.hcl                   ← Config raíz (backend, providers)
    ↓ (incluido por)
dev/k8s-cluster/terragrunt.hcl  ← Configuración del componente
```

## Conceptos Clave de Terragrunt

### 1. Include Blocks

Los bloques `include` permiten heredar configuración de archivos padre:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")  # Busca root.hcl en directorios padre
}
```

### 2. Funciones Helper

- `get_repo_root()`: Retorna el path al directorio raíz del repositorio
- `get_parent_terragrunt_dir()`: Path donde está el root.hcl padre
- `find_in_parent_folders()`: Busca archivo en directorios padre
- `path_relative_to_include()`: Path relativo desde el include

### 3. Backend Automático

En este caso, por temas de costos, se está usando un backend local. Lo recomendable es usar un backend remoto como S3.

Terragrunt genera automáticamente el `backend.tf` según la configuración en `remote_state`:

```hcl
remote_state {
  backend = "local"
  config = {
    # Guarda el state en el mismo directorio que el terragrunt.hcl
    path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"
  }
}
```

## Requisitos Previos

- **Terraform** v1.13.4 o superior
- **Terragrunt** v0.93.11 o superior
- **Incus/LXC** con daemon corriendo
- **QEMU** para VMs (si se usa type = "virtual-machine")
- **SSH Key** en `~/.ssh/id_rsa.pub`

### Verificar Instalación

```bash
# Verificar Terraform
terraform version

# Verificar Terragrunt
terragrunt --version

# Verificar Incus
incus version
```

## Comandos Básicos

### Comandos de Terragrunt vs Terraform

| Acción | Terraform | Terragrunt |
|--------|-----------|------------|
| Inicializar | `terraform init` | `terragrunt init` |
| Ver plan | `terraform plan` | `terragrunt plan` |
| Aplicar | `terraform apply` | `terragrunt apply` |
| Destruir | `terraform destroy` | `terragrunt destroy` |

### Comandos Específicos de Terragrunt

```bash
# Ejecutar comando en TODOS los componentes del ambiente (nuevo desde v0.88.0)
terragrunt run --all plan
terragrunt run --all apply
terragrunt run --all destroy

# Ver dependencias entre componentes (nuevo comando)
terragrunt dag graph

# Ver outputs de un componente
terragrunt output
```

## Despliegue de Ambientes

### Opción 1: Desplegar un Componente Específico

#### Dev - K8s Cluster

```bash
cd /home/vagrant/infra/terraform/live/dev/k8s-cluster

# Ver el plan
terragrunt plan

# Aplicar (crear las 3 VMs: 1 control-plane + 2 workers)
terragrunt apply

# Ver outputs
terragrunt output
```

#### Staging - K8s Cluster

```bash
cd /home/vagrant/infra/terraform/live/staging/k8s-cluster

terragrunt plan
terragrunt apply
```

### Opción 2: Desplegar TODO un Ambiente

```bash
# Desplegar TODOS los componentes de dev
cd /home/vagrant/infra/terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply

# Desplegar TODOS los componentes de staging
cd /home/vagrant/infra/terraform/live/staging
terragrunt run --all plan
terragrunt run --all apply
```

### Verificar Instancias Creadas

```bash
# Listar todas las instancias de Incus
incus list

# Filtrar por ambiente
incus list | grep dev-k8s
incus list | grep staging-k8s
```

### Destruir Infraestructura

```bash
# Destruir un componente específico
cd /home/vagrant/infra/terraform/live/dev/k8s-cluster
terragrunt destroy

# Destruir TODO un ambiente
cd /home/vagrant/infra/terraform/live/dev
terragrunt run --all destroy
```

## Gestión de States

### Ubicación de los States

Con la configuración actual, los archivos de state se almacenan en el mismo directorio que el archivo `terragrunt.hcl` del componente, de forma persistente (no están en el cache):

```bash
# State de dev k8s-cluster
terraform/live/dev/k8s-cluster/terraform.tfstate

# State de staging k8s-cluster
terraform/live/staging/k8s-cluster/terraform.tfstate
```

### Ver State de un Componente

```bash
cd /home/vagrant/infra/terraform/live/dev/k8s-cluster

# Listar recursos en el state
terragrunt state list

# Ver detalles de un recurso
terragrunt state show 'incus_instance.main["dev-k8s-cp01"]'
```

### Aislamiento de States

Cada ambiente (dev, staging) tiene su propio state completamente independiente. Esto significa:

- Cambios en dev NO afectan staging
- Es posible destruir dev sin afectar staging
- States separados = ambientes completamente aislados

## Troubleshooting

### Error: "SSH key not found"

**Problema**: No se encuentra la clave SSH en la ruta especificada

**Solución**:
```bash
# Verificar si existe
ls -la ~/.ssh/id_rsa.pub

# Si no existe, generarla
ssh-keygen -t rsa -b 4096 -C "email@example.com"

# O actualizar la ruta en terraform/live/dev/k8s-cluster/terragrunt.hcl
# Buscar la línea: ssh_public_key = file("/home/vagrant/.ssh/id_rsa.pub")
```

### Error: "Module not found"

**Problema**: Terragrunt no encuentra el módulo de Terraform

**Solución**:
```bash
# Verificar directorio actual
pwd

# Inicializar Terragrunt
terragrunt init

# Verificar que el módulo existe
ls -la /home/vagrant/infra/terraform/modules/incus_instance/
```

### Error: "Backend configuration changed"

**Problema**: Cambio en la configuración del backend (común después de actualizar `root.hcl`)

**Solución**:
```bash
# Limpiar cache y re-inicializar
cd /home/vagrant/infra/terraform/live/dev/k8s-cluster
rm -rf .terragrunt-cache
terragrunt init -reconfigure

# O si se desea migrar el state existente
terragrunt init -migrate-state
```

### Ver Logs Detallados

```bash
# Habilitar logs de debug de Terragrunt
export TERRAGRUNT_LOG_LEVEL=debug
terragrunt plan

# Ver logs de Terraform
export TF_LOG=DEBUG
terragrunt plan
```

### Limpiar Directorios .terragrunt-cache

Si se experimentan problemas, se puede limpiar el cache:

```bash
# Limpiar cache de un componente
cd /home/vagrant/infra/terraform/live/dev/k8s-cluster
rm -rf .terragrunt-cache

# Limpiar TODOS los caches
find /home/vagrant/infra/terraform/live -type d -name ".terragrunt-cache" -exec rm -rf {} +
```

## Configuración por Ambiente

### Recursos Asignados

| Ambiente | Control Plane | Workers (x2) | Total RAM | Total CPU |
|----------|---------------|--------------|-----------|--------------|
| **Dev** | 2GB, 2 CPU | 1.5GB, 1 CPU cada uno | ~5GB | ~4 CPUs |
| **Staging** | 2.5GB, 2 CPU | 2GB, 2 CPU cada uno | ~6.5GB | ~6 CPUs |

Estos valores se configuran en los archivos `terragrunt.hcl` de cada componente:
- `terraform/live/dev/k8s-cluster/terragrunt.hcl`
- `terraform/live/staging/k8s-cluster/terragrunt.hcl`

### Modificar Configuración

Para cambiar recursos, se debe editar el archivo `terragrunt.hcl` del componente correspondiente:

```hcl
# Ejemplo: terraform/live/dev/k8s-cluster/terragrunt.hcl
locals {
  cluster_config = {
    control_plane = {
      memory = "4GiB"  # Aumentar memoria
      cpu    = 4       # Aumentar CPUs
    }
    workers = {
      memory = "2GiB"
      cpu    = 2
    }
  }
}
```

Luego aplicar los cambios:

```bash
cd /home/vagrant/infra/terraform/live/dev/k8s-cluster
terragrunt apply
```

## Próximos Pasos

### 1. Completar el Módulo Storage Pool

El módulo `storage_pool` actualmente es un placeholder. Para completarlo:

1. Implementar `terraform/modules/storage_pool/main.tf`
2. Descomentar las configuraciones en `terraform/live/{dev,staging}/storage/terragrunt.hcl`
3. Aplicar el componente de storage

### 2. Agregar Outputs a los Módulos

Mejorar los outputs para facilitar la integración con Ansible:

```hcl
# terraform/modules/incus_instance/outputs.tf
output "instance_ips" {
  description = "Map of instance names to their IP addresses"
  value = {
    for name, instance in incus_instance.main : name => instance.ipv4_address
  }
}
```

### 3. Integrar con Ansible

Usar los outputs de Terragrunt para generar dinámicamente el inventario de Ansible:

```bash
# Generar lista de IPs
cd /home/vagrant/infra/terraform/live/dev/k8s-cluster
terragrunt output -json instance_ips > /tmp/dev-ips.json
```

### 4. Agregar Ambiente de Producción

Cuando se requiera, crear la estructura para producción:

```bash
mkdir -p /home/vagrant/infra/terraform/live/prod/{k8s-cluster,storage}
# Copiar estructura de staging y ajustar recursos
```

## Gestión de Secretos

Este proyecto utiliza **Infisical** (self-hosted) para la gestión centralizada de secretos. Infisical se ejecuta en el bastion host y proporciona:

- Almacenamiento encriptado de secretos
- Control de acceso por proyecto/ambiente
- Integración con Terragrunt
- UI web para gestión de secretos

Para más información, consultar la [documentación de gestión de secretos](../../docs/SECRETS_MANAGEMENT.md).

### Instalación Rápida

```bash
# Instalar Infisical en el bastion
./scripts/setup-infisical-bastion.sh

# Acceder a la UI
# http://localhost:8080
```

### Uso en Terragrunt

```hcl
locals {
  infisical_token = get_env("INFISICAL_TOKEN_DEV", "")

  ssh_public_key = run_cmd(
    "infisical", "secrets", "get", "SSH_PUBLIC_KEY",
    "--token", local.infisical_token,
    "--plain"
  )
}
```

## Recursos Adicionales

- [Documentación Oficial de Terragrunt](https://terragrunt.gruntwork.io/docs/)
- [Terraform Incus Provider](https://registry.terraform.io/providers/lxc/incus/latest/docs)
- [Infisical Documentation](https://infisical.com/docs)
