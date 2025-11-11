package parser

import (
	"regexp"
	"strings"
)

// DartParser parses Dart source code to extract symbols
type DartParser struct {
	content string
	lines   []string
}

// Parse extracts all symbols from Dart code
func (p *DartParser) Parse() ([]Symbol, error) {
	p.lines = strings.Split(p.content, "\n")

	var symbols []Symbol

	// Parse top-level declarations
	symbols = append(symbols, p.parseClasses()...)
	symbols = append(symbols, p.parseMixins()...)
	symbols = append(symbols, p.parseExtensions()...)
	symbols = append(symbols, p.parseEnums()...)
	symbols = append(symbols, p.parseTopLevelFunctions()...)
	symbols = append(symbols, p.parseTopLevelVariables()...)

	return symbols, nil
}

// parseClasses extracts class declarations
func (p *DartParser) parseClasses() []Symbol {
	var symbols []Symbol

	// Match: class ClassName, abstract class ClassName
	classRegex := regexp.MustCompile(`(?m)^\s*(abstract\s+)?class\s+(\w+)`)

	matches := classRegex.FindAllStringSubmatchIndex(p.content, -1)
	for _, match := range matches {
		isAbstract := match[2] != -1 // abstract keyword captured
		className := p.content[match[4]:match[5]]

		startOffset := match[0]
		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		// Find class body
		bodyStart := strings.Index(p.content[startOffset:], "{")
		if bodyStart == -1 {
			continue
		}
		bodyStart += startOffset

		bodyEnd := p.findMatchingBrace(bodyStart)
		if bodyEnd == -1 {
			bodyEnd = len(p.content)
		}

		endLine := p.getLineNumber(bodyEnd)
		endCol := p.getColumnNumber(bodyEnd, endLine)

		kind := KindClass
		if isAbstract {
			kind = KindAbstractClass
		}

		// Parse class members
		classBody := p.content[bodyStart:bodyEnd]
		children := p.parseClassMembers(classBody, className, bodyStart)

		symbol := Symbol{
			Name: className,
			Kind: kind,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     endLine,
				EndColumn:   endCol,
				StartOffset: startOffset,
				EndOffset:   bodyEnd,
			},
			Children: children,
		}

		symbols = append(symbols, symbol)
	}

	return symbols
}

// parseClassMembers extracts methods and fields from a class body
func (p *DartParser) parseClassMembers(classBody string, className string, bodyOffset int) []Symbol {
	var members []Symbol

	// Parse methods (simplified)
	methodRegex := regexp.MustCompile(`(?m)^\s*(?:static\s+)?(?:[\w<>]+\s+)?(\w+)\s*\([^)]*\)\s*(?:async\s*)?{`)
	matches := methodRegex.FindAllStringSubmatchIndex(classBody, -1)

	for _, match := range matches {
		methodName := classBody[match[2]:match[3]]

		// Skip constructor (same name as class)
		isConstructor := methodName == className

		startOffset := bodyOffset + match[0]
		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		// Find method end
		methodStart := bodyOffset + match[0]
		braceStart := strings.Index(classBody[match[0]:], "{")
		if braceStart == -1 {
			continue
		}
		braceStart += methodStart

		braceEnd := p.findMatchingBrace(braceStart)
		if braceEnd == -1 {
			braceEnd = len(p.content)
		}

		endLine := p.getLineNumber(braceEnd)
		endCol := p.getColumnNumber(braceEnd, endLine)

		kind := KindMethod
		if isConstructor {
			kind = KindConstructor
		}

		member := Symbol{
			Name:   methodName,
			Kind:   kind,
			Parent: className,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     endLine,
				EndColumn:   endCol,
				StartOffset: startOffset,
				EndOffset:   braceEnd,
			},
		}

		members = append(members, member)
	}

	// Parse fields (simplified)
	fieldRegex := regexp.MustCompile(`(?m)^\s*(?:final|const|static|late)?\s*(?:[\w<>]+)\s+(\w+)\s*[=;]`)
	fieldMatches := fieldRegex.FindAllStringSubmatchIndex(classBody, -1)

	for _, match := range fieldMatches {
		fieldName := classBody[match[2]:match[3]]

		startOffset := bodyOffset + match[0]
		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		// Find end (semicolon or equals)
		endOffset := startOffset + (match[1] - match[0])
		endLine := p.getLineNumber(endOffset)
		endCol := p.getColumnNumber(endOffset, endLine)

		member := Symbol{
			Name:   fieldName,
			Kind:   KindField,
			Parent: className,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     endLine,
				EndColumn:   endCol,
				StartOffset: startOffset,
				EndOffset:   endOffset,
			},
		}

		members = append(members, member)
	}

	return members
}

// parseMixins extracts mixin declarations
func (p *DartParser) parseMixins() []Symbol {
	var symbols []Symbol

	mixinRegex := regexp.MustCompile(`(?m)^\s*mixin\s+(\w+)`)
	matches := mixinRegex.FindAllStringSubmatchIndex(p.content, -1)

	for _, match := range matches {
		name := p.content[match[2]:match[3]]
		startOffset := match[0]
		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		symbol := Symbol{
			Name: name,
			Kind: KindMixin,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     startLine,
				EndColumn:   startCol + len(name),
				StartOffset: startOffset,
				EndOffset:   match[1],
			},
		}

		symbols = append(symbols, symbol)
	}

	return symbols
}

// parseExtensions extracts extension declarations
func (p *DartParser) parseExtensions() []Symbol {
	var symbols []Symbol

	extRegex := regexp.MustCompile(`(?m)^\s*extension\s+(\w+)`)
	matches := extRegex.FindAllStringSubmatchIndex(p.content, -1)

	for _, match := range matches {
		name := p.content[match[2]:match[3]]
		startOffset := match[0]
		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		symbol := Symbol{
			Name: name,
			Kind: KindExtension,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     startLine,
				EndColumn:   startCol + len(name),
				StartOffset: startOffset,
				EndOffset:   match[1],
			},
		}

		symbols = append(symbols, symbol)
	}

	return symbols
}

// parseEnums extracts enum declarations
func (p *DartParser) parseEnums() []Symbol {
	var symbols []Symbol

	enumRegex := regexp.MustCompile(`(?m)^\s*enum\s+(\w+)`)
	matches := enumRegex.FindAllStringSubmatchIndex(p.content, -1)

	for _, match := range matches {
		name := p.content[match[2]:match[3]]
		startOffset := match[0]
		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		symbol := Symbol{
			Name: name,
			Kind: KindEnum,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     startLine,
				EndColumn:   startCol + len(name),
				StartOffset: startOffset,
				EndOffset:   match[1],
			},
		}

		symbols = append(symbols, symbol)
	}

	return symbols
}

// parseTopLevelFunctions extracts top-level function declarations
func (p *DartParser) parseTopLevelFunctions() []Symbol {
	var symbols []Symbol

	// Simplified: match function declarations not inside classes
	funcRegex := regexp.MustCompile(`(?m)^(?:[\w<>]+\s+)?(\w+)\s*\([^)]*\)\s*(?:async\s*)?{`)
	matches := funcRegex.FindAllStringSubmatchIndex(p.content, -1)

	for _, match := range matches {
		name := p.content[match[2]:match[3]]
		startOffset := match[0]

		// Skip if inside class (rough check)
		if p.isInsideClass(startOffset) {
			continue
		}

		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		symbol := Symbol{
			Name: name,
			Kind: KindFunction,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     startLine,
				EndColumn:   startCol + len(name),
				StartOffset: startOffset,
				EndOffset:   match[1],
			},
		}

		symbols = append(symbols, symbol)
	}

	return symbols
}

// parseTopLevelVariables extracts top-level variable declarations
func (p *DartParser) parseTopLevelVariables() []Symbol {
	var symbols []Symbol

	varRegex := regexp.MustCompile(`(?m)^(?:final|const|var)\s+(\w+)\s*=`)
	matches := varRegex.FindAllStringSubmatchIndex(p.content, -1)

	for _, match := range matches {
		name := p.content[match[2]:match[3]]
		startOffset := match[0]

		if p.isInsideClass(startOffset) {
			continue
		}

		startLine := p.getLineNumber(startOffset)
		startCol := p.getColumnNumber(startOffset, startLine)

		symbol := Symbol{
			Name: name,
			Kind: KindVariable,
			Location: Location{
				StartLine:   startLine,
				StartColumn: startCol,
				EndLine:     startLine,
				EndColumn:   startCol + len(name),
				StartOffset: startOffset,
				EndOffset:   match[1],
			},
		}

		symbols = append(symbols, symbol)
	}

	return symbols
}

// Helper: Get line number from byte offset
func (p *DartParser) getLineNumber(offset int) int {
	line := 0
	currentOffset := 0

	for i, lineContent := range p.lines {
		lineLen := len(lineContent) + 1 // +1 for newline
		if currentOffset+lineLen > offset {
			return i
		}
		currentOffset += lineLen
		line = i
	}

	return line
}

// Helper: Get column number from byte offset and line
func (p *DartParser) getColumnNumber(offset int, line int) int {
	lineStart := 0
	for i := 0; i < line; i++ {
		lineStart += len(p.lines[i]) + 1 // +1 for newline
	}
	return offset - lineStart
}

// Helper: Find matching closing brace
func (p *DartParser) findMatchingBrace(openPos int) int {
	depth := 0

	for i := openPos; i < len(p.content); i++ {
		// Skip strings (with proper escape handling)
		if i < len(p.content)-1 {
			// Check for raw strings (r"..." or r'...')
			if p.content[i] == 'r' && (p.content[i+1] == '"' || p.content[i+1] == '\'') {
				i = p.skipRawString(i)
				continue
			}
			// Check for triple-quoted strings (""" or ''')
			if i < len(p.content)-2 {
				if p.content[i:i+3] == `"""` || p.content[i:i+3] == "'''" {
					i = p.skipTripleQuotedString(i)
					continue
				}
			}
		}

		// Check for regular strings (with escape handling)
		if p.content[i] == '"' || p.content[i] == '\'' {
			i = p.skipString(i)
			continue
		}

		// Skip line comments (//)
		if i < len(p.content)-1 && p.content[i:i+2] == "//" {
			i = p.skipLineComment(i)
			continue
		}

		// Skip block comments (/* */)
		if i < len(p.content)-1 && p.content[i:i+2] == "/*" {
			i = p.skipBlockComment(i)
			continue
		}

		// Track braces
		if p.content[i] == '{' {
			depth++
		} else if p.content[i] == '}' {
			depth--
			if depth == 0 {
				return i
			}
		}
	}

	return -1
}

// Helper: Skip string literal with escape handling
func (p *DartParser) skipString(start int) int {
	quote := p.content[start]
	i := start + 1

	for i < len(p.content) {
		if p.content[i] == '\\' {
			// Skip escaped character
			i += 2
			continue
		}
		if p.content[i] == quote {
			return i
		}
		i++
	}
	return i
}

// Helper: Skip raw string literal (no escape processing)
func (p *DartParser) skipRawString(start int) int {
	// start points to 'r', next char is the quote
	quote := p.content[start+1]
	i := start + 2

	for i < len(p.content) {
		if p.content[i] == quote {
			return i
		}
		i++
	}
	return i
}

// Helper: Skip triple-quoted string literal
func (p *DartParser) skipTripleQuotedString(start int) int {
	quote := p.content[start : start+3]
	i := start + 3

	for i < len(p.content)-2 {
		if p.content[i:i+3] == quote {
			return i + 2
		}
		i++
	}
	return i
}

// Helper: Skip line comment
func (p *DartParser) skipLineComment(start int) int {
	i := start + 2
	for i < len(p.content) && p.content[i] != '\n' {
		i++
	}
	return i
}

// Helper: Skip block comment
func (p *DartParser) skipBlockComment(start int) int {
	i := start + 2
	for i < len(p.content)-1 {
		if p.content[i:i+2] == "*/" {
			return i + 1
		}
		i++
	}
	return i
}

// Helper: Check if offset is inside a class definition
func (p *DartParser) isInsideClass(offset int) bool {
	// Find last class declaration before offset
	classRegex := regexp.MustCompile(`class\s+\w+`)
	matches := classRegex.FindAllStringIndex(p.content[:offset], -1)

	if len(matches) == 0 {
		return false
	}

	lastClassPos := matches[len(matches)-1][0]

	// Find the opening brace of the class
	bodyStartRel := strings.Index(p.content[lastClassPos:], "{")
	if bodyStartRel == -1 {
		return false
	}

	bodyStart := lastClassPos + bodyStartRel

	// Check if offset is after the opening brace
	if offset <= bodyStart {
		return false
	}

	// Find the matching closing brace
	bodyEnd := p.findMatchingBrace(bodyStart)
	if bodyEnd == -1 {
		// No closing brace found, assume we're inside
		return true
	}

	// Verify offset is before the closing brace
	return offset < bodyEnd
}
