package parser

import (
	"errors"
	"fmt"
	"time"
)

var (
	// ErrUnsupportedLanguage is returned when the language is not supported
	ErrUnsupportedLanguage = errors.New("unsupported language")
)

// ParseSymbols parses source code and extracts symbols
func ParseSymbols(content string, language string) ([]Symbol, time.Duration, error) {
	start := time.Now()

	var symbols []Symbol
	var err error

	switch language {
	case LangDart:
		symbols, err = parseDart(content)
	case LangJavaScript:
		symbols, err = parseJavaScript(content)
	case LangTypeScript:
		symbols, err = parseTypeScript(content)
	case LangPython:
		symbols, err = parsePython(content)
	case LangGo:
		symbols, err = parseGo(content)
	case LangRust:
		symbols, err = parseRust(content)
	default:
		return nil, 0, fmt.Errorf("%w: %s", ErrUnsupportedLanguage, language)
	}

	duration := time.Since(start)

	if err != nil {
		return nil, duration, err
	}

	return symbols, duration, nil
}

// parseDart extracts symbols from Dart code
func parseDart(content string) ([]Symbol, error) {
	parser := &DartParser{content: content}
	return parser.Parse()
}

// parseJavaScript extracts symbols from JavaScript code
func parseJavaScript(content string) ([]Symbol, error) {
	// TODO: Implement JavaScript parser
	return []Symbol{}, nil
}

// parseTypeScript extracts symbols from TypeScript code
func parseTypeScript(content string) ([]Symbol, error) {
	// TODO: Implement TypeScript parser
	return []Symbol{}, nil
}

// parsePython extracts symbols from Python code
func parsePython(content string) ([]Symbol, error) {
	// TODO: Implement Python parser
	return []Symbol{}, nil
}

// parseGo extracts symbols from Go code
func parseGo(content string) ([]Symbol, error) {
	// TODO: Implement Go parser using go/parser
	return []Symbol{}, nil
}

// parseRust extracts symbols from Rust code
func parseRust(content string) ([]Symbol, error) {
	// TODO: Implement Rust parser
	return []Symbol{}, nil
}
