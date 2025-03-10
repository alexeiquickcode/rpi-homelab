#!/bin/bash

MINIO_USER="$1"
MINIO_PASS="$2"

# Configuration variables
MINIO_NAMESPACE="minio-distributed"

# Label Minio nodes
kubectl label node pi-master minio-node=minio-0
kubectl label node pi-1 minio-node=minio-1
kubectl label node pi-2 minio-node=minio-2
kubectl label node pi-3 minio-node=minio-3

# Apply the namespace manifest
kubectl apply -f apps/minio/namespace.yaml

echo "Creating MinIO secret..."
kubectl create secret generic minio-root \
    --namespace $MINIO_NAMESPACE \
    --from-literal=root-user=$MINIO_USER \
    --from-literal=root-password=$MINIO_PASS --dry-run=client -o yaml | kubectl apply -f -

# Create PV
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

# ------------------------------------------------------------------------------

echo "Deploying RClone CSI..."

# Just re-use the minio secret
ACCESS=$(kubectl get secret minio-root -n $MINIO_NAMESPACE -o jsonpath='{.data.root-user}' | base64 -d)
SECRET=$(kubectl get secret minio-root -n $MINIO_NAMESPACE -o jsonpath='{.data.root-password}' | base64 -d)

helm repo add cloudve https://github.com/CloudVE/helm-charts/raw/master
helm upgrade --install rclone csi-rclone \
             --repo "https://storage.googleapis.com/charts.wdr.io" \
             --namespace kube-system \
             --set params.remote="s3" \
             --set params.remotePath="jellyfin-media" \
             --set params.s3-provider="Minio" \
             --set-string params.s3-access-key-id="$ACCESS" \
             --set-string params.s3-secret-access-key="$SECRET" \
