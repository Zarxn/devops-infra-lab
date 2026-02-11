# Monitoring Ansible Role

This role deploys [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) on a Kubernetes cluster using Helm.

Includes: Prometheus, Grafana, node-exporter, and kube-state-metrics.

## Requirements

- `kubernetes.core` Ansible collection
- `helm` installed on the control node
- A running Kubernetes cluster with `kubeconfig` configured on the control node.

## Role Variables

See `defaults/main.yml` for the full list of variables.

| Variable | Default | Description |
|----------|---------|-------------|
| `monitoring_chart_version` | "72.6.2" | Version of the kube-prometheus-stack Helm chart |
| `monitoring_namespace` | "monitoring" | Namespace to install the stack into |
| `monitoring_values` | (see defaults) | Values to pass to the Helm chart |

## Example Playbook

```yaml
- hosts: localhost
  vars:
    kubeconfig_path: "{{ ansible_user_dir }}/.kube/config"
  roles:
    - monitoring
```

## Access

- **Grafana**: `http://<worker-node-ip>:30300` (default credentials: `admin`/`admin`)
- **Prometheus**: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090`
- **Alertmanager**: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093`
