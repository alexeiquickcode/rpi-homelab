#!/bin/bash

NFS_NAMESPACE=nfs-storage

kubectl apply -f apps/nfs/namespace.yaml

# Install NFS provisioner Helm chart
echo "Installing NFS provisioner..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm upgrade --install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace $NFS_NAMESPACE \
    -f apps/nfs/values.yaml
