#!/bin/bash
# Development script for Symbol Navigator WASM Plugin

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PLUGIN_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Show help
show_help() {
    cat <<EOF
Symbol Navigator WASM Plugin - Development Script

Usage: ./dev.sh [command]

Commands:
    help        Show this help
    deps        Download dependencies
    test        Run tests
    build       Build WASM plugin
    install     Build and install to Flutter project
    clean       Clean build artifacts
    fmt         Format code
    lint        Run linters
    watch       Watch for changes and rebuild
    bench       Run benchmarks
    all         Run all checks (fmt, lint, test, build)

Examples:
    ./dev.sh test           # Run tests
    ./dev.sh build          # Build WASM
    ./dev.sh all            # Full check before commit

EOF
}

# Download dependencies
cmd_deps() {
    log_info "Downloading Go dependencies..."
    go mod download
    go mod tidy
    log_info "Dependencies ready"
}

# Run tests
cmd_test() {
    log_info "Running tests..."
    go test ./... -v -cover
    log_info "Tests passed"
}

# Format code
cmd_fmt() {
    log_info "Formatting Go code..."
    go fmt ./...
    log_info "Code formatted"
}

# Lint code
cmd_lint() {
    log_info "Running linters..."

    if command -v golangci-lint >/dev/null 2>&1; then
        golangci-lint run
    else
        log_warn "golangci-lint not installed, using go vet"
        go vet ./...
    fi

    log_info "Linting complete"
}

# Build WASM
cmd_build() {
    log_info "Building WASM plugin..."
    make build
    log_info "Build complete"
}

# Build and install
cmd_install() {
    log_info "Building and installing WASM plugin..."
    make build
    make install
    log_info "Installed successfully"
}

# Clean
cmd_clean() {
    log_info "Cleaning build artifacts..."
    make clean
    log_info "Clean complete"
}

# Run benchmarks
cmd_bench() {
    log_info "Running benchmarks..."
    go test ./... -bench=. -benchmem
    log_info "Benchmarks complete"
}

# Watch for changes
cmd_watch() {
    log_info "Watching for changes..."

    if ! command -v fswatch >/dev/null 2>&1; then
        log_error "fswatch not installed"
        echo "Install: brew install fswatch (macOS) or apt install inotify-tools (Linux)"
        exit 1
    fi

    log_info "Press Ctrl+C to stop"

    fswatch -o . -e ".*" -i "\\.go$" | while read f; do
        clear
        echo "=== Change detected, rebuilding... ==="
        cmd_build || log_error "Build failed"
    done
}

# Run all checks
cmd_all() {
    log_info "Running all checks..."

    cmd_fmt
    cmd_lint
    cmd_test
    cmd_build

    log_info "All checks passed ✓"
}

# Main
COMMAND="${1:-help}"

case "$COMMAND" in
    help)
        show_help
        ;;
    deps)
        cmd_deps
        ;;
    test)
        cmd_test
        ;;
    fmt)
        cmd_fmt
        ;;
    lint)
        cmd_lint
        ;;
    build)
        cmd_build
        ;;
    install)
        cmd_install
        ;;
    clean)
        cmd_clean
        ;;
    bench)
        cmd_bench
        ;;
    watch)
        cmd_watch
        ;;
    all)
        cmd_all
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
