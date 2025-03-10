#!/bin/bash

# Nvidia device plugin (no helm)
kubectl apply -f infra/plugins/nvidia/runtime-class.yaml 
kubectl apply -f infra/plugins/nvidia/nvidia-device-plugin.yaml 

# Ollama
kubectl apply -f apps/ollama/namespace.yaml
kubectl apply -f apps/ollama/deployment.yaml

# TODO: If we want to use helm

# Setup NVIDIA GPU pluging
# helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
# helm repo update
# helm upgrade -i nvdp nvdp/nvidia-device-plugin \
#   --version 0.17.0 \
#   --namespace nvidia-device-plugin \
#   --create-namespace 
#   --set-file config.map.config=infra/plugins/nvidia/config0.yaml 
