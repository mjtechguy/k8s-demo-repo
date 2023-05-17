#!/bin/sh

# Color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Prompt user for deployment name
read -p "Enter the deployment name (all lower case, no spaces): " DEPLOYMENT_NAME

# Remove Old Docker Installation
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install Docker
echo -e "${GREEN}Installing Docker...${NC}"
if ! (sudo apt-get update && sudo apt upgrade -y && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common haveged bash-completion &&
  sudo mkdir -m 0755 -p /etc/apt/keyrings &&
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
  sudo apt-get update &&
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
); then
  echo -e "${RED}Failed to install Docker.${NC}"
  exit 1
fi

# Install k3d
echo -e "${GREEN}Installing k3d...${NC}"
if ! wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.4.4 bash; then
  echo -e "${RED}Failed to install k3d.${NC}"
  exit 1
fi

# Install Helm3
echo -e "${GREEN}Installing Helm3...${NC}"
if ! curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; then
  echo -e "${RED}Failed to install Helm3.${NC}"
  exit 1
fi

# Install Kubectl
echo -e "${GREEN}Installing Kubectl...${NC}"
if ! curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; then
  echo -e "${RED}Failed to install Kubectl.${NC}"
  exit 1
fi

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Make dir for k3d
echo -e "${GREEN}Creating directory for k3d...${NC}"
if ! sudo mkdir -p /server/k3d; then
  echo -e "${RED}Failed to create directory for k3d.${NC}"
  exit 1
fi

# Deploy K3d Cluster
echo -e "${GREEN}Deploying K3d Cluster...${NC}"
if ! k3d cluster create "$DEPLOYMENT_NAME" --servers 3 --agents 3 -v /server/k3d@agent:0,1,2 -v /server/k3d@server:0,1,2 --k3s-arg "--no-deploy=traefik@server:*"; then
  echo -e "${RED}Failed to deploy K3d Cluster.${NC}"
  exit 1
fi

# Exporting Kubeconfig
echo -e "${GREEN}Exporting Kubeconfig...${NC}"
if ! k3d kubeconfig merge "$DEPLOYMENT_NAME" --kubeconfig-switch-context &&
  cp ~/.kube/config ~/.kube/config.bak && true &&
  cp ~/.kube/k3d-"$DEPLOYMENT_NAME"/kubeconfig.yaml ~/.kube/config
; then
  echo -e "${RED}Failed to export Kubeconfig.${NC}"
  exit 1
fi

# Install ingress-nginx Ingress Controller
echo -e "${GREEN}Installing ingress-nginx Ingress Controller...${NC}"
if ! helm upgrade --install ingress-nginx ingress-nginx --version 4.4.2 --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.replicaCount=1; then
  echo -e "${RED}Failed to install ingress-nginx Ingress Controller.${NC}"
  exit 1
fi

# Confirm Installation
echo -e "${GREEN}#################################${NC}"
echo -e "${GREEN}Installation completed.${NC}"
echo -e "${GREEN}Please run `kubectl get nodes` to confirm that the cluster is up and running.${NC}"
echo -e "${GREEN}#################################${NC}"