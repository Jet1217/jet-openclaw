#!/usr/bin/env bash
set -euo pipefail

# Deploy openclaw-agent:social to Fly.io registry
# Usage: ./scripts/deploy-fly.sh [extensions]
# Example: ./scripts/deploy-fly.sh "telegram slack discord whatsapp feishu memory-core"

EXTENSIONS="${1:-telegram slack discord whatsapp feishu memory-core}"
GCR_IMAGE="gcr.io/chraftclaw/openclaw-agent:social"
FLY_IMAGE="registry.fly.io/clawpod-registry:latest"

echo "==> Building Docker image..."
echo "    Extensions: ${EXTENSIONS}"
echo "    Target:     ${GCR_IMAGE}"
echo ""

docker build \
  --platform linux/amd64 \
  --build-arg OPENCLAW_EXTENSIONS="${EXTENSIONS}" \
  -t "${GCR_IMAGE}" \
  .

echo ""
echo "==> Tagging image for Fly.io registry..."
docker tag "${GCR_IMAGE}" "${FLY_IMAGE}"

echo "==> Pushing to Fly.io registry..."
docker push "${FLY_IMAGE}"

echo ""
echo "==> Done! Image pushed to ${FLY_IMAGE}"
