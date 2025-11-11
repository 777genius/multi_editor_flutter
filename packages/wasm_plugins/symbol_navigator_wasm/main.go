package main

import (
	"encoding/json"
	"fmt"
	"sync"
	"unsafe"

	"github.com/vmihailenco/msgpack/v5"

	"github.com/777genius/multi_editor_flutter/packages/wasm_plugins/symbol_navigator_wasm/parser"
)

// ============================================================================
// WASM Memory Management
// ============================================================================

var (
	// Global registry to pin allocated memory and prevent GC collection
	allocRegistry = make(map[uint32][]byte)
	allocMutex    sync.Mutex
	nextAllocID   uint32 = 1
)

// Allocate memory that can be accessed from the host
// Returns a stable pointer that won't be garbage collected
//
//export alloc
func alloc(size uint32) uint32 {
	allocMutex.Lock()
	defer allocMutex.Unlock()

	// Allocate a byte slice of the requested size
	buf := make([]byte, size)

	// Get pointer to the first byte
	ptr := uint32(uintptr(unsafe.Pointer(&buf[0])))

	// Store in registry to prevent GC collection
	allocRegistry[ptr] = buf

	return ptr
}

// Free memory by removing from registry (allows GC to collect)
//
//export dealloc
func dealloc(ptr uint32) {
	allocMutex.Lock()
	defer allocMutex.Unlock()

	// Remove from registry to allow GC
	delete(allocRegistry, ptr)
}

// ============================================================================
// Plugin Manifest
// ============================================================================

type PluginManifest struct {
	ID          string   `json:"id" msgpack:"id"`
	Name        string   `json:"name" msgpack:"name"`
	Version     string   `json:"version" msgpack:"version"`
	Description string   `json:"description" msgpack:"description"`
	Author      string   `json:"author" msgpack:"author"`
	Capabilities []string `json:"capabilities" msgpack:"capabilities"`
}

// Get plugin manifest
//
//export get_manifest
func get_manifest() uint64 {
	manifest := PluginManifest{
		ID:          "wasm.symbol-navigator",
		Name:        "Symbol Navigator (WASM)",
		Version:     "0.1.0",
		Description: "Tree-sitter powered symbol parser supporting multiple languages",
		Author:      "Editor Team",
		Capabilities: []string{
			"parse.dart",
			"parse.javascript",
			"parse.typescript",
			"parse.python",
			"parse.go",
			"parse.rust",
		},
	}

	// Serialize to JSON
	data, err := json.Marshal(manifest)
	if err != nil {
		return packResult(nil, fmt.Errorf("failed to marshal manifest: %w", err))
	}

	return packResult(data, nil)
}

// ============================================================================
// Symbol Parsing
// ============================================================================

// ParseRequest represents a symbol parsing request
type ParseRequest struct {
	Content  string `msgpack:"content"`
	Language string `msgpack:"language"`
	FilePath string `msgpack:"file_path"`
}

// ParseResponse represents the parsing result
type ParseResponse struct {
	Symbols        []parser.Symbol       `msgpack:"symbols"`
	Language       string                `msgpack:"language"`
	ParseDurationMs int64                 `msgpack:"parse_duration_ms"`
	Statistics     map[string]int        `msgpack:"statistics"`
}

// Parse source code and extract symbols
//
//export parse_symbols
func parse_symbols(ptr uint32, length uint32) uint64 {
	// Read input data from WASM memory
	data := readMemory(ptr, length)

	// Deserialize request
	var req ParseRequest
	if err := msgpack.Unmarshal(data, &req); err != nil {
		return packResult(nil, fmt.Errorf("failed to unmarshal request: %w", err))
	}

	// Parse symbols using tree-sitter
	symbols, duration, err := parser.ParseSymbols(req.Content, req.Language)
	if err != nil {
		return packResult(nil, fmt.Errorf("parse error: %w", err))
	}

	// Calculate statistics
	stats := make(map[string]int)
	for _, sym := range symbols {
		stats[sym.Kind]++
		countChildStats(sym.Children, stats)
	}

	// Build response
	response := ParseResponse{
		Symbols:        symbols,
		Language:       req.Language,
		ParseDurationMs: duration.Milliseconds(),
		Statistics:     stats,
	}

	// Serialize response
	result, err := msgpack.Marshal(response)
	if err != nil {
		return packResult(nil, fmt.Errorf("failed to marshal response: %w", err))
	}

	return packResult(result, nil)
}

// Helper to count child statistics recursively
func countChildStats(children []parser.Symbol, stats map[string]int) {
	for _, child := range children {
		stats[child.Kind]++
		countChildStats(child.Children, stats)
	}
}

// ============================================================================
// Helper Functions
// ============================================================================

// Read data from WASM memory
func readMemory(ptr uint32, length uint32) []byte {
	// Create a slice that points to WASM memory
	return (*[1 << 30]byte)(unsafe.Pointer(uintptr(ptr)))[:length:length]
}

// Pack result as (ptr, len) in uint64
// Format: upper 32 bits = pointer, lower 32 bits = length
// Returns 0 on error (with error logged internally)
// Pins the data in memory to prevent GC collection
func packResult(data []byte, err error) uint64 {
	if err != nil {
		// In production, log this error properly
		fmt.Printf("ERROR: %v\n", err)
		return 0
	}

	if len(data) == 0 {
		return 0
	}

	allocMutex.Lock()
	defer allocMutex.Unlock()

	// Get pointer to data
	ptr := uint32(uintptr(unsafe.Pointer(&data[0])))
	length := uint32(len(data))

	// Store in registry to prevent GC collection
	// The host is responsible for calling dealloc() when done with this data
	allocRegistry[ptr] = data

	// Pack into uint64: (ptr << 32) | length
	return (uint64(ptr) << 32) | uint64(length)
}

// ============================================================================
// Main (required for WASM)
// ============================================================================

func main() {
	// This is required for WASM compilation but won't be called
	// The host will call exported functions directly
}
