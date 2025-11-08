#!/bin/bash

# Production build script for Flutter IDE

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Flutter IDE - Production Build     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Navigate to app directory
cd "$(dirname "$0")/.."

# Build Rust components in release mode
echo -e "${GREEN}▶ Building Rust components (release)...${NC}"
make build-rust

# Generate code
echo -e "${GREEN}▶ Generating Dart code...${NC}"
make codegen

# Run tests
echo -e "${GREEN}▶ Running tests...${NC}"
flutter test || {
    echo -e "${RED}Tests failed! Fix tests before building production.${NC}"
    exit 1
}

# Build for target platform
PLATFORM=${1:-linux}

case $PLATFORM in
    linux)
        echo -e "${GREEN}▶ Building for Linux...${NC}"
        flutter build linux --release
        echo -e "${GREEN}✓ Build complete: build/linux/x64/release/bundle/${NC}"
        ;;
    web)
        echo -e "${GREEN}▶ Building for Web...${NC}"
        flutter build web --release --web-renderer canvaskit
        echo -e "${GREEN}✓ Build complete: build/web/${NC}"
        ;;
    macos)
        echo -e "${GREEN}▶ Building for macOS...${NC}"
        flutter build macos --release
        echo -e "${GREEN}✓ Build complete: build/macos/Build/Products/Release/${NC}"
        ;;
    windows)
        echo -e "${GREEN}▶ Building for Windows...${NC}"
        flutter build windows --release
        echo -e "${GREEN}✓ Build complete: build/windows/runner/Release/${NC}"
        ;;
    *)
        echo -e "${RED}Unknown platform: $PLATFORM${NC}"
        echo -e "${YELLOW}Usage: $0 [linux|web|macos|windows]${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Production Build Ready!        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
