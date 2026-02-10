# Kubernetes Bare-Metal Lab

Proyecto de laboratorio para desplegar un cluster Kubernetes bare-metal usando Incus/LXC como proveedor de virtualización.

## Stack

- **Infraestructura**: Terraform (multi-ambiente)
- **Virtualización**: Incus/LXC (contenedores tipo VM)
- **Configuración**: Ansible (CRI-O, Kubernetes, ArgoCD)
- **Secretos**: Infisical (self-hosted)
- **Monitoreo**: Prometheus + Grafana (kube-prometheus-stack)

## Estructura

```
.
├── terraform/
│   ├── environments/     # Root modules por ambiente
│   │   ├── dev/
│   │   └── staging/
│   ├── modules/          # Módulos reutilizables
│   │   ├── incus_instance/
│   │   ├── infisical/
│   │   └── storage_pool/
│   └── cloud-init/       # Templates cloud-init
├── ansible/
│   ├── roles/
│   │   ├── argocd/
│   │   ├── crio/
│   │   ├── monitoring/
│   │   └── geerlingguy.kubernetes/
│   ├── playbooks/
│   └── inventories/
├── scripts/
└── docs/
```

## Requisitos

- Terraform >= 1.10
- Helm 3.x
- Incus daemon + QEMU
- Ansible >= 2.10

## Uso

```bash
# Variables de entorno para Infisical
export TF_VAR_infisical_client_id="<client-id>"
export TF_VAR_infisical_client_secret="<client-secret>"

# Desplegar cluster dev
cd terraform/environments/dev
terraform init
terraform apply

# Desplegar cluster staging
cd terraform/environments/staging
terraform init
terraform apply

# Configurar nodos con Ansible
cd ansible
ansible-playbook -i inventories/dev playbooks/setup-k8s.yml

# Desplegar monitoreo (Prometheus + Grafana)
ansible-playbook -i inventories/development/hosts.yml playbooks/setup_monitoring.yml
```

## Monitoreo

El stack de monitoreo se despliega con el role `monitoring` (kube-prometheus-stack). Una vez desplegado:

- **Grafana**: `http://<worker-node-ip>:30300`
- **Prometheus**: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090`

## Módulos

| Módulo | Descripción |
|--------|-------------|
| [incus_instance](terraform/modules/incus_instance/) | Gestión de instancias Incus (VMs/contenedores) |
| [infisical](terraform/modules/infisical/) | Obtención de secretos desde Infisical |

## Herramientas de Desarrollo

```bash
# Instalar herramientas
./scripts/install-dev-tools.sh

# Activar hooks
pre-commit install
```
