# 🚀 Flutter IDE - Quick Start Guide

Полное руководство по запуску Flutter IDE в dev и prod режимах.

## 📋 Содержание

1. [Требования](#требования)
2. [Установка](#установка)
3. [Development Mode](#development-mode)
4. [Production Build](#production-build)
5. [Платформы](#платформы)
6. [Troubleshooting](#troubleshooting)

---

## ✅ Требования

### Обязательные

- **Flutter SDK** >= 3.8.0
  ```bash
  flutter --version
  ```
  Установка: https://flutter.dev/docs/get-started/install

- **Rust** >= 1.70.0
  ```bash
  rustc --version
  cargo --version
  ```
  Установка: https://rustup.rs/

- **Dart SDK** (входит в Flutter)

### Опциональные

- **make** (для Makefile команд)
- **melos** (для monorepo управления)
  ```bash
  dart pub global activate melos
  ```

---

## 📦 Установка

### Вариант 1: Quick Start (рекомендуется)

```bash
# Из корня проекта /app
make setup
```

Это выполнит:
1. ✅ Установку всех Dart зависимостей (melos bootstrap)
2. ✅ Сборку Rust компонентов (editor_native, lsp_bridge)
3. ✅ Генерацию кода (MobX, Injectable, Freezed)

### Вариант 2: Manual Setup

```bash
# 1. Установить зависимости
cd /path/to/multi_editor_flutter
melos bootstrap

# 2. Собрать Rust компоненты
cd app
make build-rust

# 3. Сгенерировать код
make codegen
```

---

## 🔧 Development Mode

### Способ 1: Автоматический запуск (рекомендуется)

```bash
cd app

# Запустить LSP Bridge + Flutter app одновременно
make quickstart
```

Это запустит:
- **LSP Bridge Server** на ws://127.0.0.1:9999
- **Flutter app** в dev режиме с hot reload

### Способ 2: Shell Script

```bash
cd app

# Запустить dev окружение
./scripts/dev.sh
```

### Способ 3: Manual (два терминала)

**Терминал 1 - LSP Bridge Server:**
```bash
cd app
make run-lsp-bridge-dev

# Или напрямую:
cd app/modules/lsp_bridge
RUST_LOG=debug cargo run
```

**Терминал 2 - Flutter App:**
```bash
cd app
make run-dev

# Или напрямую:
flutter run -d linux
```

### Hot Reload

Когда приложение запущено:
- **`r`** - Hot reload (быстрый перезапуск UI)
- **`R`** - Hot restart (полный перезапуск)
- **`q`** - Quit

---

## 🏗️ Production Build

### Сборка для Linux

```bash
cd app

# Способ 1: Makefile
make build-linux

# Способ 2: Shell script
./scripts/prod.sh linux

# Способ 3: Manual
flutter build linux --release
```

**Результат:** `build/linux/x64/release/bundle/`

### Сборка для Web

```bash
cd app

# Способ 1: Makefile
make build-web

# Способ 2: Shell script
./scripts/prod.sh web

# Способ 3: Manual
flutter build web --release --web-renderer canvaskit
```

**Результат:** `build/web/`

### Сборка для macOS

```bash
cd app
make build-macos

# Или
./scripts/prod.sh macos
```

**Результат:** `build/macos/Build/Products/Release/`

### Сборка для Windows

```bash
cd app
make build-windows

# Или
./scripts/prod.sh windows
```

**Результат:** `build/windows/runner/Release/`

### Сборка всех платформ

```bash
cd app
make build-all
```

---

## 🎯 Платформы

### Linux (Desktop)

```bash
# Dev
make run-dev

# Prod
make run-prod

# Build
make build-linux
```

**Требования:**
- Linux Desktop environment
- GTK3 development headers

### Web (Browser)

```bash
# Dev
make run-web

# Build
make build-web
```

Открывается в Chrome с CanvasKit renderer (лучшая производительность).

### macOS (Desktop)

```bash
# Dev
make run-macos

# Build
make build-macos
```

**Требования:**
- macOS 10.14+
- Xcode

### Windows (Desktop)

```bash
# Dev
make run-windows

# Build
make build-windows
```

**Требования:**
- Windows 10+
- Visual Studio 2022

---

## 📝 Makefile Команды

### Setup & Installation
```bash
make setup           # Полная установка (dependencies + build + codegen)
make install         # Только Flutter зависимости
```

### Code Generation
```bash
make codegen         # Сгенерировать код (MobX, Injectable, Freezed)
make codegen-watch   # Watch режим (auto-generate on save)
```

### Rust Components
```bash
make build-rust      # Build Rust (release mode)
make build-rust-dev  # Build Rust (debug mode)
make run-lsp-bridge  # Запустить LSP Bridge (release)
make run-lsp-bridge-dev  # Запустить LSP Bridge (debug)
```

### Development
```bash
make run-dev         # Запустить Flutter app (dev)
make run-web         # Запустить в браузере
make run-macos       # Запустить на macOS
make run-windows     # Запустить на Windows
```

### Production
```bash
make run-prod        # Запустить Flutter app (release)
make build-linux     # Build for Linux
make build-web       # Build for Web
make build-macos     # Build for macOS
make build-windows   # Build for Windows
make build-all       # Build for all platforms
```

### Testing
```bash
make test            # Запустить тесты
make test-coverage   # Тесты с coverage
make lint            # Запустить linter
make format          # Форматировать код
```

### Cleanup
```bash
make clean           # Очистить build артефакты
make clean-generated # Очистить сгенерированный код
make reset           # Полный reset (clean + dependencies)
```

### Quick Start
```bash
make quickstart      # Setup + запуск dev окружения
make dev             # Показать инструкции для dev
make help            # Показать все команды
```

---

## 🐛 Troubleshooting

### LSP Bridge не запускается

**Проблема:** `Error: LSP Bridge failed to start`

**Решение:**
```bash
# Пересобрать Rust компоненты
cd app/modules/lsp_bridge
cargo clean
cargo build --release

# Проверить запуск
cargo run
```

### Port 9999 занят

**Проблема:** `Address already in use (os error 98)`

**Решение:**
```bash
# Найти процесс на порту 9999
lsof -i :9999

# Убить процесс
kill -9 <PID>

# Или изменить порт в конфигурации
```

### Flutter pub get ошибки

**Проблема:** Ошибки при установке зависимостей

**Решение:**
```bash
# Очистить кеш
flutter clean
flutter pub cache repair

# Переустановить
flutter pub get
```

### MobX code generation ошибки

**Проблема:** `*.g.dart` файлы не генерируются

**Решение:**
```bash
# Очистить и пересоздать
make clean-generated
make codegen

# Или с force rebuild
cd app/modules/ide_presentation
dart run build_runner build --delete-conflicting-outputs
```

### Hot reload не работает

**Проблема:** Изменения не применяются

**Решение:**
1. Попробуйте **Hot Restart** (`R`)
2. Если не помогает - полный рестарт (`q` + `flutter run`)
3. Проверьте что нет синтаксических ошибок

### LSP features не работают

**Проблема:** Нет автодополнения, hover, diagnostics

**Решение:**
1. Проверьте что LSP Bridge запущен:
   ```bash
   # Должен вернуть PID процесса
   lsof -i :9999
   ```

2. Проверьте логи LSP Bridge:
   ```bash
   RUST_LOG=debug cargo run
   ```

3. Установите LSP серверы для нужных языков:
   ```bash
   # Dart (уже включен в Dart SDK)
   dart --version

   # TypeScript
   npm install -g typescript-language-server typescript

   # Python
   pip install python-lsp-server

   # Rust
   rustup component add rust-analyzer
   ```

---

## 🔍 Логи и Debugging

### Flutter App Logs

```bash
# Запустить с verbose логами
flutter run -v

# Только ошибки
flutter run --verbose
```

### LSP Bridge Logs

```bash
# Debug режим
RUST_LOG=debug cargo run

# Info режим
RUST_LOG=info cargo run

# Trace всё
RUST_LOG=trace cargo run
```

### MobX DevTools

```bash
# Добавить в pubspec.yaml
dev_dependencies:
  mobx_devtools: ^0.1.0

# Запустить Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 📚 Полезные ссылки

- **Flutter Docs**: https://flutter.dev/docs
- **MobX Docs**: https://mobx.netlify.app/
- **Rust Book**: https://doc.rust-lang.org/book/
- **LSP Specification**: https://microsoft.github.io/language-server-protocol/

---

## 🎓 Архитектура

Подробная архитектура в:
- `ARCHITECTURE_COMPLETE.md` - Полная архитектура
- `modules/ide_presentation/MOBX_GUIDE.md` - MobX guide
- `QUICK_START.md` - Quick reference

---

## ✨ Quick Commands

```bash
# Самый быстрый старт
make quickstart

# Dev окружение (2 терминала)
make run-lsp-bridge-dev    # Terminal 1
make run-dev               # Terminal 2

# Production build
make build-linux

# Полная очистка и пересборка
make reset
make setup
```

**Happy Coding!** 🎉
