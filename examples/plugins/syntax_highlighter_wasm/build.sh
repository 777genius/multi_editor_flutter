#!/bin/bash
set -e

echo "🦀 Building syntax_highlighter_wasm plugin..."
echo "📐 Architecture: Clean Architecture + DDD + SOLID"

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo not found. Please install Rust: https://rustup.rs"
    exit 1
fi

# Check if wasm32-wasip1 target is installed (WASI support for Syntect)
if ! rustup target list | grep -q "wasm32-wasip1 (installed)"; then
    echo "📦 Installing wasm32-wasip1 target..."
    rustup target add wasm32-wasip1
fi

# Build for WASM with WASI support
echo "🔨 Compiling to WebAssembly (WASI)..."
cargo build --target wasm32-wasip1 --release

# Copy output
OUTPUT_DIR="build"
mkdir -p "$OUTPUT_DIR"

WASM_FILE="target/wasm32-wasip1/release/syntax_highlighter_wasm.wasm"
if [ -f "$WASM_FILE" ]; then
    cp "$WASM_FILE" "$OUTPUT_DIR/"

    # Get file size
    SIZE=$(du -h "$WASM_FILE" | cut -f1)
    echo "✅ Build complete!"
    echo "📦 Output: $OUTPUT_DIR/syntax_highlighter_wasm.wasm ($SIZE)"

    # Show architecture summary
    echo ""
    echo "📐 Architecture Summary:"
    echo "   - Domain Layer: Pure business logic"
    echo "   - Application Layer: Use cases"
    echo "   - Infrastructure Layer: Syntect integration (TextMate grammars)"
    echo "   - Presentation Layer: WASM exports"
    echo ""

    # Optional: optimize with wasm-opt if available
    if command -v wasm-opt &> /dev/null; then
        echo "⚡ Optimizing with wasm-opt..."
        wasm-opt -Oz "$OUTPUT_DIR/syntax_highlighter_wasm.wasm" -o "$OUTPUT_DIR/syntax_highlighter_wasm.opt.wasm"
        OPT_SIZE=$(du -h "$OUTPUT_DIR/syntax_highlighter_wasm.opt.wasm" | cut -f1)
        echo "✅ Optimized: $OUTPUT_DIR/syntax_highlighter_wasm.opt.wasm ($OPT_SIZE)"
    else
        echo "💡 Tip: Install wasm-opt for smaller binaries:"
        echo "   cargo install wasm-opt"
    fi

    echo ""
    echo "🚀 Ready to use! Run: dart run example.dart"
else
    echo "❌ Build failed: $WASM_FILE not found"
    exit 1
fi
