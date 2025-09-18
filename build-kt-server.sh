#!/bin/bash
# build-kt-server.sh

# 自动提取版本
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "dev-$(git rev-parse --short HEAD)")
GO_VERSION=$(grep "^go " go.mod | cut -d' ' -f2)

echo "Building Key Transparency Server..."
echo "Version: $VERSION"
echo "Go Version: $GO_VERSION"

  # 构建镜像
docker build . \
  --file docker/Dockerfile \
  --build-arg GO_VERSION=$GO_VERSION \
  --tag gaolixin622/signal-kt-server:$VERSION \
  --tag gaolixin622/signal-kt-server:latest

echo "Build completed: gaolixin622/signal-kt-server:$VERSION"
