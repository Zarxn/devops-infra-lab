

# Script Setup Nodo (Debian based distributions)


OS=xUbuntu_22.04
CRIO_VERSION=v1.34
K8S_VERSION=1.34

#!/bin/bash
sudo apt update -y

# Instalar paquetes necesarios para usar el repo de K8S
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes Signing Key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add K8S Repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Add CRI-O Repo

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    sudo tee /etc/apt/sources.list.d/cri-o.list


# Update Apt

sudo apt update -y 

# Install CRI-O

sudo apt-get install -y cri-o

# Enable CRI-O

sudo systemctl enable crio --now

# Check to see CRI-O is installed properly
apt-cache policy cri-o

# Configure Networking

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Install and configure Kubeadm with the latest version of Kubernetes. For Worker Nodes, its not necessary to install kubectl.

sudo apt-get install -y kubelet kubeadm 
sudo apt-mark hold kubelet kubeadm 

# Enable kubelet

sudo systemctl enable --now kubelet

# To install a specific version of Kubernetes (not the latest), you can use the following...
# Example: sudo apt-get install -qy kubelet=1.25.5-00 kubectl=1.25.5-00 kubeadm=1.25.5-00

# You can see all Kubernetes versions available for Kubeadm like this: `apt list -a kubeadm`

# sudo apt-get install -qy kubelet=<version> kubectl=<version> kubeadm=<version>