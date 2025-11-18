# ДОПОЛНИТЕЛЬНЫЙ ОТЧЁТ ПО БАГАМ

**Дата**: 2025-01-18 (Вторая итерация глубокой проверки)
**Статус**: ⚠️ **Найдено 8 новых критических багов**

---

## 🔴 НОВЫЕ КРИТИЧЕСКИЕ БАГИ

После первой итерации исправлений было найдено ещё **8 критических багов**, которые не позволят коду скомпилироваться и тестам запуститься.

| # | Баг | Серьёзность | Файл |
|---|-----|------------|------|
| 9 | IDownloadService.download() - неправильные параметры | 🔴 COMPILATION ERROR | install_runtime_command_handler.dart:221 |
| 10 | Двойной вызов markModuleVerified() | 🟡 LOGIC ERROR | install_runtime_command_handler.dart:242,256 |
| 11 | Конфликт типов CancelToken | 🟡 TYPE CONFLICT | install_runtime_command_handler.dart:3,47 |
| 12 | PlatformIdentifier.toDisplayString() не существует | 🔴 COMPILATION ERROR | module_info_dto.dart:43 |
| 13 | MockManifestRepository.getModules() - неправильный параметр | 🔴 TEST FAILURE | mock_repositories.dart:93 |
| 14 | MockRuntimeRepository - множественные несоответствия | 🔴 TEST FAILURE | mock_repositories.dart |
| 15 | MockManifestRepository - множественные несоответствия | 🔴 TEST FAILURE | mock_repositories.dart |
| 16 | MockVerificationService.verify() - отсутствует параметр | 🔴 TEST FAILURE | mock_services.dart:71 |

---

## 📋 ДЕТАЛЬНОЕ ОПИСАНИЕ БАГОВ

### БАГ #9: IDownloadService.download() - Неправильные параметры ⚠️

**Серьёзность**: 🔴 COMPILATION ERROR
**Файл**: `packages/vscode_runtime_application/lib/src/handlers/install_runtime_command_handler.dart:221-229`

**Проблема**:
```dart
// Handler вызывает (строка 221):
final downloadResult = await _downloadService.download(
  url: artifact.url,
  targetPath: targetPath,  // ❌ Параметр не существует!
  onProgress: (downloaded, total) {
    final progress = downloaded.progressTo(total);
    onProgress?.call(module.id, progress * 0.6);
  },
  cancelToken: cancelToken,
);
```

**Интерфейс требует** (`i_download_service.dart:12-17`):
```dart
Future<Either<DomainException, File>> download({
  required DownloadUrl url,
  required ByteSize expectedSize,  // ✅ Правильный параметр
  void Function(ByteSize received, ByteSize total)? onProgress,
  CancelToken? cancelToken,
});
```

**Решение**:
- Заменить `targetPath: targetPath` на `expectedSize: artifact.size`
- Удалить логику создания targetPath (строка 219)
- Сервис сам определяет, куда сохранить файл

---

### БАГ #10: Двойной вызов markModuleVerified() ⚠️

**Серьёзность**: 🟡 LOGIC ERROR
**Файл**: `packages/vscode_runtime_application/lib/src/handlers/install_runtime_command_handler.dart:242,256`

**Проблема**:
```dart
// Строка 242: Вызывается ДО верификации
current = current.markModuleVerified(module.id);

final verifyResult = await _verificationService.verify(
  file: downloadedFile,
  expectedHash: artifact.hash,
  expectedSize: artifact.size,
);

if (verifyResult.isLeft()) {
  return left(ApplicationException(...));
}

// Строка 256: Вызывается ПОСЛЕ верификации (правильно)
current = current.markModuleVerified(module.id);
```

**Решение**: Удалить первый вызов на строке 242

---

### БАГ #11: Конфликт типов CancelToken ⚠️

**Серьёзность**: 🟡 TYPE CONFLICT
**Файл**: `packages/vscode_runtime_application/lib/src/handlers/install_runtime_command_handler.dart`

**Проблема**:
```dart
// Строка 3: Импортирует Dio
import 'package:dio/dio.dart';

// Строка 47: Кастит к CancelToken (но какому?)
if (command.cancelToken != null) {
  cancelToken = command.cancelToken as CancelToken;  // ❌ Dio или Domain?
}
```

**Domain Core определяет свой CancelToken** (`i_download_service.dart:26-35`):
```dart
class CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() {
    _isCancelled = true;
  }
}
```

**Решение**:
- Удалить `import 'package:dio/dio.dart'` из handler
- Использовать только domain CancelToken
- Или переименовать domain CancelToken в RuntimeCancelToken

---

### БАГ #12: PlatformIdentifier.toDisplayString() не существует ⚠️

**Серьёзность**: 🔴 COMPILATION ERROR
**Файл**: `packages/vscode_runtime_application/lib/src/dtos/module_info_dto.dart:43`

**Проблема**:
```dart
supportedPlatforms: module.supportedPlatforms
    .map((p) => p.toDisplayString())  // ❌ Метод не существует!
    .toList(),
```

**PlatformIdentifier имеет** (`platform_identifier.dart`):
```dart
String get identifier => '$os-$architecture';  // ✅ Есть
String toString() => identifier;               // ✅ Есть
// toDisplayString() - НЕТ!
```

**Решение**: Заменить `p.toDisplayString()` на `p.identifier` или `p.toString()`

---

### БАГ #13: MockManifestRepository.getModules() - Неправильный параметр ⚠️

**Серьёзность**: 🔴 TEST FAILURE
**Файл**: `packages/vscode_runtime_application/test/mocks/mock_repositories.dart:93`

**Проблема**:
```dart
// Mock (НЕПРАВИЛЬНО):
@override
Future<Either<DomainException, List<RuntimeModule>>> getModules({
  RuntimeVersion? version,  // ❌ Неправильный параметр!
}) async {
  return right(_modules);
}
```

**Интерфейс требует** (после исправления бага #2):
```dart
Future<Either<DomainException, List<RuntimeModule>>> getModules([
  PlatformIdentifier? platform,  // ✅ Правильный параметр
]);
```

**Решение**: Изменить параметр на `PlatformIdentifier? platform`

---

### БАГ #14: MockRuntimeRepository - Множественные несоответствия ⚠️

**Серьёзность**: 🔴 TEST FAILURE
**Файл**: `packages/vscode_runtime_application/test/mocks/mock_repositories.dart`

**Проблемы**:

1. **Неправильная сигнатура loadInstallation()**:
```dart
// Mock имеет (строка 24):
Future<Either<DomainException, Option<RuntimeInstallation>>> getInstallation(
  InstallationId id,  // ❌ Только 1 параметр, неправильное имя
)

// Интерфейс требует (после исправления бага #4):
Future<Either<DomainException, Option<RuntimeInstallation>>> loadInstallation(
  InstallationId installationId,
  List<RuntimeModule> modules,  // ✅ Нужен второй параметр!
)
```

2. **Неправильное имя метода saveInstalledVersion()**:
```dart
// Mock имеет (строка 42):
Future<Either<DomainException, Unit>> setInstalledVersion(RuntimeVersion version)

// Интерфейс требует:
Future<Either<DomainException, Unit>> saveInstalledVersion(RuntimeVersion version)
```

3. **Неправильное имя метода getInstallationHistory()**:
```dart
// Mock имеет (строка 67):
Future<Either<DomainException, List<RuntimeInstallation>>> getAllInstallations()

// Интерфейс требует:
Future<Either<DomainException, List<RuntimeInstallation>>> getInstallationHistory()
```

4. **Лишние методы, которых нет в интерфейсе**:
   - `getAvailableModules()` (строка 36)
   - `setModuleInstalled(ModuleId, bool)` (строка 48)
   - `removeModule(ModuleId)` (строка 61)

**Решение**: Полная переработка mock для соответствия IRuntimeRepository

---

### БАГ #15: MockManifestRepository - Множественные несоответствия ⚠️

**Серьёзность**: 🔴 TEST FAILURE
**Файл**: `packages/vscode_runtime_application/test/mocks/mock_repositories.dart`

**Проблемы**:

1. **getModule() с лишним параметром**:
```dart
// Mock имеет (строка 108):
Future<Either<DomainException, Option<RuntimeModule>>> getModule(
  ModuleId moduleId, {
  RuntimeVersion? version,  // ❌ Лишний параметр!
})

// Интерфейс требует:
Future<Either<DomainException, Option<RuntimeModule>>> getModule(
  ModuleId moduleId,  // ✅ Только один параметр
)
```

2. **Метод refreshManifest() вместо fetchManifest()**:
```dart
// Mock имеет (строка 117):
Future<Either<DomainException, Unit>> refreshManifest()

// Интерфейс требует:
Future<Either<DomainException, RuntimeManifest>> fetchManifest()
```

3. **Лишний метод getLatestVersion()**:
```dart
// Mock имеет (строка 100):
Future<Either<DomainException, RuntimeVersion>> getLatestVersion()
// ❌ Этого метода нет в IManifestRepository!
```

**Решение**: Полная переработка mock для соответствия IManifestRepository

---

### БАГ #16: MockVerificationService.verify() - Отсутствует параметр ⚠️

**Серьёзность**: 🔴 TEST FAILURE
**Файл**: `packages/vscode_runtime_application/test/mocks/mock_services.dart:71`

**Проблема**:
```dart
// Mock имеет:
@override
Future<Either<DomainException, Unit>> verify({
  required File file,
  required SHA256Hash expectedHash,  // ❌ Только 2 параметра!
}) async {
  if (_shouldFail) {
    return left(VerificationException('Hash mismatch'));
  }
  return right(unit);
}
```

**Интерфейс требует** (`i_verification_service.dart:26-30`):
```dart
Future<Either<VerificationException, Unit>> verify({
  required File file,
  required SHA256Hash expectedHash,
  required ByteSize expectedSize,  // ✅ Нужен третий параметр!
});
```

**Решение**: Добавить параметр `required ByteSize expectedSize`

---

## 📊 СТАТИСТИКА БАГОВ

### По категориям:

| Категория | Количество |
|-----------|------------|
| Compilation Errors | 3 (баги #9, #12, все тесты) |
| Test Failures | 4 (баги #13, #14, #15, #16) |
| Logic Errors | 1 (баг #10) |
| Type Conflicts | 1 (баг #11) |
| **ВСЕГО** | **8 новых багов** |

### Общая статистика (с первой итерацией):

| Итерация | Баги найдены | Баги исправлены |
|----------|--------------|-----------------|
| 1-я | 8 | 8 ✅ |
| 2-я | 8 | 0 ⚠️ |
| **ВСЕГО** | **16** | **8** |

---

## 🎯 ПРИОРИТЕТ ИСПРАВЛЕНИЯ

### Критические (блокируют компиляцию):
1. ✅ **БАГ #9** - IDownloadService.download() параметры
2. ✅ **БАГ #12** - PlatformIdentifier.toDisplayString()

### Критические (блокируют тесты):
3. ✅ **БАГ #13** - MockManifestRepository.getModules()
4. ✅ **БАГ #14** - MockRuntimeRepository полная переработка
5. ✅ **БАГ #15** - MockManifestRepository полная переработка
6. ✅ **БАГ #16** - MockVerificationService.verify()

### Средние (логические ошибки):
7. ✅ **БАГ #10** - Двойной вызов markModuleVerified()
8. ✅ **БАГ #11** - Конфликт типов CancelToken

---

## 📁 ЗАТРОНУТЫЕ ФАЙЛЫ

```
packages/vscode_runtime_application/
├── lib/src/handlers/
│   └── install_runtime_command_handler.dart     [НУЖНО ИСПРАВИТЬ]
├── lib/src/dtos/
│   └── module_info_dto.dart                     [НУЖНО ИСПРАВИТЬ]
└── test/mocks/
    ├── mock_repositories.dart                    [НУЖНО ПЕРЕПИСАТЬ]
    └── mock_services.dart                        [НУЖНО ИСПРАВИТЬ]

packages/vscode_runtime_core/lib/src/
├── domain/value_objects/
│   └── platform_identifier.dart                  [НУЖНО ДОБАВИТЬ МЕТОД]
└── ports/services/
    └── i_download_service.dart                   [ВОЗМОЖНО ПЕРЕИМЕНОВАТЬ CancelToken]
```

---

## ✅ ПЛАН ДЕЙСТВИЙ

1. Исправить handler (баги #9, #10)
2. Добавить метод toDisplayString() в PlatformIdentifier (баг #12)
3. Полностью переписать mock_repositories.dart (баги #13, #14, #15)
4. Исправить MockVerificationService (баг #16)
5. Решить проблему с CancelToken (баг #11)
6. Запустить build_runner
7. Проверить компиляцию
8. Запустить тесты

---

*Отчёт создан: 2025-01-18*
*Итерация: 2*
*Всего найдено багов: 16*
