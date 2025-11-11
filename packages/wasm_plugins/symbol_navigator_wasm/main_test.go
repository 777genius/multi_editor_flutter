package main

import (
	"testing"
	"unsafe"

	"github.com/vmihailenco/msgpack/v5"

	"github.com/777genius/multi_editor_flutter/symbol_navigator_wasm/parser"
)

func TestGetManifest(t *testing.T) {
	result := get_manifest()

	// Unpack result
	ptr := uint32(result >> 32)
	length := uint32(result & 0xFFFFFFFF)

	if ptr == 0 || length == 0 {
		t.Fatal("get_manifest returned null")
	}

	// Read data
	data := readMemory(ptr, length)

	// Should be valid JSON
	if len(data) == 0 {
		t.Error("Manifest data is empty")
	}

	t.Logf("Manifest size: %d bytes", len(data))
	t.Logf("Manifest: %s", string(data))
}

func TestParseSymbols(t *testing.T) {
	// Prepare request
	req := ParseRequest{
		Content:  "class TestClass { void method() {} }",
		Language: "dart",
		FilePath: "test.dart",
	}

	reqData, err := msgpack.Marshal(req)
	if err != nil {
		t.Fatalf("Failed to marshal request: %v", err)
	}

	// Allocate memory
	ptr := alloc(uint32(len(reqData)))
	if ptr == 0 {
		t.Fatal("alloc failed")
	}

	// Copy request data
	dest := (*[1 << 30]byte)(unsafe.Pointer(uintptr(ptr)))[:len(reqData):len(reqData)]
	copy(dest, reqData)

	// Call parse_symbols
	result := parse_symbols(ptr, uint32(len(reqData)))

	// Unpack result
	resultPtr := uint32(result >> 32)
	resultLen := uint32(result & 0xFFFFFFFF)

	if resultPtr == 0 || resultLen == 0 {
		t.Fatal("parse_symbols returned null")
	}

	// Read response
	respData := readMemory(resultPtr, resultLen)

	// Unmarshal response
	var resp ParseResponse
	if err := msgpack.Unmarshal(respData, &resp); err != nil {
		t.Fatalf("Failed to unmarshal response: %v", err)
	}

	t.Logf("Parsed %d symbols in %dms", len(resp.Symbols), resp.ParseDurationMs)
	t.Logf("Statistics: %+v", resp.Statistics)

	// Check we got symbols
	if len(resp.Symbols) == 0 {
		t.Error("Expected at least one symbol")
	}

	// Check symbol structure
	if len(resp.Symbols) > 0 {
		symbol := resp.Symbols[0]
		if symbol.Name == "" {
			t.Error("Symbol name is empty")
		}
		if symbol.Kind == "" {
			t.Error("Symbol kind is empty")
		}
		t.Logf("First symbol: %s (%s)", symbol.Name, symbol.Kind)
	}
}

func TestParseSymbolsInvalidLanguage(t *testing.T) {
	req := ParseRequest{
		Content:  "some code",
		Language: "invalid_language",
		FilePath: "test.txt",
	}

	reqData, err := msgpack.Marshal(req)
	if err != nil {
		t.Fatalf("Failed to marshal request: %v", err)
	}

	ptr := alloc(uint32(len(reqData)))
	dest := (*[1 << 30]byte)(unsafe.Pointer(uintptr(ptr)))[:len(reqData):len(reqData)]
	copy(dest, reqData)

	result := parse_symbols(ptr, uint32(len(reqData)))

	// Should return 0 on error
	if result != 0 {
		t.Error("Expected error for invalid language, but got result")
	}
}

func TestAllocDealloc(t *testing.T) {
	// Test alloc
	ptr := alloc(1024)
	if ptr == 0 {
		t.Error("alloc returned null pointer")
	}

	// Test dealloc (no-op, but should not crash)
	dealloc(ptr)
}

func TestPackResult(t *testing.T) {
	testCases := []struct {
		name string
		data []byte
		err  error
		want uint64
	}{
		{
			name: "valid data",
			data: []byte("test"),
			err:  nil,
			want: 0, // Will be non-zero (actual ptr + len)
		},
		{
			name: "empty data",
			data: []byte{},
			err:  nil,
			want: 0,
		},
		{
			name: "error",
			data: nil,
			err:  parser.ErrUnsupportedLanguage,
			want: 0,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := packResult(tc.data, tc.err)

			if tc.err != nil {
				if result != 0 {
					t.Error("Expected 0 on error")
				}
				return
			}

			if len(tc.data) > 0 {
				if result == 0 {
					t.Error("Expected non-zero result for valid data")
				}

				// Unpack and verify
				ptr := uint32(result >> 32)
				length := uint32(result & 0xFFFFFFFF)

				if length != uint32(len(tc.data)) {
					t.Errorf("Expected length %d, got %d", len(tc.data), length)
				}

				if ptr == 0 {
					t.Error("Pointer is null")
				}
			}
		})
	}
}

func BenchmarkGetManifest(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = get_manifest()
	}
}

func BenchmarkParseSymbols(b *testing.B) {
	req := ParseRequest{
		Content:  "class TestClass { void method() {} }",
		Language: "dart",
		FilePath: "test.dart",
	}

	reqData, _ := msgpack.Marshal(req)
	ptr := alloc(uint32(len(reqData)))
	dest := (*[1 << 30]byte)(unsafe.Pointer(uintptr(ptr)))[:len(reqData):len(reqData)]
	copy(dest, reqData)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = parse_symbols(ptr, uint32(len(reqData)))
	}
}
