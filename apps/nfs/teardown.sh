#!/bin/bash

NFS_NAMESPACE="nfs-storage"

echo "Uninstalling NFS provisioner Helm chart..."
helm uninstall nfs-provisioner --namespace $NFS_NAMESPACE || true

echo "Deleting NFS namespace..."
kubectl delete -f apps/nfs/namespace.yaml --ignore-not-found
kubectl delete namespace $NFS_NAMESPACE --ignore-not-found

echo "NFS teardown complete!"
