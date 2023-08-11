#!/bin/bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check --status

if [ $? -eq 0 ]; then
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    echo "kubectl installation successful."
else
    echo "kubectl installation failed."
    exit 1
fi

# Create SSH key (Ed25519) and copy to target machines
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# List of target server IPs
target_servers=("192.168.200.10" "192.168.200.11" "192.168.200.12" "192.168.200.13")

# Loop through target servers and copy SSH public key
for server_ip in "${target_servers[@]}"; do
    ssh-copy-id -i ~/.ssh/id_ed25519.pub nick@"$server_ip"
    if [ $? -eq 0 ]; then
        echo "SSH key copied to $server_ip successfully."
    else
        echo "Error: Unable to copy SSH key to $server_ip."
    fi
done

# Create .kube directory
mkdir -p ~/.kube

# Copy k3s.yaml from remote machine
scp nick@192.168.200.10:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Set KUBECONFIG environment variable
export KUBECONFIG=~/.kube/config

# Update k3s master node IP in k3s.yaml
sed -i "s/server:.*/server: https:\/\/192.168.200.100:6443/g" ~/.kube/config

echo "Setup completed."
