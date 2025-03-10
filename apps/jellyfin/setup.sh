#!/bin/bash

kubectl apply -f apps/jellyfin/namespace.yaml
kubectl apply -f apps/jellyfin/pv-media.yaml
kubectl apply -f apps/jellyfin/pvc.yaml
kubectl apply -f apps/jellyfin/deployment.yaml
