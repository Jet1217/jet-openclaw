#!/usr/bin/env bash
set -euo pipefail

# Deploy openclaw-agent to Fly.io registry
# Usage: ./scripts/deploy-fly.sh [--env beta|prod] [extensions]
# Examples:
#   ./scripts/deploy-fly.sh                                                  # prod, default extensions
#   ./scripts/deploy-fly.sh --env beta                                       # beta, default extensions
#   ./scripts/deploy-fly.sh --env beta "telegram slack discord"              # beta, custom extensions
#   ./scripts/deploy-fly.sh "telegram slack discord whatsapp feishu"        # prod, custom extensions

ENV="prod"
EXTENSIONS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV="$2"
      shift 2
      ;;
    --beta)
      ENV="beta"
      shift
      ;;
    --prod)
      ENV="prod"
      shift
      ;;
    *)
      EXTENSIONS="$1"
      shift
      ;;
  esac
done

EXTENSIONS="${EXTENSIONS:-telegram slack discord whatsapp feishu memory-core}"

case "$ENV" in
  beta)
    GCR_IMAGE="gcr.io/chraftclaw/openclaw-agent:beta"
    FLY_IMAGE="registry.fly.io/clawpod-registry:beta"
    ;;
  prod)
    GCR_IMAGE="gcr.io/chraftclaw/openclaw-agent:social"
    FLY_IMAGE="registry.fly.io/clawpod-registry:latest"
    ;;
  *)
    echo "Error: unknown --env value '${ENV}'. Use 'beta' or 'prod'."
    exit 1
    ;;
esac

echo "==> Building Docker image..."
echo "    Env:        ${ENV}"
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
