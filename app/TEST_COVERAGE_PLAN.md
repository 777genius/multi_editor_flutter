# Крупномасштабный план интеграции тестов IDE
## Цель: 50% покрытие тестами для /app IDE

---

## 📊 Текущее состояние

### Общая статистика
- **Всего Dart файлов:** 201 (без generated)
- **Текущее количество тестов:** 14
- **Текущее покрытие:** ~7%
- **Целевое покрытие:** 50%
- **Необходимо добавить тестов:** ~96 тестовых файлов

### Модули с существующими тестами
1. **lsp_application** - 6 тестов ✅
2. **git_integration** - 3 теста ✅
3. **ide_presentation** - 3 теста ✅
4. **global_search** - 1 тест ✅
5. **minimap_enhancement** - 1 тест ✅

### Модули БЕЗ тестов (критичные)
- **lsp_domain** (26 файлов) ❌
- **editor_core** (18 файлов) ❌
- **lsp_infrastructure** (8 файлов) ❌
- **editor_ffi** (4 файла) ❌
- **editor_monaco** (4 файла) ❌
- **dart_ide_enhancements** (3 файла) ❌
- **js_ts_ide_enhancements** (3 файла) ❌

---

## 🎯 Стратегия тестирования

### Принципы
1. **Модульная независимость** - каждый модуль имеет свою папку test/
2. **Покрытие по слоям** - тесты для Domain → Application → Infrastructure → Presentation
3. **Типы тестов** - Unit, Widget, Integration
4. **Приоритизация** - сначала критичные модули с Clean Architecture

### Целевое распределение тестов по модулям

| Модуль | Файлов | Текущих тестов | Целевых тестов | Приоритет |
|--------|--------|----------------|----------------|-----------|
| git_integration | 76 | 3 | 38 | 🔴 Высокий |
| lsp_application | 27 | 6 | 14 | 🟡 Средний |
| lsp_domain | 26 | 0 | 13 | 🔴 Высокий |
| ide_presentation | 22 | 3 | 11 | 🟡 Средний |
| editor_core | 18 | 0 | 9 | 🔴 Высокий |
| lsp_infrastructure | 8 | 0 | 4 | 🟡 Средний |
| global_search | 5 | 1 | 3 | 🟢 Низкий |
| minimap_enhancement | 5 | 1 | 3 | 🟢 Низкий |
| editor_ffi | 4 | 0 | 2 | 🟡 Средний |
| editor_monaco | 4 | 0 | 2 | 🟡 Средний |
| dart_ide_enhancements | 3 | 0 | 2 | 🟢 Низкий |
| js_ts_ide_enhancements | 3 | 0 | 2 | 🟢 Низкий |
| **ИТОГО** | **201** | **14** | **103** | |

---

## 📋 Детальный план по модулям

---

## 🔴 ФАЗА 1: Критичные модули (Приоритет: Высокий)

### 1.1. lsp_domain (Domain Layer для LSP)

**Текущее:** 0 тестов | **Цель:** 13 тестов

#### Структура тестов
```
app/modules/lsp_domain/test/
├── entities/
│   ├── lsp_session_test.dart
│   ├── diagnostic_test.dart
│   ├── completion_list_test.dart
│   ├── hover_info_test.dart
│   ├── code_lens_test.dart
│   ├── code_action_test.dart
│   └── document_symbol_test.dart
├── value_objects/
│   └── session_id_test.dart
├── failures/
│   └── lsp_failure_test.dart
└── repositories/
    └── i_lsp_client_repository_test.dart (mock interface)
```

#### Тесты для создания (13)

##### 1. **lsp_session_test.dart** - Unit тесты для LSPSession
```dart
// Тесты:
// - Создание сессии с валидными данными
// - Переходы состояния (uninitialized → initializing → ready)
// - Валидация SessionId
// - Сериализация/десериализация
// - Equality и hashCode
```

##### 2. **diagnostic_test.dart** - Unit тесты для Diagnostic
```dart
// Тесты:
// - Создание диагностики с разными severity
// - Валидация range
// - Группировка по severity
// - Фильтрация диагностик
// - JSON сериализация
```

##### 3. **completion_list_test.dart** - Unit тесты для CompletionList
```dart
// Тесты:
// - Создание списка автодополнений
// - Фильтрация по типу
// - Сортировка по приоритету
// - Incremental vs Complete режимы
```

##### 4. **hover_info_test.dart** - Unit тесты для HoverInfo
```dart
// Тесты:
// - Создание hover информации
// - Markdown форматирование
// - Range валидация
```

##### 5. **code_lens_test.dart** - Unit тесты для CodeLens
```dart
// Тесты:
// - Создание code lens
// - Валидация команд
// - Range валидация
```

##### 6. **code_action_test.dart** - Unit тесты для CodeAction
```dart
// Тесты:
// - Создание code actions
// - Типы actions (quickfix, refactor, source)
// - Edits валидация
```

##### 7. **document_symbol_test.dart** - Unit тесты для DocumentSymbol
```dart
// Тесты:
// - Создание символов
// - Иерархия символов (дерево)
// - Различные типы (class, method, field)
```

##### 8-13. **Остальные entity тесты** - signature_help, semantic_tokens, folding_range, etc.

---

### 1.2. editor_core (Domain Layer для Editor)

**Текущее:** 0 тестов | **Цель:** 9 тестов

#### Структура тестов
```
app/modules/editor_core/test/
├── entities/
│   ├── editor_document_test.dart
│   ├── cursor_position_test.dart
│   ├── text_selection_test.dart
│   └── editor_theme_test.dart
├── value_objects/
│   ├── language_id_test.dart
│   └── document_uri_test.dart
├── failures/
│   └── editor_failure_test.dart
└── repositories/
    └── i_code_editor_repository_test.dart (mock interface)
```

#### Тесты для создания (9)

##### 1. **editor_document_test.dart** - Unit тесты для EditorDocument
```dart
// Тесты:
// - Создание документа с контентом
// - Валидация URI
// - Изменение контента
// - Language ID ассоциация
// - Dirty state tracking
```

##### 2. **cursor_position_test.dart** - Unit тесты для CursorPosition
```dart
// Тесты:
// - Валидация line и column
// - Comparison операции (before, after)
// - Offset calculation
// - Boundary checks
```

##### 3. **text_selection_test.dart** - Unit тесты для TextSelection
```dart
// Тесты:
// - Создание selection с start/end
// - isEmpty проверка
// - Reverse selection
// - Merge selections
// - Overlap detection
```

##### 4. **editor_theme_test.dart** - Unit тесты для EditorTheme
```dart
// Тесты:
// - Создание темы
// - Light vs Dark режимы
// - Color scheme валидация
// - Default values
```

##### 5-9. **Остальные тесты** - language_id, document_uri, failures

---

### 1.3. git_integration (Full Stack модуль)

**Текущее:** 3 теста | **Цель:** 38 тестов

#### Структура тестов (расширенная)
```
app/modules/git_integration/test/
├── domain/
│   ├── entities/
│   │   ├── git_repository_test.dart
│   │   ├── git_commit_test.dart
│   │   ├── git_branch_test.dart
│   │   ├── git_remote_test.dart
│   │   ├── merge_conflict_test.dart
│   │   └── diff_hunk_test.dart
│   ├── value_objects/
│   │   ├── repository_path_test.dart
│   │   ├── branch_name_test.dart
│   │   ├── commit_hash_test.dart
│   │   └── commit_message_test.dart
│   └── services/
│       ├── conflict_detector_test.dart
│       └── merge_strategy_selector_test.dart
├── application/
│   ├── use_cases/
│   │   ├── init_repository_use_case_test.dart
│   │   ├── clone_repository_use_case_test.dart
│   │   ├── commit_changes_use_case_test.dart
│   │   ├── push_changes_use_case_test.dart
│   │   ├── pull_changes_use_case_test.dart
│   │   ├── merge_branch_use_case_test.dart
│   │   ├── create_branch_use_case_test.dart
│   │   ├── checkout_branch_use_case_test.dart
│   │   └── ... (18 use cases всего)
│   └── services/
│       ├── git_service_test.dart
│       ├── diff_service_test.dart
│       ├── blame_service_test.dart
│       └── merge_service_test.dart
├── infrastructure/
│   ├── repositories/
│   │   ├── git_cli_repository_test.dart
│   │   ├── diff_repository_impl_test.dart ✅ (exists)
│   │   └── credential_repository_impl_test.dart ✅ (exists)
│   └── adapters/
│       ├── git_command_adapter_test.dart
│       └── git_parser_adapter_test.dart
└── presentation/
    ├── widgets/
    │   ├── git_panel_test.dart
    │   ├── git_panel_enhanced_test.dart ✅ (exists)
    │   ├── commit_dialog_test.dart
    │   ├── diff_viewer_test.dart
    │   └── merge_conflict_resolver_test.dart
    └── providers/
        ├── git_state_provider_test.dart
        └── diff_state_provider_test.dart
```

#### Приоритетные тесты (35 новых)

##### Domain Layer (12 тестов)
1. **git_repository_test.dart** - Тесты для GitRepository entity
2. **git_commit_test.dart** - Тесты для GitCommit
3. **git_branch_test.dart** - Тесты для GitBranch
4. **merge_conflict_test.dart** - Тесты обнаружения конфликтов
5. **repository_path_test.dart** - Валидация путей
6. **branch_name_test.dart** - Валидация имен веток
7. **commit_hash_test.dart** - Валидация SHA-1
8. **conflict_detector_test.dart** - Логика обнаружения конфликтов
9-12. Остальные entities и value objects

##### Application Layer (15 тестов)
1. **init_repository_use_case_test.dart** - Инициализация репозитория
2. **clone_repository_use_case_test.dart** - Клонирование
3. **commit_changes_use_case_test.dart** - Создание коммитов
4. **push_changes_use_case_test.dart** - Push операции
5. **pull_changes_use_case_test.dart** - Pull операции
6. **merge_branch_use_case_test.dart** - Merge веток
7. **create_branch_use_case_test.dart** - Создание веток
8. **checkout_branch_use_case_test.dart** - Переключение веток
9. **git_service_test.dart** - Основной Git сервис
10. **diff_service_test.dart** - Diff вычисление
11-15. Остальные use cases

##### Infrastructure Layer (3 теста)
1. **git_cli_repository_test.dart** - Git CLI адаптер
2. **git_command_adapter_test.dart** - Command execution
3. **git_parser_adapter_test.dart** - Парсинг Git вывода

##### Presentation Layer (5 тестов)
1. **git_panel_test.dart** - Основная Git панель
2. **commit_dialog_test.dart** - Диалог коммита
3. **diff_viewer_test.dart** - Визуализация diff
4. **merge_conflict_resolver_test.dart** - UI разрешения конфликтов
5. **git_state_provider_test.dart** - State provider

---

## 🟡 ФАЗА 2: Средний приоритет

### 2.1. lsp_application (Application Layer для LSP)

**Текущее:** 6 тестов | **Цель:** 14 тестов

#### Недостающие тесты (8 новых)

##### Use Cases (5 тестов)
```
test/use_cases/
├── get_completions_use_case_test.dart (NEW)
├── get_diagnostics_use_case_test.dart (NEW)
├── get_hover_info_use_case_test.dart (NEW)
├── go_to_definition_use_case_test.dart (NEW)
└── find_references_use_case_test.dart (NEW)
```

##### Services (3 теста)
```
test/services/
├── diagnostic_service_test.dart (NEW)
├── semantic_tokens_service_test.dart (NEW)
└── editor_sync_service_test.dart (NEW)
```

---

### 2.2. ide_presentation (Presentation Layer + MobX)

**Текущее:** 3 теста | **Цель:** 11 тестов

#### Недостающие тесты (8 новых)

##### Stores (2 теста)
```
test/stores/
├── editor_store_test.dart ✅ (exists)
└── lsp_store_test.dart (NEW)
```

##### Widgets (5 тестов)
```
test/widgets/
├── editor_view_test.dart (NEW)
├── file_tree_explorer_test.dart (NEW)
├── completion_popup_test.dart (NEW)
├── diagnostics_panel_test.dart (NEW)
└── command_palette_test.dart (NEW)
```

##### Screens (1 тест)
```
test/screens/
└── ide_screen_test.dart ✅ (exists)
```

---

### 2.3. lsp_infrastructure (Infrastructure Layer для LSP)

**Текущее:** 0 тестов | **Цель:** 4 теста

#### Тесты для создания (4)

```
app/modules/lsp_infrastructure/test/
├── client/
│   └── websocket_lsp_client_repository_test.dart
├── protocol/
│   ├── json_rpc_protocol_test.dart
│   └── request_manager_test.dart
└── mappers/
    └── lsp_protocol_mappers_test.dart
```

##### 1. **websocket_lsp_client_repository_test.dart**
```dart
// Тесты:
// - WebSocket connection установка
// - Отправка JSON-RPC запросов
// - Получение ответов
// - Обработка ошибок
// - Reconnection логика
```

##### 2. **json_rpc_protocol_test.dart**
```dart
// Тесты:
// - Парсинг JSON-RPC 2.0
// - Создание запросов
// - Создание ответов
// - Обработка errors
```

##### 3. **request_manager_test.dart**
```dart
// Тесты:
// - Request ID generation
// - Request/Response сопоставление
// - Timeout handling
```

---

### 2.4. editor_ffi (FFI Infrastructure)

**Текущее:** 0 тестов | **Цель:** 2 теста

#### Тесты для создания (2)

```
app/modules/editor_ffi/test/
├── repository/
│   └── native_editor_repository_test.dart
└── ffi/
    └── native_bindings_test.dart
```

##### 1. **native_editor_repository_test.dart**
```dart
// Integration тесты:
// - Инициализация FFI
// - Открытие документа
// - Чтение/запись контента
// - Syntax highlighting
// - Memory management
```

---

### 2.5. editor_monaco (Monaco Infrastructure)

**Текущее:** 0 тестов | **Цель:** 2 теста

#### Тесты для создания (2)

```
app/modules/editor_monaco/test/
├── adapters/
│   └── monaco_editor_repository_test.dart
└── mappers/
    └── monaco_mappers_test.dart
```

---

## 🟢 ФАЗА 3: Низкий приоритет (дополнительные модули)

### 3.1. global_search

**Текущее:** 1 тест | **Цель:** 3 теста

#### Недостающие тесты (2 новых)
```
test/
├── services/
│   └── global_search_service_optimized_test.dart ✅ (exists)
├── models/
│   └── search_models_test.dart (NEW)
└── widgets/
    └── search_results_widget_test.dart (NEW)
```

---

### 3.2. minimap_enhancement

**Текущее:** 1 тест | **Цель:** 3 теста

#### Недостающие тесты (2 новых)
```
test/
├── services/
│   └── minimap_service_optimized_test.dart ✅ (exists)
├── models/
│   └── minimap_data_test.dart (NEW)
└── widgets/
    └── minimap_widget_test.dart (NEW)
```

---

### 3.3. dart_ide_enhancements

**Текущее:** 0 тестов | **Цель:** 2 теста

#### Тесты для создания (2)
```
app/modules/dart_ide_enhancements/test/
├── commands/
│   └── pub_commands_test.dart
└── widgets/
    └── pub_commands_panel_test.dart
```

---

### 3.4. js_ts_ide_enhancements

**Текущее:** 0 тестов | **Цель:** 2 теста

#### Тесты для создания (2)
```
app/modules/js_ts_ide_enhancements/test/
├── commands/
│   └── npm_commands_test.dart
└── widgets/
    └── npm_commands_panel_test.dart
```

---

## 🔧 Инфраструктура тестирования

### Общие зависимости

Добавить в каждый модуль с тестами:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
  flutter_riverpod: ^2.4.0
  bloc_test: ^9.1.0
  fake_async: ^1.3.1
```

### Test Helpers

Создать общие test helpers:

```
app/test/
├── helpers/
│   ├── mock_factories.dart         # Фабрики моков
│   ├── test_data_builders.dart     # Test data builders
│   └── custom_matchers.dart        # Custom matchers
└── fixtures/
    ├── git_responses.json
    ├── lsp_responses.json
    └── editor_documents.json
```

---

## 📈 Roadmap и Timeline

### Milestone 1: Критичные модули (4 недели)

**Неделя 1-2: lsp_domain + editor_core**
- [ ] Создать 13 тестов для lsp_domain
- [ ] Создать 9 тестов для editor_core
- [ ] Достичь 80%+ покрытия Domain слоя
- **Результат:** +22 теста

**Неделя 3-4: git_integration expansion**
- [ ] Добавить 35 тестов для git_integration
- [ ] Покрыть все Use Cases
- [ ] Протестировать Domain entities
- **Результат:** +35 тестов

**Итого Milestone 1:** +57 тестов (14 → 71)

---

### Milestone 2: Средний приоритет (3 недели)

**Неделя 5-6: lsp_application + lsp_infrastructure**
- [ ] Добавить 8 тестов для lsp_application
- [ ] Создать 4 теста для lsp_infrastructure
- **Результат:** +12 тестов

**Неделя 7: ide_presentation + editor adapters**
- [ ] Добавить 8 тестов для ide_presentation
- [ ] Создать 2 теста для editor_ffi
- [ ] Создать 2 теста для editor_monaco
- **Результат:** +12 тестов

**Итого Milestone 2:** +24 теста (71 → 95)

---

### Milestone 3: Дополнительные модули (1 неделя)

**Неделя 8: Finalization**
- [ ] Добавить 2 теста для global_search
- [ ] Добавить 2 теста для minimap_enhancement
- [ ] Создать 2 теста для dart_ide_enhancements
- [ ] Создать 2 теста для js_ts_ide_enhancements
- **Результат:** +8 тестов

**Итого Milestone 3:** +8 тестов (95 → 103)

---

## 🎯 Финальные метрики

### Целевое состояние

| Метрика | Текущее | Целевое | Прогресс |
|---------|---------|---------|----------|
| Всего тестов | 14 | 103 | +89 |
| Покрытие | ~7% | ~50% | +43% |
| Модулей с тестами | 5/12 | 12/12 | 100% |

### Покрытие по слоям

| Слой | Файлов | Целевое покрытие |
|------|--------|------------------|
| Domain | 44 | 60%+ |
| Application | 27 | 50%+ |
| Infrastructure | 15 | 40%+ |
| Presentation | 22 | 45%+ |

---

## 🚀 Рекомендации по реализации

### Порядок действий для каждого модуля

1. **Создать структуру test/**
   ```bash
   mkdir -p app/modules/{module}/test/{domain,application,infrastructure,presentation}
   ```

2. **Настроить pubspec.yaml**
   - Добавить dev_dependencies
   - Настроить test configuration

3. **Создать базовые моки**
   - Mock repositories
   - Mock services
   - Test fixtures

4. **Написать тесты по приоритету**
   - Domain entities (unit)
   - Use cases (unit + integration)
   - Repositories (integration)
   - Widgets (widget tests)

5. **Запустить тесты**
   ```bash
   cd app/modules/{module}
   flutter test --coverage
   ```

6. **Проверить покрытие**
   ```bash
   lcov --summary coverage/lcov.info
   ```

### Best Practices

1. **AAA Pattern** - Arrange, Act, Assert
2. **Given-When-Then** для BDD стиля
3. **One assertion per test** (где возможно)
4. **Descriptive test names** - `test('should return error when repository path is invalid')`
5. **Test data builders** для сложных объектов
6. **Shared test fixtures** для переиспользования данных

### CI/CD Integration

Добавить в `.github/workflows/test.yml`:

```yaml
name: Test Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      # Тесты для каждого модуля
      - name: Test lsp_domain
        run: |
          cd app/modules/lsp_domain
          flutter test --coverage

      - name: Test git_integration
        run: |
          cd app/modules/git_integration
          flutter test --coverage

      # ... остальные модули

      # Объединить coverage
      - name: Merge coverage
        run: |
          lcov --add-tracefile app/modules/*/coverage/lcov.info \
               --output-file coverage/lcov.info

      # Upload to Codecov
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

---

## 📝 Чек-лист по модулям

### Domain Layer
- [ ] lsp_domain - 13 тестов
- [ ] editor_core - 9 тестов
- [ ] git_integration/domain - 12 тестов

### Application Layer
- [ ] lsp_application - 8 тестов (добавить к существующим 6)
- [ ] git_integration/application - 15 тестов

### Infrastructure Layer
- [ ] lsp_infrastructure - 4 теста
- [ ] editor_ffi - 2 теста
- [ ] editor_monaco - 2 теста
- [ ] git_integration/infrastructure - 3 теста

### Presentation Layer
- [ ] ide_presentation - 8 тестов (добавить к существующим 3)
- [ ] git_integration/presentation - 5 тестов

### Services & Utilities
- [ ] global_search - 2 теста (добавить к существующему 1)
- [ ] minimap_enhancement - 2 теста (добавить к существующему 1)
- [ ] dart_ide_enhancements - 2 теста
- [ ] js_ts_ide_enhancements - 2 теста

---

## 📚 Ресурсы и документация

### Flutter Testing Documentation
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget)
- [Integration Testing](https://docs.flutter.dev/cookbook/testing/integration)

### Testing Libraries
- [Mockito](https://pub.dev/packages/mockito)
- [Mocktail](https://pub.dev/packages/mocktail)
- [Bloc Test](https://pub.dev/packages/bloc_test)

### Best Practices
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Test-Driven Development in Flutter](https://resocoder.com/flutter-tdd-clean-architecture-course/)

---

## ✅ Критерии успеха

### Количественные метрики
- ✅ Минимум 103 тестовых файла
- ✅ 50%+ line coverage
- ✅ 100% модулей имеют тесты
- ✅ 0 failed tests в CI

### Качественные метрики
- ✅ Каждый модуль независим
- ✅ Тесты быстро выполняются (<5 min все)
- ✅ Понятные имена тестов
- ✅ Хорошие error messages
- ✅ Minimal flakiness

---

## 🎓 Заключение

Этот план обеспечивает:

1. **Систематический подход** - покрытие по слоям Clean Architecture
2. **Модульную независимость** - каждый модуль имеет свои тесты
3. **Приоритизацию** - критичные модули сначала
4. **Достижимость** - реалистичный timeline (8 недель)
5. **Масштабируемость** - легко добавлять новые тесты

**Следующие шаги:**
1. Review этого плана с командой
2. Начать с Milestone 1 (lsp_domain + editor_core)
3. Настроить CI/CD для автоматического запуска тестов
4. Еженедельный мониторинг прогресса

---

**Автор:** Claude AI
**Дата:** 2025-11-18
**Версия:** 1.0
