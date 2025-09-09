#!/usr/bin/env bash
# Unified build script for all project images (Java, Node.js, Python)
# Usage examples:
#   ./build.sh                    # build all images with tag 'latest'
#   TAG=v1 ./build.sh             # build all images with custom tag
#   TAG=$(git rev-parse --short HEAD) ./build.sh
#   PUSH=true REGISTRY=myrepo ./build.sh  # build and push to a registry (e.g., docker.io/username)
#   PLATFORMS=linux/amd64,linux/arm64 PUSH=true ./build.sh  # multi-arch build (requires buildx)

set -euo pipefail

# ---------- Configurable vars (can be overridden via environment) ---------- #
TAG="${TAG:-latest}"
JAVA_IMAGE="${JAVA_IMAGE:-cache-demo-java}"
NODE_IMAGE="${NODE_IMAGE:-cache-demo-node}"
PY_IMAGE="${PY_IMAGE:-cache-demo-python}"
REGISTRY="${REGISTRY:-}"              # e.g. docker.io/username or ghcr.io/owner
PUSH="${PUSH:-false}"                 # true to push images after build
PLATFORMS="${PLATFORMS:-}"            # e.g. linux/amd64,linux/arm64 (empty means normal single-arch build)
BUILD_ARGS=()                          # append with BUILD_ARGS+=(--build-arg NAME=VALUE)

# Enable Docker BuildKit for better caching
export DOCKER_BUILDKIT=1

# Prefix images with registry if provided
if [[ -n "$REGISTRY" ]]; then
  JAVA_IMAGE_FULL="$REGISTRY/$JAVA_IMAGE"
  NODE_IMAGE_FULL="$REGISTRY/$NODE_IMAGE"
  PY_IMAGE_FULL="$REGISTRY/$PY_IMAGE"
else
  JAVA_IMAGE_FULL="$JAVA_IMAGE"
  NODE_IMAGE_FULL="$NODE_IMAGE"
  PY_IMAGE_FULL="$PY_IMAGE"
fi

# Detect if we should use buildx (multi-arch)
USE_BUILDX=false
if [[ -n "$PLATFORMS" ]]; then
  USE_BUILDX=true
fi

function ensure_buildx() {
  if ! docker buildx ls >/dev/null 2>&1; then
    echo "[INFO] Creating default buildx builder" >&2
    docker buildx create --use --name multiarch-builder
  fi
}

function build_image() {
  local dir=$1
  local image=$2
  local tag=$3
  local label_base="org.opencontainers.image"
  local labels=(
    "--label" "$label_base.title=$image"
    "--label" "$label_base.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    "--label" "$label_base.revision=$(git rev-parse --short HEAD 2>/dev/null || echo 'na')"
    "--label" "$label_base.source=$(git config --get remote.origin.url 2>/dev/null || echo 'local')"
  )

  if $USE_BUILDX; then
    docker buildx build "${labels[@]}" "${BUILD_ARGS[@]}" \
      --platform "$PLATFORMS" \
      -t "$image:$tag" "$dir" $([[ "$PUSH" == true ]] && echo --push || echo --load)
  else
    docker build "${labels[@]}" "${BUILD_ARGS[@]}" -t "$image:$tag" "$dir"
    if [[ "$PUSH" == true ]]; then
      docker push "$image:$tag"
    fi
  fi
}

function main() {
  echo "==> Building images with tag: $TAG"
  if $USE_BUILDX; then
    ensure_buildx
  fi

  echo "-- Building Java image: $JAVA_IMAGE_FULL:$TAG"
  build_image "Java" "$JAVA_IMAGE_FULL" "$TAG"

  echo "-- Building Node.js image: $NODE_IMAGE_FULL:$TAG"
  build_image "NodeJs" "$NODE_IMAGE_FULL" "$TAG"

  echo "-- Building Python image: $PY_IMAGE_FULL:$TAG"
  build_image "Python" "$PY_IMAGE_FULL" "$TAG"

  echo "==> Done"
  if [[ "$PUSH" == true ]]; then
    echo "Images pushed:"
    printf '  %s:%s\n' "$JAVA_IMAGE_FULL" "$NODE_IMAGE_FULL" "$PY_IMAGE_FULL" | sed "N;N;"
  else
    echo "Local images available:"
    printf '  %s:%s\n' "$JAVA_IMAGE_FULL" "$TAG"
    printf '  %s:%s\n' "$NODE_IMAGE_FULL" "$TAG"
    printf '  %s:%s\n' "$PY_IMAGE_FULL" "$TAG"
  fi
}

main "$@"
