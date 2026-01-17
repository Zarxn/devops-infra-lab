# Kubernetes Bare-Metal Lab

Proyecto de laboratorio para desplegar un cluster Kubernetes bare-metal usando Incus/LXC como proveedor de virtualización.

## Stack

- **Infraestructura**: Terraform + Terragrunt (multi-ambiente)
- **Virtualización**: Incus/LXC (contenedores tipo VM)
- **Configuración**: Ansible (CRI-O, Kubernetes, ArgoCD)
- **Secretos**: Infisical (self-hosted)

## Estructura

```
.
├── terraform/
│   ├── modules/          # Módulos reutilizables
│   │   ├── incus_instance/
│   │   └── storage_pool/
│   └── live/             # Configuraciones por ambiente (Terragrunt)
│       ├── dev/
│       └── staging/
├── ansible/
│   ├── roles/            # Roles de configuración
│   │   ├── argocd/
│   │   ├── crio/
│   │   └── geerlingguy.kubernetes/
│   ├── playbooks/
│   └── inventories/
├── scripts/              # Scripts de instalación
└── docs/                 # Documentación adicional
```

## Requisitos

- Terraform >= 1.13
- Terragrunt >= 0.93
- Incus daemon + QEMU
- Ansible >= 2.10

## Uso Rápido

```bash
# Desplegar cluster dev
cd terraform/live/dev/k8s-cluster
terragrunt apply

# Configurar nodos con Ansible
cd ansible
ansible-playbook -i inventories/dev playbooks/setup-k8s.yml
```

## Documentación

- [Terragrunt Multi-Ambiente](terraform/live/README.md)
- [Gestión de Secretos](docs/INFISICAL_SETUP.md)

## Herramientas de Desarrollo

El proyecto incluye pre-commit hooks para:
- Linting (tflint, ansible-lint)
- Seguridad (checkov)
- Documentación automática (terraform-docs)

```bash
# Instalar herramientas
./scripts/install-dev-tools.sh

# Activar hooks
pre-commit install
```
