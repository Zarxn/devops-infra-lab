# Infraestructure Inventory
## Terraform Modules
| Module | Variables | Outputs |
| ------ | --------- | ------- |
| storage_pool | 0 | 0 |
| incus_instance | 2 | 0 |
| infisical | 4 | 1 |
## Ansible Roles
### geerlingguy.docker
- main.yml
- docker-users.yml
- setup-Suse.yml
- setup-RedHat.yml
- setup-Debian.yml
- docker-compose.yml
### geerlingguy.kubernetes
- main.yml
- node-setup.yml
- sysctl-setup.yml
- control-plane-setup.yml
- kubelet-setup.yml
- setup-RedHat.yml
- setup-Debian.yml
### argocd
- main.yml
### crio
- main.yml
- prerequisites.yml
- repository.yml
- install.yml
