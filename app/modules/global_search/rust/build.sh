#!/bin/bash
# Build script for global search WASM module

set -e

echo "🦀 Building global search WASM module..."

# Check if wasm-pack is installed
if ! command -v wasm-pack &> /dev/null; then
    echo "❌ wasm-pack not found. Installing..."
    cargo install wasm-pack
fi

# Build for web target
echo "📦 Building WASM..."
wasm-pack build --target web --out-dir ../lib/src/wasm --release

echo "✅ WASM module built successfully!"
echo "📍 Output: lib/src/wasm/"

# Show file sizes
echo ""
echo "📊 File sizes:"
ls -lh ../lib/src/wasm/*.wasm 2>/dev/null || echo "No WASM files found"

echo ""
echo "🎉 Build complete! You can now use the global search module in Dart."
