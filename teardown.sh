#!/bin/bash

set -e  # Stop script on error

BASE_DIR="$(dirname "$0")"

# Deploy services
bash "$BASE_DIR/ollama/teardown.sh"
bash "$BASE_DIR/minio/teardown.sh"
bash "$BASE_DIR/nfs/teardown.sh"
bash "$BASE_DIR/jellyfin/teardown.sh"
