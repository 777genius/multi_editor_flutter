# Monaco Editor: Context-Aware Auto-Completion для Dart

Документация по реализации интеллектуального автодополнения кода для Monaco Editor в проекте Multi-File Code Editor.

---

## 📊 Сравнение подходов

| Аспект | Подход 1 (Simple) | Подход 2 (LSP) |
|--------|------------------|----------------|
| **Время реализации** | 3-5 дней | 2-3 недели |
| **Сложность** | 4/10 | 7/10 |
| **Качество IntelliSense** | 70% | 95% |
| **Multi-file support** | ❌ | ✅ |
| **Pub packages** | ❌ | ✅ |
| **Offline work** | ✅ | ❌ |
| **Backend нужен** | ❌ | ✅ (Node.js) |
| **Maintenance** | Easy | Medium |

---

## 🎯 Подход 1: `registerCompletionItemProvider` (Рекомендуемый для MVP)

**Сложность:** 4/10
**Время:** 3-5 дней
**Покрытие:** 70% use cases

### Архитектура

```
Monaco Editor (Browser)
    ↓
registerCompletionItemProvider (JS function)
    ↓
Regex/AST Parsing текущего файла
    ↓
Return suggestions
```

### Полная реализация

#### 1. JavaScript Completion Provider

Создать файл: `modules/editor_ui/web/dart_completion.js`

```javascript
/**
 * Context-aware completion provider for Dart in Monaco Editor
 * Provides keywords, snippets, and basic context-aware suggestions
 */

(function() {
  'use strict';

  // Dart keywords
  const DART_KEYWORDS = [
    'abstract', 'as', 'assert', 'async', 'await',
    'break', 'case', 'catch', 'class', 'const', 'continue',
    'default', 'do', 'dynamic', 'else', 'enum', 'export', 'extends',
    'factory', 'false', 'final', 'finally', 'for',
    'get', 'if', 'implements', 'import', 'in', 'is',
    'library', 'mixin', 'new', 'null',
    'operator', 'part', 'return', 'set', 'static', 'super', 'switch',
    'this', 'throw', 'true', 'try', 'typedef',
    'var', 'void', 'while', 'with', 'yield'
  ];

  // Built-in types
  const DART_TYPES = [
    'int', 'double', 'num', 'String', 'bool',
    'List', 'Map', 'Set', 'Iterable',
    'Future', 'Stream',
    'Object', 'Type', 'Function'
  ];

  // String methods
  const STRING_METHODS = [
    { name: 'length', type: 'Property', doc: 'The number of characters in this string' },
    { name: 'isEmpty', type: 'Property', doc: 'Whether this string is empty' },
    { name: 'isNotEmpty', type: 'Property', doc: 'Whether this string is not empty' },
    { name: 'contains', type: 'Method', doc: 'Whether the string contains a match of other' },
    { name: 'substring', type: 'Method', doc: 'The substring of this string from startIndex to endIndex' },
    { name: 'toLowerCase', type: 'Method', doc: 'Converts all characters to lower case' },
    { name: 'toUpperCase', type: 'Method', doc: 'Converts all characters to upper case' },
    { name: 'trim', type: 'Method', doc: 'Returns the string without leading and trailing whitespace' },
    { name: 'split', type: 'Method', doc: 'Splits the string at matches of pattern' },
    { name: 'replaceAll', type: 'Method', doc: 'Replaces all substrings that match from with replace' },
    { name: 'startsWith', type: 'Method', doc: 'Whether the string starts with a match of other' },
    { name: 'endsWith', type: 'Method', doc: 'Whether the string ends with a match of other' }
  ];

  // List methods
  const LIST_METHODS = [
    { name: 'length', type: 'Property', doc: 'The number of objects in this list' },
    { name: 'isEmpty', type: 'Property', doc: 'Whether this collection has no elements' },
    { name: 'isNotEmpty', type: 'Property', doc: 'Whether this collection has at least one element' },
    { name: 'first', type: 'Property', doc: 'The first element' },
    { name: 'last', type: 'Property', doc: 'The last element' },
    { name: 'add', type: 'Method', doc: 'Adds value to the end of this list' },
    { name: 'addAll', type: 'Method', doc: 'Appends all objects of iterable to the end of this list' },
    { name: 'remove', type: 'Method', doc: 'Removes the first occurrence of value from this list' },
    { name: 'removeAt', type: 'Method', doc: 'Removes the object at position index from this list' },
    { name: 'clear', type: 'Method', doc: 'Removes all objects from this list' },
    { name: 'map', type: 'Method', doc: 'Returns a new lazy Iterable with elements that are created by calling f on each element' },
    { name: 'where', type: 'Method', doc: 'Returns a new lazy Iterable with all elements that satisfy test' },
    { name: 'forEach', type: 'Method', doc: 'Invokes action on each element of this iterable' },
    { name: 'contains', type: 'Method', doc: 'Whether the collection contains an element equal to element' },
    { name: 'indexOf', type: 'Method', doc: 'The first index of element in this list' },
    { name: 'sort', type: 'Method', doc: 'Sorts this list according to the order specified by the compare function' }
  ];

  // Map methods
  const MAP_METHODS = [
    { name: 'length', type: 'Property', doc: 'The number of key-value pairs in the map' },
    { name: 'isEmpty', type: 'Property', doc: 'Whether there is no key-value pair in the map' },
    { name: 'isNotEmpty', type: 'Property', doc: 'Whether there is at least one key-value pair in the map' },
    { name: 'keys', type: 'Property', doc: 'The keys of this map' },
    { name: 'values', type: 'Property', doc: 'The values of this map' },
    { name: 'containsKey', type: 'Method', doc: 'Whether this map contains the given key' },
    { name: 'containsValue', type: 'Method', doc: 'Whether this map contains the given value' },
    { name: 'putIfAbsent', type: 'Method', doc: 'Look up the value of key, or add a new entry if it is not present' },
    { name: 'remove', type: 'Method', doc: 'Removes key and its associated value, if present, from the map' },
    { name: 'clear', type: 'Method', doc: 'Removes all entries from the map' },
    { name: 'forEach', type: 'Method', doc: 'Applies action to each key-value pair of the map' }
  ];

  // Widget snippets
  const WIDGET_SNIPPETS = [
    {
      label: 'StatelessWidget',
      insertText: [
        'class ${1:MyWidget} extends StatelessWidget {',
        '  const ${1:MyWidget}({super.key});',
        '',
        '  @override',
        '  Widget build(BuildContext context) {',
        '    return ${2:Container}();',
        '  }',
        '}'
      ].join('\n'),
      documentation: 'Create a StatelessWidget'
    },
    {
      label: 'StatefulWidget',
      insertText: [
        'class ${1:MyWidget} extends StatefulWidget {',
        '  const ${1:MyWidget}({super.key});',
        '',
        '  @override',
        '  State<${1:MyWidget}> createState() => _${1:MyWidget}State();',
        '}',
        '',
        'class _${1:MyWidget}State extends State<${1:MyWidget}> {',
        '  @override',
        '  Widget build(BuildContext context) {',
        '    return ${2:Container}();',
        '  }',
        '}'
      ].join('\n'),
      documentation: 'Create a StatefulWidget'
    },
    {
      label: 'FutureBuilder',
      insertText: [
        'FutureBuilder<${1:Type}>(',
        '  future: ${2:futureFunction()},',
        '  builder: (context, snapshot) {',
        '    if (snapshot.hasData) {',
        '      return ${3:Text(snapshot.data.toString())};',
        '    } else if (snapshot.hasError) {',
        '      return ${4:Text(snapshot.error.toString())};',
        '    }',
        '    return ${5:CircularProgressIndicator}();',
        '  },',
        ')'
      ].join('\n'),
      documentation: 'Create a FutureBuilder widget'
    }
  ];

  // Parse file for local declarations
  function parseLocalDeclarations(fileContent) {
    const declarations = {
      classes: [],
      functions: [],
      variables: []
    };

    // Find class declarations
    const classRegex = /class\s+(\w+)/g;
    let match;
    while ((match = classRegex.exec(fileContent)) !== null) {
      declarations.classes.push(match[1]);
    }

    // Find function declarations
    const funcRegex = /(?:void|Future|String|int|bool|double|dynamic)\s+(\w+)\s*\(/g;
    while ((match = funcRegex.exec(fileContent)) !== null) {
      declarations.functions.push(match[1]);
    }

    // Find variable declarations
    const varRegex = /(?:var|final|const|String|int|bool|double|List|Map)\s+(\w+)\s*=/g;
    while ((match = varRegex.exec(fileContent)) !== null) {
      declarations.variables.push(match[1]);
    }

    return declarations;
  }

  // Infer type of variable
  function inferVariableType(fileContent, varName) {
    // Try explicit type declaration
    const explicitTypeRegex = new RegExp(`(\\w+)(?:<[^>]+>)?\\s+${varName}\\s*=`, 'g');
    const match = explicitTypeRegex.exec(fileContent);
    if (match) {
      return match[1];
    }

    // Try to infer from assignment
    const assignmentRegex = new RegExp(`${varName}\\s*=\\s*(['"\\[]|\\w+\\()`, 'g');
    const assignMatch = assignmentRegex.exec(fileContent);
    if (assignMatch) {
      const value = assignMatch[1];
      if (value.startsWith("'") || value.startsWith('"')) return 'String';
      if (value.startsWith('[')) return 'List';
      if (value.startsWith('{')) return 'Map';
    }

    return null;
  }

  // Main completion provider
  monaco.languages.registerCompletionItemProvider('dart', {
    provideCompletionItems: function(model, position) {
      const textUntilPosition = model.getValueInRange({
        startLineNumber: 1,
        startColumn: 1,
        endLineNumber: position.lineNumber,
        endColumn: position.column
      });

      const word = model.getWordUntilPosition(position);
      const range = {
        startLineNumber: position.lineNumber,
        endLineNumber: position.lineNumber,
        startColumn: word.startColumn,
        endColumn: word.endColumn
      };

      const suggestions = [];
      const fileContent = model.getValue();

      // 1. Keyword completions (at start of line or after whitespace)
      const lineUntilPosition = model.getValueInRange({
        startLineNumber: position.lineNumber,
        startColumn: 1,
        endLineNumber: position.lineNumber,
        endColumn: position.column
      });

      if (/^\s*\w*$/.test(lineUntilPosition)) {
        // Add keywords
        DART_KEYWORDS.forEach(kw => {
          suggestions.push({
            label: kw,
            kind: monaco.languages.CompletionItemKind.Keyword,
            insertText: kw,
            range: range
          });
        });

        // Add types
        DART_TYPES.forEach(type => {
          suggestions.push({
            label: type,
            kind: monaco.languages.CompletionItemKind.Class,
            insertText: type,
            range: range
          });
        });

        // Add local declarations
        const declarations = parseLocalDeclarations(fileContent);

        declarations.classes.forEach(cls => {
          suggestions.push({
            label: cls,
            kind: monaco.languages.CompletionItemKind.Class,
            insertText: cls,
            range: range,
            documentation: `Class ${cls} (local)`
          });
        });

        declarations.functions.forEach(func => {
          suggestions.push({
            label: func,
            kind: monaco.languages.CompletionItemKind.Function,
            insertText: func,
            range: range,
            documentation: `Function ${func} (local)`
          });
        });

        declarations.variables.forEach(varName => {
          suggestions.push({
            label: varName,
            kind: monaco.languages.CompletionItemKind.Variable,
            insertText: varName,
            range: range,
            documentation: `Variable ${varName} (local)`
          });
        });
      }

      // 2. Import completions
      if (/import\s+['"]\s*$/.test(textUntilPosition)) {
        suggestions.push({
          label: 'package:',
          kind: monaco.languages.CompletionItemKind.Module,
          insertText: 'package:',
          range: range,
          documentation: 'Import a package from pub.dev'
        });

        suggestions.push({
          label: 'dart:',
          kind: monaco.languages.CompletionItemKind.Module,
          insertText: 'dart:',
          range: range,
          documentation: 'Import a Dart core library'
        });
      }

      // 3. Method/property completions after dot
      const dotMatch = textUntilPosition.match(/(\w+)\.\w*$/);
      if (dotMatch) {
        const varName = dotMatch[1];
        const varType = inferVariableType(fileContent, varName);

        if (varType === 'String') {
          STRING_METHODS.forEach(method => {
            suggestions.push({
              label: method.name,
              kind: method.type === 'Property'
                ? monaco.languages.CompletionItemKind.Property
                : monaco.languages.CompletionItemKind.Method,
              insertText: method.name,
              range: range,
              documentation: method.doc
            });
          });
        } else if (varType === 'List') {
          LIST_METHODS.forEach(method => {
            suggestions.push({
              label: method.name,
              kind: method.type === 'Property'
                ? monaco.languages.CompletionItemKind.Property
                : monaco.languages.CompletionItemKind.Method,
              insertText: method.name,
              range: range,
              documentation: method.doc
            });
          });
        } else if (varType === 'Map') {
          MAP_METHODS.forEach(method => {
            suggestions.push({
              label: method.name,
              kind: method.type === 'Property'
                ? monaco.languages.CompletionItemKind.Property
                : monaco.languages.CompletionItemKind.Method,
              insertText: method.name,
              range: range,
              documentation: method.doc
            });
          });
        }
      }

      // 4. Widget snippets (after "class" keyword or at start of file)
      if (/(?:^|\n)\s*(?:class)?\s*\w*$/.test(textUntilPosition)) {
        WIDGET_SNIPPETS.forEach(snippet => {
          suggestions.push({
            label: snippet.label,
            kind: monaco.languages.CompletionItemKind.Snippet,
            insertText: snippet.insertText,
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            range: range,
            documentation: snippet.documentation
          });
        });
      }

      return { suggestions: suggestions };
    },

    triggerCharacters: ['.', ' ']
  });

  console.log('Dart completion provider registered');
})();
```

#### 2. Flutter Integration

Обновить файл: `modules/editor_ui/lib/src/widgets/code_editor/monaco_code_editor.dart`

```dart
Future<void> _initializeMonaco() async {
  // ... existing initialization code

  // Load Dart completion provider
  await _controller.evaluateJavascript('''
    (function() {
      var script = document.createElement('script');
      script.src = 'dart_completion.js';
      script.onload = function() {
        console.log('Dart completion provider loaded');
      };
      script.onerror = function() {
        console.error('Failed to load Dart completion provider');
      };
      document.head.appendChild(script);
    })();
  ''');
}
```

#### 3. Добавить файл в pubspec.yaml

```yaml
flutter:
  assets:
    - packages/flutter_monaco/assets/monaco/
    - packages/flutter_monaco/assets/monaco-editor/
    # Добавить:
    - assets/monaco/dart_completion.js
```

Скопировать файл:
```bash
cp modules/editor_ui/web/dart_completion.js modules/editor_ui/assets/monaco/
```

### Что покрывает этот подход:

✅ **Keyword completions**: class, void, Future, async, await, etc.
✅ **Type completions**: String, int, List, Map, etc.
✅ **Local declarations**: классы, функции, переменные из текущего файла
✅ **Context-aware after import**: предлагает "package:" и "dart:"
✅ **Method completions**: для String, List, Map после точки
✅ **Widget snippets**: StatelessWidget, StatefulWidget, FutureBuilder
✅ **Works offline**: нет зависимости от сервера

❌ **Не покрывает**:
- Multi-file analysis (не видит другие файлы)
- Pub packages (не знает про external dependencies)
- Advanced type inference (только базовый)
- Jump to definition
- Real-time error markers

---

## 🚀 Подход 2: `monaco-languageclient` + Dart Analysis Server (LSP)

**Сложность:** 7/10
**Время:** 2-3 недели
**Покрытие:** 95% use cases

### Архитектура

```
Flutter Web (Browser)
    ↓ WebSocket (ws://localhost:3001)
Node.js Express Server
    ↓ stdio (stdin/stdout)
Dart Analysis Server (--lsp flag)
```

### Реализация

#### 1. Backend: Node.js LSP Proxy Server

Создать: `lsp-server/server.js`

```javascript
const express = require('express');
const ws = require('ws');
const { spawn } = require('child_process');
const path = require('path');

const app = express();
const HTTP_PORT = 3000;
const WS_PORT = 3001;

// CORS для development
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'LSP server is running' });
});

// WebSocket server для LSP communication
const wss = new ws.Server({ port: WS_PORT });

wss.on('connection', (socket) => {
  console.log('✅ Client connected to LSP WebSocket');

  // Spawn Dart Analysis Server в LSP mode
  const dartSdk = process.env.DART_SDK_PATH || '/usr/local/flutter/bin/cache/dart-sdk';
  const dartBin = path.join(dartSdk, 'bin', 'dart');

  console.log(`Starting Dart Analysis Server: ${dartBin}`);

  const analysisServer = spawn(dartBin, [
    'language-server',
    '--client-id=monaco-editor',
    '--client-version=1.0.0',
    '--protocol=lsp'
  ], {
    stdio: ['pipe', 'pipe', 'pipe']
  });

  // Track if process started successfully
  let serverStarted = false;

  analysisServer.on('spawn', () => {
    console.log('✅ Dart Analysis Server started');
    serverStarted = true;
  });

  analysisServer.on('error', (err) => {
    console.error('❌ Failed to start Dart Analysis Server:', err);
    socket.send(JSON.stringify({
      jsonrpc: '2.0',
      error: {
        code: -32000,
        message: 'Failed to start Dart Analysis Server: ' + err.message
      }
    }));
  });

  // Forward messages: WebSocket → Dart Analysis Server
  socket.on('message', (message) => {
    if (serverStarted) {
      try {
        const data = message.toString();
        console.log('→ Browser → DAS:', data.substring(0, 100) + '...');

        // LSP uses Content-Length headers
        const contentLength = Buffer.byteLength(data, 'utf8');
        const header = `Content-Length: ${contentLength}\r\n\r\n`;

        analysisServer.stdin.write(header + data);
      } catch (err) {
        console.error('Error forwarding message to DAS:', err);
      }
    }
  });

  // Forward messages: Dart Analysis Server → WebSocket
  let buffer = '';

  analysisServer.stdout.on('data', (data) => {
    buffer += data.toString();

    // Process all complete messages in buffer
    while (true) {
      const headerMatch = buffer.match(/Content-Length: (\d+)\r\n\r\n/);
      if (!headerMatch) break;

      const contentLength = parseInt(headerMatch[1]);
      const headerLength = headerMatch[0].length;
      const messageStart = buffer.indexOf(headerMatch[0]) + headerLength;

      if (buffer.length < messageStart + contentLength) {
        // Incomplete message, wait for more data
        break;
      }

      const message = buffer.substring(messageStart, messageStart + contentLength);
      console.log('← DAS → Browser:', message.substring(0, 100) + '...');

      socket.send(message);

      buffer = buffer.substring(messageStart + contentLength);
    }
  });

  analysisServer.stderr.on('data', (data) => {
    console.error('DAS stderr:', data.toString());
  });

  // Cleanup on disconnect
  socket.on('close', () => {
    console.log('❌ Client disconnected');
    if (serverStarted) {
      analysisServer.kill();
      console.log('Dart Analysis Server stopped');
    }
  });

  analysisServer.on('exit', (code) => {
    console.log(`Dart Analysis Server exited with code ${code}`);
    socket.close();
  });
});

app.listen(HTTP_PORT, () => {
  console.log(`📡 HTTP Server: http://localhost:${HTTP_PORT}`);
  console.log(`🔌 WebSocket Server: ws://localhost:${WS_PORT}`);
  console.log('\nWaiting for connections...');
});
```

Создать: `lsp-server/package.json`

```json
{
  "name": "dart-lsp-server",
  "version": "1.0.0",
  "description": "LSP proxy server for Dart Analysis Server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.16.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
```

Установка и запуск:

```bash
cd lsp-server
npm install
npm start
```

#### 2. Frontend: Monaco LSP Client

Создать: `modules/editor_ui/web/monaco_lsp_client.js`

```javascript
/**
 * Monaco LSP Client for Dart Analysis Server
 * Connects Monaco Editor to Dart Analysis Server via WebSocket
 */

import * as monaco from 'monaco-editor';
import { MonacoLanguageClient, CloseAction, ErrorAction } from 'monaco-languageclient';
import { toSocket, WebSocketMessageReader, WebSocketMessageWriter } from 'vscode-ws-jsonrpc';

const LSP_SERVER_URL = 'ws://localhost:3001';

// Initialize LSP connection
export async function initializeDartLSP(editor) {
  try {
    console.log('Connecting to Dart LSP server...');

    const webSocket = new WebSocket(LSP_SERVER_URL);

    webSocket.onopen = () => {
      console.log('✅ Connected to Dart LSP server');

      const socket = toSocket(webSocket);
      const reader = new WebSocketMessageReader(socket);
      const writer = new WebSocketMessageWriter(socket);

      // Create language client
      const languageClient = new MonacoLanguageClient({
        name: 'Dart Language Client',
        clientOptions: {
          // Document selector
          documentSelector: [{ language: 'dart' }],

          // Synchronize settings
          synchronize: {
            fileEvents: monaco.workspace.createFileSystemWatcher('**/*.dart')
          },

          // Error handling
          errorHandler: {
            error: () => ErrorAction.Continue,
            closed: () => CloseAction.DoNotRestart
          },

          // Workspace configuration
          workspaceFolder: {
            uri: monaco.Uri.parse('file:///workspace'),
            name: 'workspace',
            index: 0
          }
        },

        // Connection provider
        connectionProvider: {
          get: (errorHandler, closeHandler) => {
            return Promise.resolve({
              reader,
              writer
            });
          }
        }
      });

      // Start the client
      languageClient.start();

      // Register dispose handler
      reader.onClose(() => {
        console.log('LSP connection closed');
        languageClient.stop();
      });

      console.log('✅ Dart LSP client initialized');
    };

    webSocket.onerror = (error) => {
      console.error('❌ LSP WebSocket error:', error);
      console.log('Falling back to basic completion provider');
      // Fallback to basic completion
      loadBasicCompletionProvider();
    };

  } catch (error) {
    console.error('❌ Failed to initialize LSP:', error);
    console.log('Falling back to basic completion provider');
    loadBasicCompletionProvider();
  }
}

// Fallback to basic completion if LSP unavailable
function loadBasicCompletionProvider() {
  const script = document.createElement('script');
  script.src = 'dart_completion.js';
  document.head.appendChild(script);
}

// Export for use in Monaco initialization
window.initializeDartLSP = initializeDartLSP;
```

#### 3. Integration в Flutter

Обновить: `modules/editor_ui/lib/src/widgets/code_editor/monaco_code_editor.dart`

```dart
class MonacoCodeEditor extends StatefulWidget {
  final bool enableLSP;
  final String? lspServerUrl;

  const MonacoCodeEditor({
    super.key,
    this.enableLSP = false,
    this.lspServerUrl,
  });
}

class _MonacoCodeEditorState extends State<MonacoCodeEditor> {
  Future<void> _initializeMonaco() async {
    // ... existing initialization

    // Check if LSP should be enabled
    if (widget.enableLSP) {
      await _tryInitializeLSP();
    } else {
      await _loadBasicCompletion();
    }
  }

  Future<void> _tryInitializeLSP() async {
    final lspUrl = widget.lspServerUrl ?? 'ws://localhost:3001';

    await _controller.evaluateJavascript('''
      (async function() {
        try {
          // Check if LSP server is available
          const response = await fetch('${lspUrl.replaceFirst('ws', 'http')}/health');

          if (response.ok) {
            console.log('LSP server available, loading LSP client');

            // Load Monaco LSP client
            const script = document.createElement('script');
            script.type = 'module';
            script.src = 'monaco_lsp_client.js';
            script.onload = function() {
              if (window.initializeDartLSP) {
                window.initializeDartLSP(window.monacoEditor);
              }
            };
            document.head.appendChild(script);
          } else {
            throw new Error('LSP server not healthy');
          }
        } catch (error) {
          console.error('LSP server not available:', error);
          console.log('Loading basic completion provider');

          // Fallback to basic completion
          const script = document.createElement('script');
          script.src = 'dart_completion.js';
          document.head.appendChild(script);
        }
      })();
    ''');
  }

  Future<void> _loadBasicCompletion() async {
    await _controller.evaluateJavascript('''
      (function() {
        var script = document.createElement('script');
        script.src = 'dart_completion.js';
        document.head.appendChild(script);
      })();
    ''');
  }
}
```

### Что покрывает LSP подход:

✅ **Full IntelliSense**: как в VS Code
✅ **Multi-file analysis**: видит все файлы проекта
✅ **Pub packages**: знает про external dependencies
✅ **Type inference**: полноценный анализ типов
✅ **Jump to definition**: навигация по коду
✅ **Error markers**: real-time error checking
✅ **Code actions**: quick fixes, refactorings
✅ **Hover documentation**: показывает dartdoc

⚠️ **Требования**:
- Node.js сервер должен быть запущен
- Dart SDK установлен на сервере
- Не работает offline

---

## 📋 Поэтапный план внедрения

### Фаза 1: MVP (3-5 дней) — Подход 1
**Задачи:**
1. ✅ Создать `dart_completion.js` с базовыми completions
2. ✅ Интегрировать в Monaco initialization
3. ✅ Протестировать keywords, types, snippets
4. ✅ Добавить context-aware completions (import, dot notation)
5. ✅ Оптимизировать performance

**Результат:** 70% use cases покрыты, работает offline

### Фаза 2: Advanced Local Analysis (неделя 2)
**Задачи:**
1. Улучшить парсинг текущего файла (AST вместо regex)
2. Добавить более точный type inference
3. Добавить больше Widget snippets
4. Добавить Flutter-specific completions (MaterialApp, Scaffold, etc.)

**Результат:** 80% use cases покрыты

### Фаза 3: LSP Integration (неделя 3-4) — Подход 2
**Задачи:**
1. ✅ Настроить Node.js LSP proxy server
2. ✅ Интегрировать monaco-languageclient
3. ✅ Реализовать WebSocket communication
4. ✅ Добавить fallback на Подход 1 если LSP недоступен
5. ✅ Тестирование и оптимизация

**Результат:** 95% use cases покрыты

---

## 🛠 Развертывание

### Development
```bash
# Terminal 1: Flutter app
cd example
flutter run -d chrome

# Terminal 2: LSP server (опционально)
cd lsp-server
npm start
```

### Production

**Вариант A: Без LSP (только Подход 1)**
- Bundled JavaScript компилируется в Flutter web assets
- Работает без дополнительных сервисов
- Подходит для большинства use cases

**Вариант B: С LSP (Подход 2)**
- Deploy Node.js LSP server отдельно (Docker, Cloud Run, etc.)
- Flutter app коннектится к LSP server URL
- Максимальная функциональность IntelliSense

---

## 📊 ROI Analysis

### Подход 1: registerCompletionItemProvider

**Инвестиции:**
- Development: 3-5 дней = ~40 часов
- Maintenance: 1-2 часа/месяц

**Выгоды:**
- ✅ Immediate value (работает сразу)
- ✅ Zero infrastructure costs
- ✅ Покрывает 70% use cases
- ✅ Проект rating: 84 → 87 (+3%)

### Подход 2: LSP Integration

**Инвестиции:**
- Development: 2-3 недели = ~80-120 часов
- Infrastructure: Node.js server hosting (~$5-20/месяц)
- Maintenance: 3-5 часов/месяц

**Выгоды:**
- ✅ Professional-grade IntelliSense
- ✅ Покрывает 95% use cases
- ✅ Competitive advantage vs всех Flutter editor пакетов
- ✅ Проект rating: 84 → 92 (+8%)

---

## 🎯 Рекомендация

### Рекомендуемая стратегия: **Incremental Implementation**

**Week 1:** Подход 1 (MVP)
- Быстрый wins
- Immediate user value
- Low risk

**Week 2:** Enhanced Local Analysis
- Improve Подход 1
- 80% functionality
- Still no infrastructure

**Week 3-4:** LSP Integration (опционально)
- Premium feature
- Opt-in для пользователей
- Maximum functionality

**Deployment:**
```dart
const MonacoCodeEditor(
  enableLSP: true,  // Опция для пользователей
  lspServerUrl: 'wss://lsp.yourapp.com',  // Hosted LSP server
);
```

---

## 📚 Полезные ресурсы

### Monaco Editor
- [Monaco Editor API](https://microsoft.github.io/monaco-editor/api/index.html)
- [Monaco Language Client](https://github.com/TypeFox/monaco-languageclient)
- [Customizing Monaco](https://www.checklyhq.com/blog/customizing-monaco/)

### Dart LSP
- [Dart Analysis Server LSP](https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server/tool/lsp_spec)
- [LSP Specification](https://microsoft.github.io/language-server-protocol/)

### Flutter Integration
- [flutter_monaco package](https://pub.dev/packages/flutter_monaco)
- [WebView integration](https://pub.dev/packages/webview_flutter)

---

## ✅ Checklist для реализации

### Подход 1 (MVP)
- [ ] Создать `dart_completion.js`
- [ ] Добавить keyword completions
- [ ] Добавить type completions
- [ ] Реализовать context-aware suggestions (import, dot)
- [ ] Добавить Widget snippets
- [ ] Интегрировать в Monaco initialization
- [ ] Протестировать на разных файлах
- [ ] Оптимизировать performance

### Подход 2 (LSP) — опционально
- [ ] Настроить Node.js server
- [ ] Настроить Dart Analysis Server integration
- [ ] Реализовать WebSocket proxy
- [ ] Интегрировать monaco-languageclient
- [ ] Добавить fallback логику
- [ ] Протестировать completions, hover, errors
- [ ] Deploy LSP server
- [ ] Настроить environment variables

---

**Последнее обновление:** 2025-11-07
**Статус:** Ready for implementation
**Приоритет:** High (увеличит project rating с 84 → 87-92)
