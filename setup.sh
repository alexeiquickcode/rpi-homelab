#!/bin/bash

set -e  # Stop script on error

BASE_DIR="$(dirname "$0")"

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

echo "Initializing Kubernetes setup..."

# Deploy services
bash "$BASE_DIR/ollama/setup.sh"
bash "$BASE_DIR/minio/setup.sh" $MINIO_USER $MINIO_PASS
bash "$BASE_DIR/nfs/setup.sh"
bash "$BASE_DIR/jellyfin/setup.sh"

echo "All services deployed successfully!"
