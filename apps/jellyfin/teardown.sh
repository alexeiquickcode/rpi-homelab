#!/bin/bash
set -e
set -u

JELLYFIN_NAMESPACE="jellyfin"

echo "Deleting Jellyfin resources..."
kubectl delete -f apps/jellyfin/deployment.yaml --ignore-not-found
kubectl delete -f apps/jellyfin/pvc.yaml --ignore-not-found
kubectl delete -f apps/jellyfin/media-pv.yaml --ignore-not-found
kubectl delete -f apps/jellyfin/namespace.yaml --ignore-not-found

echo "Deleting Jellyfin namespace..."
kubectl delete namespace $JELLYFIN_NAMESPACE --ignore-not-found

echo "Jellyfin teardown complete!"
