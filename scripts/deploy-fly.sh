#!/usr/bin/env bash
set -euo pipefail

# Deploy openclaw-agent to Fly.io registry
# Usage: ./scripts/deploy-fly.sh [--env beta|prod] [--tag <tag>] [extensions]
# Examples:
#   ./scripts/deploy-fly.sh                                                  # prod, auto-increment version
#   ./scripts/deploy-fly.sh --env beta                                       # beta, auto-increment version
#   ./scripts/deploy-fly.sh --tag 2026.4.10                                  # prod, explicit tag
#   ./scripts/deploy-fly.sh --env beta "telegram slack discord"              # beta, custom extensions
#   ./scripts/deploy-fly.sh "telegram slack discord whatsapp feishu"        # prod, custom extensions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV="prod"
EXTENSIONS=""
EXPLICIT_TAG=""

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
    --tag)
      EXPLICIT_TAG="$2"
      shift 2
      ;;
    *)
      EXTENSIONS="$1"
      shift
      ;;
  esac
done

EXTENSIONS="${EXTENSIONS:-telegram slack discord whatsapp feishu memory-core}"

# ── Resolve version tag ────────────────────────────────────────────────────────
# Read the current version from package.json (format: YYYY.M.PATCH)
CURRENT_VERSION="$(node -p "require('${REPO_ROOT}/package.json').version" 2>/dev/null || echo "")"

if [[ -n "${EXPLICIT_TAG}" ]]; then
  VERSION_TAG="${EXPLICIT_TAG}"
elif [[ -n "${CURRENT_VERSION}" ]]; then
  # Auto-increment the patch segment (last number after the final dot)
  MAJOR_MINOR="${CURRENT_VERSION%.*}"   # e.g. "2026.4"
  PATCH="${CURRENT_VERSION##*.}"        # e.g. "9"
  VERSION_TAG="${MAJOR_MINOR}.$((PATCH + 1))"
else
  # Fallback: use today's date as YYYY.M.D
  VERSION_TAG="$(date +%Y.%-m.%-d)"
fi

# ── Image names ────────────────────────────────────────────────────────────────
FLY_REGISTRY="registry.fly.io/clawpod-registry"

case "$ENV" in
  beta)
    GCR_IMAGE="gcr.io/chraftclaw/openclaw-agent:beta"
    FLY_IMAGE_VERSIONED="${FLY_REGISTRY}:beta-${VERSION_TAG}"
    FLY_IMAGE_FLOATING="${FLY_REGISTRY}:beta"
    ;;
  prod)
    GCR_IMAGE="gcr.io/chraftclaw/openclaw-agent:${VERSION_TAG}"
    FLY_IMAGE_VERSIONED="${FLY_REGISTRY}:${VERSION_TAG}"
    FLY_IMAGE_FLOATING="${FLY_REGISTRY}:latest"
    ;;
  *)
    echo "Error: unknown --env value '${ENV}'. Use 'beta' or 'prod'."
    exit 1
    ;;
esac

echo "==> Building Docker image..."
echo "    Env:        ${ENV}"
echo "    Version:    ${VERSION_TAG}"
echo "    Extensions: ${EXTENSIONS}"
echo "    Versioned:  ${FLY_IMAGE_VERSIONED}"
echo "    Floating:   ${FLY_IMAGE_FLOATING}"
echo ""

docker build \
  --platform linux/amd64 \
  --build-arg OPENCLAW_EXTENSIONS="${EXTENSIONS}" \
  -t "${GCR_IMAGE}" \
  "${REPO_ROOT}"

echo ""
echo "==> Tagging image for Fly.io registry..."
docker tag "${GCR_IMAGE}" "${FLY_IMAGE_VERSIONED}"
docker tag "${GCR_IMAGE}" "${FLY_IMAGE_FLOATING}"

echo "==> Pushing to Fly.io registry..."
docker push "${FLY_IMAGE_VERSIONED}"
docker push "${FLY_IMAGE_FLOATING}"

echo ""
echo "==> Done!"
echo "    Versioned tag: ${FLY_IMAGE_VERSIONED}"
echo "    Floating tag:  ${FLY_IMAGE_FLOATING}"
echo ""
echo "==> To roll out to all sandboxes:"
echo "    1. Update FLY_MACHINE_IMAGE=${FLY_IMAGE_VERSIONED} in fly-sandbox-service .env"
echo "    2. POST /api/v1/sandboxes/admin/upgrade-image?image=${FLY_IMAGE_VERSIONED}"
