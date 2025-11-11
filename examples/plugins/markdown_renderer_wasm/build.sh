#!/bin/bash
set -e

echo "🦀 Building markdown_renderer_wasm plugin..."
echo "📐 Architecture: Clean Architecture + DDD + SOLID"

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo not found. Please install Rust: https://rustup.rs"
    exit 1
fi

# Check if wasm32-unknown-unknown target is installed
if ! rustup target list | grep -q "wasm32-unknown-unknown (installed)"; then
    echo "📦 Installing wasm32-unknown-unknown target..."
    rustup target add wasm32-unknown-unknown
fi

# Build for WASM
echo "🔨 Compiling to WebAssembly..."
cargo build --target wasm32-unknown-unknown --release

# Copy output
OUTPUT_DIR="build"
mkdir -p "$OUTPUT_DIR"

WASM_FILE="target/wasm32-unknown-unknown/release/markdown_renderer_wasm.wasm"
if [ -f "$WASM_FILE" ]; then
    cp "$WASM_FILE" "$OUTPUT_DIR/"

    # Get file size
    SIZE=$(du -h "$WASM_FILE" | cut -f1)
    echo "✅ Build complete!"
    echo "📦 Output: $OUTPUT_DIR/markdown_renderer_wasm.wasm ($SIZE)"

    # Show architecture summary
    echo ""
    echo "📐 Architecture Summary:"
    echo "   - Domain Layer: Pure business logic"
    echo "   - Application Layer: Use cases"
    echo "   - Infrastructure Layer: pulldown-cmark integration"
    echo "   - Presentation Layer: WASM exports"
    echo ""

    # Optional: optimize with wasm-opt if available
    if command -v wasm-opt &> /dev/null; then
        echo "⚡ Optimizing with wasm-opt..."
        wasm-opt -Oz "$OUTPUT_DIR/markdown_renderer_wasm.wasm" -o "$OUTPUT_DIR/markdown_renderer_wasm.opt.wasm"
        OPT_SIZE=$(du -h "$OUTPUT_DIR/markdown_renderer_wasm.opt.wasm" | cut -f1)
        echo "✅ Optimized: $OUTPUT_DIR/markdown_renderer_wasm.opt.wasm ($OPT_SIZE)"
    else
        echo "💡 Tip: Install wasm-opt for smaller binaries:"
        echo "   cargo install wasm-opt"
    fi

    echo ""
    echo "🚀 Ready to use!"
else
    echo "❌ Build failed: $WASM_FILE not found"
    exit 1
fi
