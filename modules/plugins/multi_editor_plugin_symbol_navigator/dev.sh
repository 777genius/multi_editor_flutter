#!/bin/bash
# Development script for Symbol Navigator Dart Plugin

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
Symbol Navigator Dart Plugin - Development Script

Usage: ./dev.sh [command]

Commands:
    help        Show this help
    deps        Get dependencies
    gen         Generate freezed files
    test        Run tests
    fmt         Format code
    analyze     Run analyzer
    clean       Clean generated files
    watch       Watch and regenerate freezed files
    all         Run all checks (fmt, analyze, gen, test)
    wasm        Build WASM plugin

Examples:
    ./dev.sh gen            # Generate freezed files
    ./dev.sh test           # Run tests
    ./dev.sh all            # Full check before commit

EOF
}

# Get dependencies
cmd_deps() {
    log_info "Getting Flutter dependencies..."
    flutter pub get
    log_info "Dependencies ready"
}

# Generate freezed files
cmd_gen() {
    log_info "Generating freezed files..."
    flutter pub run build_runner build --delete-conflicting-outputs
    log_info "Generation complete"
}

# Run tests
cmd_test() {
    log_info "Running tests..."
    flutter test
    log_info "Tests passed"
}

# Format code
cmd_fmt() {
    log_info "Formatting Dart code..."
    dart format .
    log_info "Code formatted"
}

# Analyze code
cmd_analyze() {
    log_info "Analyzing Dart code..."
    flutter analyze
    log_info "Analysis complete"
}

# Clean
cmd_clean() {
    log_info "Cleaning generated files..."
    flutter clean
    rm -f lib/**/*.g.dart lib/**/*.freezed.dart
    log_info "Clean complete"
}

# Watch for changes
cmd_watch() {
    log_info "Watching for changes and regenerating..."
    flutter pub run build_runner watch --delete-conflicting-outputs
}

# Build WASM plugin
cmd_wasm() {
    log_info "Building WASM plugin..."
    cd ../../../packages/wasm_plugins/symbol_navigator_wasm
    make build
    make install
    cd -
    log_info "WASM plugin built and installed"
}

# Run all checks
cmd_all() {
    log_info "Running all checks..."

    cmd_deps
    cmd_fmt
    cmd_analyze
    cmd_gen
    cmd_test

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
    gen)
        cmd_gen
        ;;
    test)
        cmd_test
        ;;
    fmt)
        cmd_fmt
        ;;
    analyze)
        cmd_analyze
        ;;
    clean)
        cmd_clean
        ;;
    watch)
        cmd_watch
        ;;
    wasm)
        cmd_wasm
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
