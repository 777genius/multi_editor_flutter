# Quick Start: Интеграция тестов IDE

Быстрое руководство по началу работы с планом тестирования для достижения 50% покрытия.

---

## 📋 Краткое резюме

**Текущее состояние:** 14 тестов (~7% покрытие)
**Цель:** 103 теста (~50% покрытие)
**Необходимо добавить:** 89 тестов
**Timeline:** 8 недель

---

## 🚀 Быстрый старт

### Шаг 1: Изучите документацию

1. **TEST_COVERAGE_PLAN.md** - Полный план тестирования (103 теста)
2. **TEST_EXAMPLES.md** - Примеры тестов для каждого слоя
3. **TESTING_QUICKSTART.md** (этот файл) - Быстрый старт

### Шаг 2: Выберите модуль для начала

Рекомендуем начать с **Milestone 1** (Недели 1-2):

```bash
# Приоритет 1: lsp_domain
cd app/modules/lsp_domain

# Приоритет 2: editor_core
cd app/modules/editor_core
```

### Шаг 3: Создайте структуру тестов

Для **lsp_domain**:

```bash
cd app/modules/lsp_domain
mkdir -p test/{entities,value_objects,failures,repositories}
```

Для **editor_core**:

```bash
cd app/modules/editor_core
mkdir -p test/{entities,value_objects,failures,repositories}
```

### Шаг 4: Настройте pubspec.yaml

Добавьте в `pubspec.yaml` модуля:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
  fake_async: ^1.3.1
```

Установите зависимости:

```bash
flutter pub get
```

### Шаг 5: Создайте первый тест

Скопируйте пример из `TEST_EXAMPLES.md` и адаптируйте под свой код.

Для **lsp_domain**, создайте `test/entities/lsp_session_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('LspSession', () {
    test('should create session with valid data', () {
      // Arrange
      final sessionId = SessionId.generate();

      // Act
      final session = LspSession(
        id: sessionId,
        languageId: const LanguageId('dart'),
        state: SessionState.uninitialized,
        rootUri: DocumentUri.fromString('file:///project')
            .getOrElse(() => throw Exception()),
        createdAt: DateTime.now(),
      );

      // Assert
      expect(session.id, equals(sessionId));
      expect(session.state, equals(SessionState.uninitialized));
    });
  });
}
```

### Шаг 6: Запустите тест

```bash
flutter test test/entities/lsp_session_test.dart
```

### Шаг 7: Проверьте покрытие

```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

---

## 📊 План по неделям

### Неделя 1-2: lsp_domain + editor_core (22 теста)

**lsp_domain (13 тестов):**

```bash
cd app/modules/lsp_domain
```

1. Создать `test/entities/lsp_session_test.dart`
2. Создать `test/entities/diagnostic_test.dart`
3. Создать `test/entities/completion_list_test.dart`
4. Создать `test/entities/hover_info_test.dart`
5. Создать `test/entities/code_lens_test.dart`
6. Создать `test/entities/code_action_test.dart`
7. Создать `test/entities/document_symbol_test.dart`
8. Создать `test/value_objects/session_id_test.dart`
9. Создать `test/failures/lsp_failure_test.dart`
10-13. Остальные entities

**editor_core (9 тестов):**

```bash
cd app/modules/editor_core
```

1. Создать `test/entities/editor_document_test.dart`
2. Создать `test/entities/cursor_position_test.dart`
3. Создать `test/entities/text_selection_test.dart`
4. Создать `test/entities/editor_theme_test.dart`
5. Создать `test/value_objects/language_id_test.dart`
6. Создать `test/value_objects/document_uri_test.dart`
7. Создать `test/failures/editor_failure_test.dart`
8-9. Остальные тесты

**Чек-лист Недели 1-2:**

- [ ] lsp_domain: 13 тестов
- [ ] editor_core: 9 тестов
- [ ] Все тесты проходят
- [ ] Coverage report сгенерирован
- [ ] **Результат: +22 теста (14 → 36)**

---

### Неделя 3-4: git_integration expansion (35 тестов)

**git_integration (35 новых тестов):**

```bash
cd app/modules/git_integration
```

**Domain (12 тестов):**
1. `test/domain/entities/git_repository_test.dart`
2. `test/domain/entities/git_commit_test.dart`
3. `test/domain/entities/git_branch_test.dart`
4. `test/domain/entities/merge_conflict_test.dart`
5. `test/domain/value_objects/repository_path_test.dart`
6. `test/domain/value_objects/branch_name_test.dart`
7. `test/domain/value_objects/commit_hash_test.dart`
8. `test/domain/services/conflict_detector_test.dart`
9-12. Остальные entities

**Application (15 тестов):**
1. `test/application/use_cases/init_repository_use_case_test.dart`
2. `test/application/use_cases/clone_repository_use_case_test.dart`
3. `test/application/use_cases/commit_changes_use_case_test.dart`
4. `test/application/use_cases/push_changes_use_case_test.dart`
5. `test/application/use_cases/pull_changes_use_case_test.dart`
6. `test/application/use_cases/merge_branch_use_case_test.dart`
7. `test/application/services/git_service_test.dart`
8-15. Остальные use cases

**Infrastructure (3 теста):**
1. `test/infrastructure/repositories/git_cli_repository_test.dart`
2. `test/infrastructure/adapters/git_command_adapter_test.dart`
3. `test/infrastructure/adapters/git_parser_adapter_test.dart`

**Presentation (5 тестов):**
1. `test/presentation/widgets/git_panel_test.dart`
2. `test/presentation/widgets/commit_dialog_test.dart`
3. `test/presentation/widgets/diff_viewer_test.dart`
4. `test/presentation/widgets/merge_conflict_resolver_test.dart`
5. `test/presentation/providers/git_state_provider_test.dart`

**Чек-лист Недели 3-4:**

- [ ] Domain: 12 тестов
- [ ] Application: 15 тестов
- [ ] Infrastructure: 3 теста
- [ ] Presentation: 5 тестов
- [ ] **Результат: +35 тестов (36 → 71)**

---

### Неделя 5-6: lsp_application + lsp_infrastructure (12 тестов)

**lsp_application (8 новых тестов):**

```bash
cd app/modules/lsp_application
```

1. `test/use_cases/get_completions_use_case_test.dart`
2. `test/use_cases/get_diagnostics_use_case_test.dart`
3. `test/use_cases/get_hover_info_use_case_test.dart`
4. `test/use_cases/go_to_definition_use_case_test.dart`
5. `test/use_cases/find_references_use_case_test.dart`
6. `test/services/diagnostic_service_test.dart`
7. `test/services/semantic_tokens_service_test.dart`
8. `test/services/editor_sync_service_test.dart`

**lsp_infrastructure (4 теста):**

```bash
cd app/modules/lsp_infrastructure
```

1. `test/client/websocket_lsp_client_repository_test.dart`
2. `test/protocol/json_rpc_protocol_test.dart`
3. `test/protocol/request_manager_test.dart`
4. `test/mappers/lsp_protocol_mappers_test.dart`

**Чек-лист Недели 5-6:**

- [ ] lsp_application: 8 тестов
- [ ] lsp_infrastructure: 4 теста
- [ ] **Результат: +12 тестов (71 → 83)**

---

### Неделя 7: ide_presentation + editor adapters (12 тестов)

**ide_presentation (8 новых тестов):**

```bash
cd app/modules/ide_presentation
```

1. `test/stores/lsp_store_test.dart`
2. `test/widgets/editor_view_test.dart`
3. `test/widgets/file_tree_explorer_test.dart`
4. `test/widgets/completion_popup_test.dart`
5. `test/widgets/diagnostics_panel_test.dart`
6. `test/widgets/command_palette_test.dart`
7-8. Остальные widgets

**editor_ffi (2 теста):**

```bash
cd app/modules/editor_ffi
```

1. `test/repository/native_editor_repository_test.dart`
2. `test/ffi/native_bindings_test.dart`

**editor_monaco (2 теста):**

```bash
cd app/modules/editor_monaco
```

1. `test/adapters/monaco_editor_repository_test.dart`
2. `test/mappers/monaco_mappers_test.dart`

**Чек-лист Недели 7:**

- [ ] ide_presentation: 8 тестов
- [ ] editor_ffi: 2 теста
- [ ] editor_monaco: 2 теста
- [ ] **Результат: +12 тестов (83 → 95)**

---

### Неделя 8: Finalization (8 тестов)

**Дополнительные модули:**

```bash
# global_search (2 теста)
cd app/modules/global_search
# Создать test/models/search_models_test.dart
# Создать test/widgets/search_results_widget_test.dart

# minimap_enhancement (2 теста)
cd app/modules/minimap_enhancement
# Создать test/models/minimap_data_test.dart
# Создать test/widgets/minimap_widget_test.dart

# dart_ide_enhancements (2 теста)
cd app/modules/dart_ide_enhancements
# Создать test/commands/pub_commands_test.dart
# Создать test/widgets/pub_commands_panel_test.dart

# js_ts_ide_enhancements (2 теста)
cd app/modules/js_ts_ide_enhancements
# Создать test/commands/npm_commands_test.dart
# Создать test/widgets/npm_commands_panel_test.dart
```

**Чек-лист Недели 8:**

- [ ] global_search: 2 теста
- [ ] minimap_enhancement: 2 теста
- [ ] dart_ide_enhancements: 2 теста
- [ ] js_ts_ide_enhancements: 2 теста
- [ ] **Результат: +8 тестов (95 → 103)**

---

## 🔧 Полезные команды

### Запуск тестов

```bash
# Запустить все тесты модуля
flutter test

# Запустить конкретный тест
flutter test test/entities/lsp_session_test.dart

# Запустить с coverage
flutter test --coverage

# Запустить с verbose output
flutter test --verbose
```

### Проверка покрытия

```bash
# Сгенерировать coverage
flutter test --coverage

# Показать summary
lcov --summary coverage/lcov.info

# Показать детальный отчет
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Генерация моков

```bash
# Для mockito
flutter pub run build_runner build

# Watch mode (автоматическая регенерация)
flutter pub run build_runner watch
```

### CI/CD

Запустить все тесты для всех модулей:

```bash
#!/bin/bash
# test_all_modules.sh

modules=(
  "lsp_domain"
  "lsp_application"
  "lsp_infrastructure"
  "editor_core"
  "editor_ffi"
  "editor_monaco"
  "git_integration"
  "ide_presentation"
  "global_search"
  "minimap_enhancement"
  "dart_ide_enhancements"
  "js_ts_ide_enhancements"
)

for module in "${modules[@]}"; do
  echo "Testing $module..."
  cd "app/modules/$module"
  flutter test --coverage || exit 1
  cd -
done

echo "All tests passed!"
```

---

## 📝 Чек-лист перед началом

### Подготовка

- [ ] Прочитал TEST_COVERAGE_PLAN.md
- [ ] Изучил примеры в TEST_EXAMPLES.md
- [ ] Понял структуру Clean Architecture
- [ ] Настроил IDE для тестирования

### Для каждого модуля

- [ ] Создал структуру test/
- [ ] Настроил pubspec.yaml
- [ ] Создал базовые моки
- [ ] Написал первый тест
- [ ] Убедился что тест проходит
- [ ] Проверил coverage

### Перед коммитом

- [ ] Все тесты проходят
- [ ] Coverage не уменьшилось
- [ ] Нет warnings
- [ ] Код отформатирован

---

## 🎯 Метрики успеха

### По неделям

| Неделя | Добавлено тестов | Всего тестов | Покрытие |
|--------|------------------|--------------|----------|
| 0 (старт) | 0 | 14 | ~7% |
| 1-2 | +22 | 36 | ~18% |
| 3-4 | +35 | 71 | ~35% |
| 5-6 | +12 | 83 | ~41% |
| 7 | +12 | 95 | ~47% |
| 8 | +8 | 103 | ~50% |

### Критерии завершения

- ✅ Минимум 103 тестовых файла
- ✅ 50%+ line coverage
- ✅ 100% модулей имеют тесты
- ✅ 0 failed tests
- ✅ CI/CD настроен и работает

---

## 🆘 Troubleshooting

### Проблема: Тесты не запускаются

**Решение:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
```

### Проблема: Mockito не генерирует моки

**Решение:**
```bash
# Убедитесь что есть @GenerateMocks аннотация
# Запустите build_runner
flutter pub run build_runner build --delete-conflicting-outputs
```

### Проблема: Coverage показывает 0%

**Решение:**
```bash
# Убедитесь что файлы не в test/ директории
# Проверьте что тесты действительно выполняются
flutter test --coverage --verbose
```

### Проблема: Тесты падают с FFI errors

**Решение:**
```bash
# FFI тесты требуют native библиотеки
# Используйте integration тесты или моки для FFI
```

---

## 📚 Дополнительные ресурсы

### Документация

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Clean Architecture Testing](https://resocoder.com/flutter-tdd-clean-architecture-course/)

### Примеры в проекте

- `app/modules/git_integration/test/` - Хорошие примеры
- `app/modules/lsp_application/test/` - Use case тесты
- `app/modules/ide_presentation/test/` - Widget тесты

### Помощь

Если застряли:
1. Проверьте TEST_EXAMPLES.md
2. Посмотрите существующие тесты в git_integration
3. Изучите документацию Flutter Testing

---

## ✅ Следующие шаги

1. **Прочитайте весь TESTING_QUICKSTART.md**
2. **Начните с Недели 1-2** (lsp_domain + editor_core)
3. **Создайте первый тест** для lsp_session
4. **Запустите и убедитесь что проходит**
5. **Продолжайте по плану**

**Удачи с тестированием!** 🚀
