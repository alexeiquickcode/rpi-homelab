#!/bin/bash
set -e
set -u

MINIO_NAMESPACE="minio-distributed"

echo "Removing all Minio resources"
helm uninstall rclone --namespace kube-system || true
helm uninstall minio --namespace $MINIO_NAMESPACE || true
kubectl delete pvc --namespace $MINIO_NAMESPACE --all --ignore-not-found
kubectl delete -f apps/minio/pv.yaml --ignore-not-found
kubectl delete secret minio-root --namespace $MINIO_NAMESPACE --ignore-not-found
kubectl delete namespace $MINIO_NAMESPACE --ignore-not-found

echo "MinIO teardown complete!"
