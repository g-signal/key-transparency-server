#!/bin/bash
# build-kt-server.sh - Automated build and push script for Key Transparency Server

set -e  # Exit on any error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration file path
CONFIG_FILE="config/build.properties"

# Read configuration using a safer method
print_status "Reading configuration from $CONFIG_FILE..."

# Function to read property from config file
read_property() {
    local key="$1"
    local config_file="$2"
    grep "^${key}=" "$config_file" 2>/dev/null | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Read docker.repo from config
DOCKER_REPO=$(read_property "docker.repo" "$CONFIG_FILE")
BUILD_PUSH=$(read_property "build.push" "$CONFIG_FILE")
BUILD_LATEST_TAG=$(read_property "build.latest_tag" "$CONFIG_FILE")

# Set defaults if not found
DOCKER_REPO=${DOCKER_REPO:-"gaolixin622/signal-kt-server"}
BUILD_PUSH=${BUILD_PUSH:-"true"}
BUILD_LATEST_TAG=${BUILD_LATEST_TAG:-"true"}

# Validate required config
if [[ -z "$DOCKER_REPO" ]]; then
    print_error "docker.repo not found in config file"
    exit 1
fi

# Extract version information
print_status "Extracting version information..."
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "dev-$(date +%Y%m%d%H%M%S)")
FULL_VERSION=$(git describe --tags --dirty --always 2>/dev/null || echo "unknown")
GO_VERSION=$(grep "^go " go.mod | cut -d' ' -f2)

print_status "Build Information:"
echo "  Version: $VERSION"
echo "  Full Version: $FULL_VERSION"
echo "  Go Version: $GO_VERSION"
echo "  Docker Repo: $DOCKER_REPO"

# Build Docker image
print_status "Building Docker image..."
docker build . \
  --file docker/Dockerfile \
  --build-arg GO_VERSION="$GO_VERSION" \
  --build-arg APP_VERSION="$VERSION" \
  --tag "$DOCKER_REPO:$VERSION" \
  --tag "$DOCKER_REPO:$FULL_VERSION"

# Add latest tag if configured
if [[ "$BUILD_LATEST_TAG" == "true" ]]; then
    docker tag "$DOCKER_REPO:$VERSION" "$DOCKER_REPO:latest"
    print_status "Tagged as latest"
fi

print_status "Build completed successfully!"

# Push to registry if configured
if [[ "$BUILD_PUSH" == "true" ]]; then
    print_status "Pushing images to registry..."

    # Check if logged in to Docker
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker daemon not running"
        exit 1
    fi

    # Push version tag
    print_status "Pushing $DOCKER_REPO:$VERSION..."
    docker push "$DOCKER_REPO:$VERSION"

    # Push full version tag
    print_status "Pushing $DOCKER_REPO:$FULL_VERSION..."
    docker push "$DOCKER_REPO:$FULL_VERSION"

    # Push latest tag if configured
    if [[ "$BUILD_LATEST_TAG" == "true" ]]; then
        print_status "Pushing $DOCKER_REPO:latest..."
        docker push "$DOCKER_REPO:latest"
    fi

    print_status "All images pushed successfully!"
    echo "  - $DOCKER_REPO:$VERSION"
    echo "  - $DOCKER_REPO:$FULL_VERSION"
    [[ "$BUILD_LATEST_TAG" == "true" ]] && echo "  - $DOCKER_REPO:latest"
else
    print_warning "Push disabled in configuration"
    print_status "Built images:"
    echo "  - $DOCKER_REPO:$VERSION"
    echo "  - $DOCKER_REPO:$FULL_VERSION"
    [[ "$BUILD_LATEST_TAG" == "true" ]] && echo "  - $DOCKER_REPO:latest"
fi

print_status "Script completed successfully!"
