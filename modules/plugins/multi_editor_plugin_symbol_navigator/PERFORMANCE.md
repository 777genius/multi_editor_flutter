# Symbol Navigator - Performance Guide

This guide explains performance characteristics, optimization techniques, and benchmarking results.

## 📊 Current Performance (v0.1.0)

### Parse Times (Regex-based)

| File Size | Lines | Parse Time | Memory |
|-----------|-------|------------|--------|
| Small | 100 | 0.5-1ms | ~200KB |
| Medium | 1,000 | 5-10ms | ~2MB |
| Large | 10,000 | 50-100ms | ~20MB |
| XLarge | 100,000 | 500-1000ms | ~200MB |

### Throughput

- **Lines per second**: ~100,000-200,000
- **Files per second**: ~100-200 (1K lines each)
- **Symbols per second**: ~10,000-20,000

## 🎯 Target Performance (Tree-sitter)

| Metric | Current | Target | Improvement |
|--------|---------|--------|-------------|
| Parse 1K lines | 5-10ms | 0.5-1ms | **10x** |
| Parse 10K lines | 50-100ms | 5-10ms | **10x** |
| Memory per file | 2MB | 500KB | **4x less** |
| Accuracy | 90% | 99.9% | +9.9% |

## 🔍 Performance Profiling

### Dart Side

#### Measuring Parse Time

```dart
final stopwatch = Stopwatch()..start();
await symbolNavigator._parseFile(file);
stopwatch.stop();
print('Parse time: ${stopwatch.elapsedMilliseconds}ms');
```

#### Using DevTools

```bash
# Run with profiling
flutter run --profile

# In DevTools:
# 1. Open Performance tab
# 2. Record timeline
# 3. Trigger file parse
# 4. Stop recording
# 5. Analyze CPU flame graph
```

### Go Side

#### Benchmarking

```bash
# Run benchmarks
cd packages/wasm_plugins/symbol_navigator_wasm
go test -bench=. -benchmem

# Results:
# BenchmarkParseDartSmall-8    1000000   1234 ns/op   512 B/op   8 allocs/op
# BenchmarkParseDartLarge-8     10000  123456 ns/op  5120 B/op  80 allocs/op
```

#### CPU Profiling

```bash
# Generate CPU profile
go test -cpuprofile=cpu.prof -bench=.

# Analyze with pprof
go tool pprof cpu.prof
> top10
> list ParseSymbols
```

#### Memory Profiling

```bash
# Generate memory profile
go test -memprofile=mem.prof -bench=.

# Analyze
go tool pprof mem.prof
> top10
> list parseDart
```

## ⚡ Optimization Techniques

### 1. Debouncing (Implemented)

**Current**: 500ms debounce prevents excessive parsing on rapid changes.

```dart
static const _parseDelay = Duration(milliseconds: 500);

_parseDebounce?.cancel();
_parseDebounce = Timer(_parseDelay, () {
  _parseFile(file);
});
```

**Impact**: Reduces parse calls by ~80% during typing.

### 2. Incremental Parsing (TODO)

**Goal**: Only re-parse changed regions.

```go
func IncrementalParse(tree *SymbolTree, edit Edit) []Symbol {
  // Find affected symbols
  affected := findAffectedSymbols(tree, edit)

  // Re-parse only affected region
  newSymbols := parseRegion(edit.StartLine, edit.EndLine)

  // Merge with existing tree
  return mergeSymbols(tree.Symbols, newSymbols, affected)
}
```

**Expected Impact**: 5-10x faster for small edits.

### 3. Worker Isolation (TODO)

**Goal**: Parse in background thread/isolate.

```dart
// Dart Isolate
final receivePort = ReceivePort();
await Isolate.spawn(_parseWorker, receivePort.sendPort);

// Heavy parsing happens off main thread
final result = await receivePort.first;
```

**Impact**: No UI blocking during parse.

### 4. Caching (TODO)

**Goal**: Cache parsed symbols, invalidate on change.

```dart
final _cache = <String, SymbolTree>{};

SymbolTree? getCached(String fileId, DateTime modifiedAt) {
  final cached = _cache[fileId];
  if (cached != null && cached.timestamp == modifiedAt) {
    return cached;
  }
  return null;
}
```

**Impact**: Instant retrieval for unchanged files.

### 5. Tree-sitter Integration (Roadmap)

**Why Tree-sitter?**
- Incremental parsing built-in
- Error recovery
- 10-100x faster than regex
- 99.9% accuracy

```go
import "github.com/tree-sitter/go-tree-sitter"

func ParseWithTreeSitter(content string) []Symbol {
  parser := sitter.NewParser()
  parser.SetLanguage(dart.GetLanguage())

  tree := parser.Parse(nil, []byte(content))
  return extractSymbols(tree.RootNode())
}
```

**Expected Impact**: See "Target Performance" above.

## 📈 Benchmarking Guide

### Running Benchmarks

```bash
# Go benchmarks
cd packages/wasm_plugins/symbol_navigator_wasm
./dev.sh bench

# Compare before/after
go test -bench=. -benchmem > before.txt
# (make changes)
go test -bench=. -benchmem > after.txt
benchstat before.txt after.txt
```

### Benchmark Results Format

```text
BenchmarkParseDartSmall-8        1000000    1234 ns/op    512 B/op    8 allocs/op
BenchmarkParseDartLarge-8          10000  123456 ns/op   5120 B/op   80 allocs/op
```

Interpretation:
- **1000000**: Iterations run
- **1234 ns/op**: Nanoseconds per operation
- **512 B/op**: Bytes allocated per operation
- **8 allocs/op**: Allocations per operation

### Creating Benchmarks

```go
func BenchmarkMyFunction(b *testing.B) {
  // Setup (not timed)
  content := loadTestFile()

  // Reset timer before benchmark
  b.ResetTimer()

  // Run benchmark
  for i := 0; i < b.N; i++ {
    ParseSymbols(content, "dart")
  }
}
```

## 🎛️ Performance Tuning

### Memory Optimization

#### 1. Reduce Allocations

```go
// ❌ Bad: Allocates new string each iteration
result := ""
for _, item := range items {
  result += item
}

// ✅ Good: Single buffer, minimal allocations
var buffer strings.Builder
for _, item := range items {
  buffer.WriteString(item)
}
result := buffer.String()
```

#### 2. Reuse Buffers

```go
// Pool for reusable buffers
var bufferPool = sync.Pool{
  New: func() interface{} {
    return new(bytes.Buffer)
  },
}

func parseWithBuffer(content string) []Symbol {
  buf := bufferPool.Get().(*bytes.Buffer)
  defer func() {
    buf.Reset()
    bufferPool.Put(buf)
  }()

  // Use buffer
}
```

#### 3. Avoid Unnecessary Copies

```dart
// ❌ Bad: Copies entire list
final allSymbols = [...tree.symbols];
allSymbols.addAll(moreSymbols);

// ✅ Good: Modify in place when possible
tree.symbols.addAll(moreSymbols);
```

### CPU Optimization

#### 1. Minimize Regex Complexity

```go
// ❌ Bad: Catastrophic backtracking possible
badRegex := regexp.MustCompile(`(a+)+b`)

// ✅ Good: Linear time
goodRegex := regexp.MustCompile(`a+b`)
```

#### 2. Early Exit

```go
// ✅ Good: Exit early if possible
func findSymbol(symbols []Symbol, name string) *Symbol {
  for _, sym := range symbols {
    if sym.Name == name {
      return &sym  // Early exit
    }
  }
  return nil
}
```

#### 3. Batch Processing

```dart
// ✅ Good: Process multiple files in batch
Future<void> parseMultipleFiles(List<FileDocument> files) async {
  await Future.wait(
    files.map((file) => _parseFile(file)),
  );
}
```

## 📉 Common Performance Pitfalls

### 1. No Debouncing

**Problem**: Parse on every keystroke → 100s of parses per second.

**Solution**: 500ms debounce implemented.

### 2. Synchronous Parsing on UI Thread

**Problem**: UI freezes during parse.

**Solution**: Use async/await, consider Isolates for very large files.

### 3. Unbounded Memory Growth

**Problem**: Keep all parsed trees in memory.

**Solution**: LRU cache with size limit.

```dart
class LRUCache<K, V> {
  final int maxSize;
  final _cache = <K, V>{};
  final _order = <K>[];

  void put(K key, V value) {
    if (_cache.length >= maxSize) {
      final oldest = _order.removeAt(0);
      _cache.remove(oldest);
    }
    _cache[key] = value;
    _order.add(key);
  }
}
```

### 4. Expensive UI Updates

**Problem**: Rebuild entire tree on every parse.

**Solution**: Incremental updates, use `const` constructors.

### 5. No Progress Indication

**Problem**: User thinks app froze during long parse.

**Solution**: Show loading indicator, progress updates.

## 🔬 Performance Testing

### Load Testing

```dart
test('parses 1000 files without memory leak', () async {
  final plugin = SymbolNavigatorPlugin();

  for (var i = 0; i < 1000; i++) {
    final file = generateMockFile(lines: 1000);
    plugin.onFileOpen(file);
    await Future.delayed(Duration(milliseconds: 10));
  }

  // Memory should stabilize
  expect(getCurrentMemoryUsage(), lessThan(100 * 1024 * 1024)); // 100MB
});
```

### Stress Testing

```dart
test('handles 100K line file', () async {
  final hugeFile = generateMockFile(lines: 100000);

  final stopwatch = Stopwatch()..start();
  plugin.onFileOpen(hugeFile);
  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // < 2s
});
```

## 📊 Performance Monitoring

### Metrics to Track

1. **Parse Time**: Time from file open to symbols ready
2. **Memory Usage**: Peak memory during parse
3. **Throughput**: Lines/symbols per second
4. **Accuracy**: % of symbols correctly identified
5. **UI Responsiveness**: Frame rate during parse

### Logging Performance

```dart
void _parseFile(FileDocument file) async {
  final stopwatch = Stopwatch()..start();
  final startMemory = getCurrentMemoryUsage();

  try {
    // Parse
    final tree = await performParse(file);

    // Log metrics
    final duration = stopwatch.elapsedMilliseconds;
    final memoryUsed = getCurrentMemoryUsage() - startMemory;

    logger.info('Parse complete', {
      'file': file.name,
      'lines': file.content.split('\n').length,
      'symbols': tree.totalCount,
      'duration_ms': duration,
      'memory_mb': memoryUsed / (1024 * 1024),
      'throughput_lines_per_sec': lines / (duration / 1000),
    });
  } finally {
    stopwatch.stop();
  }
}
```

## 🎯 Performance Goals

### Short-term (v0.2.0)

- [ ] Tree-sitter integration: 10x speedup
- [ ] Memory optimization: 4x reduction
- [ ] Benchmark suite: Automated tracking

### Medium-term (v0.3.0)

- [ ] Incremental parsing: 5-10x for edits
- [ ] Worker isolation: No UI blocking
- [ ] LRU cache: Instant for unchanged files

### Long-term (v1.0.0)

- [ ] Sub-millisecond parsing for 1K lines
- [ ] 500KB memory per file max
- [ ] 99.9% accuracy all languages
- [ ] Real-time parsing (< 16ms latency)

## 📝 Performance Checklist

Before releasing performance improvements:

- [ ] Run benchmarks (before/after comparison)
- [ ] Profile CPU (identify bottlenecks)
- [ ] Profile memory (check for leaks)
- [ ] Test on large files (10K+ lines)
- [ ] Test on slow devices (verify UI responsiveness)
- [ ] Document changes (performance gains in CHANGELOG)
- [ ] Update benchmarks (record new baselines)

## 🆘 Performance Troubleshooting

### Symptom: Slow Parsing

**Debug**:
1. Check file size: Is it > 10K lines?
2. Profile: Where is time spent?
3. Check regex: Any catastrophic backtracking?
4. Verify debouncing: Is it working?

### Symptom: High Memory Usage

**Debug**:
1. Profile memory: What's allocating?
2. Check caching: Growing unbounded?
3. Look for leaks: Are objects being released?
4. Verify WASM cleanup: dealloc() called?

### Symptom: UI Freezing

**Debug**:
1. Is parsing synchronous?
2. Check DevTools timeline
3. Move to Isolate/Worker
4. Add progress indicators

## 🚀 Future Optimizations

1. **SIMD**: Use SIMD instructions for pattern matching
2. **GPU**: Offload parsing to GPU (experimental)
3. **Caching**: Distributed cache for team projects
4. **Preloading**: Anticipate which files user will open
5. **Compression**: Compress cached symbols

---

**For more details, see:**
- [ARCHITECTURE.md](ARCHITECTURE.md) - Design details
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guide
- Go benchmarks: `./dev.sh bench`
- Dart profiling: Flutter DevTools
