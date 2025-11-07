# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- ✨ **Linux support** - Full desktop support for Linux via webview_cef
  - Automatic CEF binary download on first build
  - Support for x86_64 and ARM64 architectures
  - No system dependencies required
  - See [LINUX.md](LINUX.md) for details

- 📚 Comprehensive Linux documentation ([LINUX.md](LINUX.md))
  - Installation guide
  - Troubleshooting section
  - Distribution packaging examples (AppImage, Snap, Flatpak)
  - Performance considerations

### Changed

- 🔄 **Desktop WebView migration** - Unified all desktop platforms (Windows, macOS, Linux) on webview_cef
  - Replaced `webview_windows ^0.4.0` with `webview_cef ^0.2.2`
  - Removed `webview_flutter ^4.13.0` (desktop-only focus)
  - Simplified platform-specific code

- 📝 Updated README.md with platform support matrix
- 🎨 Added platform badges (Windows | macOS | Linux | Web)

### Temporarily Disabled

- 🔧 **Android support** - Easy to re-enable (uncomment `webview_flutter` in pubspec.yaml)
  - ⚠️ UI not optimized for mobile screens
  - Current layout is desktop/web-first (fixed sidebars, no responsive breakpoints)

- 🔧 **iOS support** - Easy to re-enable (uncomment `webview_flutter` in pubspec.yaml)
  - ⚠️ UI not optimized for mobile screens
  - Current layout is desktop/web-first (fixed sidebars, no responsive breakpoints)

> Mobile platforms can be re-enabled by uncommenting dependencies and platform declarations, but would require additional UI work for proper mobile experience.

### Technical Details

**Packages Updated:**
- `flutter_monaco_web` - Migrated to webview_cef for desktop
- Platform support: `macos`, `windows`, `linux`, `web`

**New Dependencies:**
- `webview_cef: ^0.2.2` - CEF-based WebView for all desktop platforms

**Removed Dependencies:**
- `webview_flutter` - No longer needed for desktop-only support
- `webview_windows` - Replaced by webview_cef

---

## [0.1.0] - Initial Release

### Added

- 🎉 Initial release of Multi-File Code Editor
- ✅ Monaco Editor integration (VS Code's editor)
- ✅ 100+ language syntax highlighting
- ✅ Hierarchical file tree with unlimited nesting
- ✅ Drag-and-drop file/folder management
- ✅ Plugin system with lifecycle management
- ✅ Multiple themes (Light, Dark, High Contrast)
- ✅ Type-safe Freezed sealed classes (Dart 3.x)
- ✅ Clean Architecture + DDD design

### Plugins

- 📦 Auto-save with debouncing
- 🎨 File icons (150+ types via Devicon)
- 📊 Real-time file statistics
- 🕐 Recent files tracking
- 🎯 Dart language support with snippets

### Platforms

- ✅ Windows (via webview_windows)
- ✅ macOS (via webview_flutter)
- ✅ Web (native browser)
- ✅ Android (via webview_flutter)
- ✅ iOS (via webview_flutter)

---

[Unreleased]: https://github.com/777genius/multi_editor_flutter/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/777genius/multi_editor_flutter/releases/tag/v0.1.0
