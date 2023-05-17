#!/bin/sh

# Color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Prompt user for deployment name
read -p "Enter the deployment name (all lower case, no spaces): " DEPLOYMENT_NAME

# List components to be removed
echo -e "${RED}The following components will be removed:"
echo -e "${RED}- K3d Cluster: $DEPLOYMENT_NAME"
echo -e "${RED}- Kubectl configuration"
echo -e "${RED}- Helm3"
echo -e "${RED}- k3d"
echo -e "${RED}- Docker${NC}"

# Confirmation prompt
read -p "Are you sure you want to continue with the cleanup? Type 'yes' to confirm: " CONFIRMATION

# Function to execute a command and check for failure
execute_command() {
  if ! "$@"; then
    echo -e "${RED}Step failed: $@${NC}"
    exit 1
  fi
}

# Delete K3d Cluster
echo -e "${GREEN}Deleting K3d Cluster...${NC}"
execute_command k3d cluster delete "$DEPLOYMENT_NAME"

# Remove Kubectl configuration
echo -e "${GREEN}Removing Kubectl configuration...${NC}"
execute_command rm -rf ~/.kube/config

# Uninstall Helm3
echo -e "${GREEN}Uninstalling Helm3...${NC}"
execute_command helm --namespace kube-system uninstall helm-install

# Uninstall k3d
echo -e "${GREEN}Uninstalling k3d...${NC}"
execute_command sudo rm $(which k3d)
execute_command sudo rm -rf /usr/local/bin/k3d

# Uninstall Docker
echo -e "${GREEN}Uninstalling Docker...${NC}"
execute_command sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
execute_command sudo rm -rf /var/lib/docker
execute_command sudo rm -rf /etc/docker
execute_command sudo groupdel docker
execute_command sudo rm -rf /var/run/docker.sock

echo -e "${GREEN}Cleanup completed.${NC}"
