package parser

import (
	"testing"
)

func TestParseDartClass(t *testing.T) {
	content := `
class MyClass {
  String name;
  int age;

  void greet() {
    print('Hello');
  }
}
`

	symbols, err := parseDart(content)
	if err != nil {
		t.Fatalf("Failed to parse: %v", err)
	}

	if len(symbols) != 1 {
		t.Fatalf("Expected 1 symbol, got %d", len(symbols))
	}

	classSymbol := symbols[0]
	if classSymbol.Name != "MyClass" {
		t.Errorf("Expected class name 'MyClass', got '%s'", classSymbol.Name)
	}

	if classSymbol.Kind != KindClass {
		t.Errorf("Expected kind 'class_declaration', got '%s'", classSymbol.Kind)
	}

	// Should have 3 children: 2 fields + 1 method
	if len(classSymbol.Children) < 1 {
		t.Errorf("Expected at least 1 child, got %d", len(classSymbol.Children))
	}
}

func TestParseDartAbstractClass(t *testing.T) {
	content := `abstract class Animal {
  void makeSound();
}`

	symbols, err := parseDart(content)
	if err != nil {
		t.Fatalf("Failed to parse: %v", err)
	}

	if len(symbols) != 1 {
		t.Fatalf("Expected 1 symbol, got %d", len(symbols))
	}

	if symbols[0].Kind != KindAbstractClass {
		t.Errorf("Expected abstract_class, got %s", symbols[0].Kind)
	}
}

func TestParseDartMixin(t *testing.T) {
	content := `mixin Logger {
  void log(String msg) {}
}`

	symbols, err := parseDart(content)
	if err != nil {
		t.Fatalf("Failed to parse: %v", err)
	}

	found := false
	for _, sym := range symbols {
		if sym.Kind == KindMixin && sym.Name == "Logger" {
			found = true
			break
		}
	}

	if !found {
		t.Error("Mixin 'Logger' not found")
	}
}

func TestParseDartEnum(t *testing.T) {
	content := `enum Color { red, green, blue }`

	symbols, err := parseDart(content)
	if err != nil {
		t.Fatalf("Failed to parse: %v", err)
	}

	found := false
	for _, sym := range symbols {
		if sym.Kind == KindEnum && sym.Name == "Color" {
			found = true
			break
		}
	}

	if !found {
		t.Error("Enum 'Color' not found")
	}
}

func TestParseDartTopLevelFunction(t *testing.T) {
	content := `
void main() {
  print('Hello');
}

String greet(String name) {
  return 'Hello, $name';
}
`

	symbols, err := parseDart(content)
	if err != nil {
		t.Fatalf("Failed to parse: %v", err)
	}

	functionNames := make(map[string]bool)
	for _, sym := range symbols {
		if sym.Kind == KindFunction {
			functionNames[sym.Name] = true
		}
	}

	if !functionNames["main"] {
		t.Error("Function 'main' not found")
	}

	if !functionNames["greet"] {
		t.Error("Function 'greet' not found")
	}
}

func TestParseSymbolsLanguageDispatch(t *testing.T) {
	testCases := []struct {
		language string
		content  string
		wantErr  bool
	}{
		{LangDart, "class Test {}", false},
		{LangJavaScript, "function test() {}", false},
		{LangTypeScript, "function test(): void {}", false},
		{LangPython, "def test():\n    pass", false},
		{LangGo, "func test() {}", false},
		{LangRust, "fn test() {}", false},
		{"unknown", "some code", true},
	}

	for _, tc := range testCases {
		t.Run(tc.language, func(t *testing.T) {
			_, _, err := ParseSymbols(tc.content, tc.language)
			if tc.wantErr && err == nil {
				t.Error("Expected error for unsupported language")
			}
			if !tc.wantErr && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
		})
	}
}

func TestSymbolLocation(t *testing.T) {
	content := `class MyClass {
  void method() {}
}`

	symbols, err := parseDart(content)
	if err != nil {
		t.Fatalf("Failed to parse: %v", err)
	}

	if len(symbols) == 0 {
		t.Fatal("No symbols parsed")
	}

	classSymbol := symbols[0]

	// Check location is set
	if classSymbol.Location.StartLine < 0 {
		t.Error("StartLine should be >= 0")
	}

	if classSymbol.Location.StartOffset < 0 {
		t.Error("StartOffset should be >= 0")
	}

	if classSymbol.Location.EndOffset <= classSymbol.Location.StartOffset {
		t.Error("EndOffset should be > StartOffset")
	}
}

func BenchmarkParseDartSmall(b *testing.B) {
	content := `
class MyClass {
  String name;
  void greet() {}
}
`

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = parseDart(content)
	}
}

func BenchmarkParseDartLarge(b *testing.B) {
	// Simulate a large file
	content := `
class Widget1 { void build() {} }
class Widget2 { void build() {} }
class Widget3 { void build() {} }
class Widget4 { void build() {} }
class Widget5 { void build() {} }
class Widget6 { void build() {} }
class Widget7 { void build() {} }
class Widget8 { void build() {} }
class Widget9 { void build() {} }
class Widget10 { void build() {} }
`

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = parseDart(content)
	}
}
