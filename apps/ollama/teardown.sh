#!/bin/bash
set -e
set -u

OLLAMA_NAMESPACE="ollama"

echo "Deleting Nvidia device plugin..."
kubectl delete -f infra/plugins/nvidia/runtime-class.yaml --ignore-not-found
kubectl delete -f infra/plugins/nvidia/nvidia-device-plugin.yaml --ignore-not-found

echo "Deleting Ollama resources..."
kubectl delete -f apps/ollama/deployment.yaml --ignore-not-found
kubectl delete -f apps/ollama/namespace.yaml --ignore-not-found

echo "Deleting Ollama namespace..."
kubectl delete namespace $OLLAMA_NAMESPACE --ignore-not-found

echo "Ollama teardown complete!"
