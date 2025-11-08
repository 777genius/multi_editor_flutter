#!/bin/bash

# Development script for Flutter IDE
# Starts LSP Bridge server and Flutter app concurrently

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Flutter IDE - Development Mode    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Stopping services...${NC}"
    kill $LSP_BRIDGE_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: Rust/Cargo not found. Please install Rust first.${NC}"
    echo -e "${YELLOW}Visit: https://rustup.rs/${NC}"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter not found. Please install Flutter first.${NC}"
    echo -e "${YELLOW}Visit: https://flutter.dev/docs/get-started/install${NC}"
    exit 1
fi

# Navigate to app directory
cd "$(dirname "$0")/.."

# Build Rust components if needed
if [ ! -f "modules/lsp_bridge/target/debug/lsp_bridge" ]; then
    echo -e "${YELLOW}Building Rust components (first time)...${NC}"
    make build-rust-dev
fi

# Start LSP Bridge server in background
echo -e "${GREEN}▶ Starting LSP Bridge server...${NC}"
echo -e "${YELLOW}  Listening on: ws://127.0.0.1:9999${NC}"
cd modules/lsp_bridge
RUST_LOG=info cargo run &
LSP_BRIDGE_PID=$!
cd ../..

# Wait for LSP Bridge to start
echo -e "${YELLOW}  Waiting for LSP Bridge to start...${NC}"
sleep 2

# Check if LSP Bridge is running
if ! kill -0 $LSP_BRIDGE_PID 2>/dev/null; then
    echo -e "${RED}Error: LSP Bridge failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}✓ LSP Bridge running (PID: $LSP_BRIDGE_PID)${NC}"
echo ""

# Start Flutter app
echo -e "${GREEN}▶ Starting Flutter IDE...${NC}"
echo -e "${YELLOW}  Hot reload: Press 'r'${NC}"
echo -e "${YELLOW}  Hot restart: Press 'R'${NC}"
echo -e "${YELLOW}  Quit: Press 'q' or Ctrl+C${NC}"
echo ""

flutter run -d linux

# Cleanup on exit
cleanup
