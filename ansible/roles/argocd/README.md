# ArgoCD Ansible Role

This role installs ArgoCD on a Kubernetes cluster using Helm.

## Requirements

- `kubernetes.core` Ansible collection
- `helm` installed on the control node (handled by the role)
- A running Kubernetes cluster with `kubeconfig` configured on the control node.

## Role Variables

See `defaults/main.yml` for the full list of variables.

| Variable | Default | Description |
|----------|---------|-------------|
| `argocd_chart_version` | "7.7.11" | Version of the ArgoCD Helm chart |
| `argocd_namespace` | "argocd" | Namespace to install ArgoCD into |
| `argocd_values` | (see defaults) | Values to pass to the Helm chart |

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - argocd
```
