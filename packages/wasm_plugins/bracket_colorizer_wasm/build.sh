#!/bin/bash

# Build script for Bracket Pair Colorizer WASM plugin

set -e

echo "Building Bracket Pair Colorizer WASM plugin..."

# Check if rustc is installed
if ! command -v rustc &> /dev/null; then
    echo "Error: Rust is not installed. Please install Rust from https://rustup.rs/"
    exit 1
fi

# Check if wasm32-unknown-unknown target is installed
if ! rustup target list | grep -q "wasm32-unknown-unknown (installed)"; then
    echo "Installing wasm32-unknown-unknown target..."
    rustup target add wasm32-unknown-unknown
fi

# Run tests first
echo "Running tests..."
cargo test

# Build for WASM
echo "Compiling to WASM..."
cargo build --target wasm32-unknown-unknown --release

# Create build output directory
mkdir -p build

# Copy WASM file to build directory
cp target/wasm32-unknown-unknown/release/bracket_colorizer_wasm.wasm build/

# Check file size
WASM_SIZE=$(wc -c < build/bracket_colorizer_wasm.wasm)
echo "WASM file size: $(numfmt --to=iec-i --suffix=B $WASM_SIZE)"

# Optionally optimize with wasm-opt if available
if command -v wasm-opt &> /dev/null; then
    echo "Optimizing WASM with wasm-opt..."
    wasm-opt -Oz build/bracket_colorizer_wasm.wasm -o build/bracket_colorizer_wasm.optimized.wasm

    OPTIMIZED_SIZE=$(wc -c < build/bracket_colorizer_wasm.optimized.wasm)
    echo "Optimized WASM size: $(numfmt --to=iec-i --suffix=B $OPTIMIZED_SIZE)"

    REDUCTION=$((WASM_SIZE - OPTIMIZED_SIZE))
    PERCENT=$((REDUCTION * 100 / WASM_SIZE))
    echo "Size reduction: $(numfmt --to=iec-i --suffix=B $REDUCTION) ($PERCENT%)"

    # Use optimized version
    mv build/bracket_colorizer_wasm.optimized.wasm build/bracket_colorizer_wasm.wasm
else
    echo "wasm-opt not found. Skipping optimization."
    echo "Install with: npm install -g wasm-opt"
fi

echo "Build complete! WASM file: build/bracket_colorizer_wasm.wasm"
echo "Run tests with: cargo test"
