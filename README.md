
# cloud-init  

  - k3d kubeconfig merge demo-cluster --kubeconfig-switch-context
  - mkdir -p /home/$USER/.kube
  - mkdir ~/.kube && k3d kubeconfig merge demo-cluster --output ~/.kube/config