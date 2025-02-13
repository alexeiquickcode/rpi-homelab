#!/bin/bash

apps/set -e  # Stop script on error

# Prompt for user and pass
if [ -z "$1" ]; then
    read -p "Enter MINIO username: " MINIO_USER
else
    MINIO_USER="$1"
fi

if [ -z "$2" ]; then
    read -sp "Enter MINIO password: " MINIO_PASS
    echo
else
    MINIO_PASS="$2"
fi

# Configuration variables
MINIO_NAMESPACE="minio-distributed"
NFS_STORAGE_NODE_IP="192.168.20.100"
NFS_NAMESPACE="nfs-storage"
JELLYFIN_NAMESPACE="jellyfin"
OLLAMA_NAMESPACE=ollama

# Create Kubernetes namespaces
echo "Creating namespaces..."
kubectl create namespace $MINIO_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $JELLYFIN_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NFS_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $OLLAMA_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply node taints
# kubectl taint nodes ubuntu01 nvidia.com/gpu=true:NoSchedule
# kubectl apply -f infra/service-accounts/apply-node-taints-sa.yaml -n kube-system
# kubectl apply -f infra/node-taints/cluster-role.yaml -n kube-system
# kubectl apply -f infra/node-taints/cluster-role-binding.yaml -n kube-system
# kubectl apply -f infra/node-taints/daemonset-gpu-taint.yaml -n kube-system

# Create MinIO secret (required for bitname chart) TODO: Can we just use the one in the folder?
echo "Creating MinIO secret..."
kubectl create secret generic minio-root \
    --namespace $MINIO_NAMESPACE \
    --from-literal=root-user=$MINIO_USER \
    --from-literal=root-password=$MINIO_PASS --dry-run=client -o yaml | kubectl apply -f -

echo "Creating PV for MinIO..."
kubectl apply -f apps/minio/pv.yaml

# Install MinIO Helm chart
echo "Installing MinIO..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install minio bitnami/minio \
    --namespace $MINIO_NAMESPACE \
    -f apps/minio/bitnami-values.yaml \
    --set auth.rootUser=$MINIO_USER \
    --set auth.rootPassword=$MINIO_PASS

# Install NFS provisioner Helm chart
echo "Installing NFS provisioner..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm upgrade --install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace $NFS_NAMESPACE \
    --set nfs.server=$NFS_STORAGE_NODE_IP \
    --set nfs.path=/srv/nfs

# Deploy RClone CSI if needed
echo "Deploying RClone CSI..."
kubectl apply -f infra/secrets/rclone-config-secret.yaml -n $JELLYFIN_NAMESPACE 
ACCESS=$(kubectl get secret rclone-config-secret -n $JELLYFIN_NAMESPACE -o jsonpath='{.data.rclone\.conf}' | base64 -d | grep '^access_key_id' | awk -F'= ' '{print $2}' | xargs)
SECRET=$(kubectl get secret rclone-config-secret -n $JELLYFIN_NAMESPACE -o jsonpath='{.data.rclone\.conf}' | base64 -d | grep '^secret_access_key' | awk -F'= ' '{print $2}' | xargs)

helm repo add cloudve https://github.com/CloudVE/helm-charts/raw/master
helm upgrade --install rclone csi-rclone \
             --repo "https://storage.googleapis.com/charts.wdr.io" \
             --namespace kube-system \
             --set params.remote="s3" \
             --set params.remotePath="jellyfin-media" \
             --set params.s3-provider="Minio" \
             --set-string params.s3-access-key-id="$ACCESS" \
             --set-string params.s3-secret-access-key="$SECRET" \

# TODO: Why are these default tolerations overriding my custom ones ??? EW
kubectl patch daemonset csi-nodeplugin-rclone \
    -n kube-system \
    --patch '{"spec": {"template": {"spec": {"tolerations": []}}}}'

# Apply remaining 
echo "Applying Jellyfin resources..."
# kubectl apply -k .
kubectl apply -f apps/jellyfin/media-pv.yaml
kubectl apply -f apps/jellyfin/pvc.yaml
kubectl apply -f apps/jellyfin/deployment.yaml
kubectl apply -f apps/ollama/deployment.yaml

# Setup NVIDIA GPU pluging
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --version 0.17.0 \
  --namespace nvidia-device-plugin \
  --create-namespace 
  # --set-file config.map.config=infra/plugins/nvidia/config0.yaml 

echo "Setup complete."
