#!/bin/bash

NAMESPACE_MINIO="minio-distributed"
NAMESPACE_JELLYFIN="jellyfin"
NAMESPACE_NFS="nfs-storage"
# NAMESPACE_OLLAMA="ollama"

echo "Deleting deployments..."
kubectl delete deployment jellyfin -n $NAMESPACE_JELLYFIN
# kubectl delete daemonset apply-node-taints -n kube-system

echo "Uninstalling Helm charts..."
helm uninstall minio --namespace $NAMESPACE_MINIO
helm uninstall nfs-provisioner --namespace $NAMESPACE_NFS
helm uninstall rclone --namespace kube-system
helm uninstall nvdp --namespace nvidia-device-plugin

echo "Deleting resources..."
kubectl delete pvc --all -n $NAMESPACE_MINIO
kubectl delete pvc --all -n $NAMESPACE_JELLYFIN

# WARN: Not removing minio namespace or pvs 
# kubectl delete pv --all
# kubectl delete namespace $NAMESPACE_MINIO $NAMESPACE_JELLYFIN $NAMESPACE_NFS 

kubectl delete namespace $NAMESPACE_JELLYFIN $NAMESPACE_NFS
