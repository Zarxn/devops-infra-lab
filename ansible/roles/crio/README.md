# Ansible Role: CRI-O

Installs and configures [CRI-O](https://cri-o.io/) container runtime for Kubernetes on Debian/Ubuntu systems.

## Requirements

- Ansible >= 2.10
- Target systems: Ubuntu 22.04 (Jammy), Ubuntu 20.04 (Focal), or Debian 11/12
- Root or sudo access on target hosts

## Role Variables

Available variables with their default values (see `defaults/main.yml`):

```yaml
# CRI-O version (should match Kubernetes minor version)
crio_version: "v1.34"

# Enable CRI-O service on boot
crio_service_enabled: true

# Start CRI-O service after installation
crio_service_state: started

# Kernel modules required for container networking
crio_kernel_modules:
  - overlay
  - br_netfilter

# Sysctl settings for Kubernetes networking
crio_sysctl_settings:
  net.bridge.bridge-nf-call-iptables: 1
  net.bridge.bridge-nf-call-ip6tables: 1
  net.ipv4.ip_forward: 1
```

### Supported CRI-O Versions

| CRI-O Version | Kubernetes Version | Status |
|---------------|-------------------|--------|
| v1.35         | v1.35.x           | Latest |
| v1.34         | v1.34.x           | Stable |
| v1.33         | v1.33.x           | Stable |
| v1.32         | v1.32.x           | Stable |
| v1.31         | v1.31.x           | EOL    |

## Dependencies

None.

## Example Playbook

```yaml
---
- name: Install CRI-O on Kubernetes nodes
  hosts: all
  become: true
  roles:
    - role: crio
      vars:
        crio_version: "v1.34"
```

### Using with geerlingguy.kubernetes

```yaml
---
- name: Setup Kubernetes cluster with CRI-O
  hosts: all
  become: true

  pre_tasks:
    - name: Install CRI-O container runtime
      ansible.builtin.include_role:
        name: crio
      vars:
        crio_version: "v1.34"

  roles:
    - role: geerlingguy.kubernetes
      vars:
        kubernetes_version: "1.34"
        kubernetes_cri_socket: "unix:///var/run/crio/crio.sock"
```

## Tags

- `crio` - All CRI-O related tasks
- `prerequisites` - Kernel modules and sysctl configuration
- `repository` - Repository setup and GPG key installation
- `install` - Package installation and service configuration

## License

MIT

## Author

DevOps Portfolio Project
