# Linux Support

This document provides detailed information about running the Multi-File Code Editor on Linux.

## Overview

The editor now fully supports Linux desktop through [webview_cef](https://pub.dev/packages/webview_cef), which uses the Chromium Embedded Framework (CEF) to provide Monaco Editor integration.

## Architecture

### WebView Implementation

- **Package**: `webview_cef ^0.2.2`
- **Engine**: CEF (Chromium Embedded Framework)
- **Supported Architectures**:
  - x86_64 (x64)
  - ARM64 (aarch64)

### How It Works

```
┌─────────────────────────────────────┐
│   Flutter Application (Dart)        │
│                                      │
│  ┌──────────────────────────────┐   │
│  │  Monaco Editor Widget        │   │
│  │  (multi_editor_ui)           │   │
│  └────────────┬─────────────────┘   │
│               │                      │
│  ┌────────────▼─────────────────┐   │
│  │  CefWebViewController        │   │
│  │  (platform_webview.dart)     │   │
│  └────────────┬─────────────────┘   │
│               │                      │
│  ┌────────────▼─────────────────┐   │
│  │  webview_cef                 │   │
│  │  (WebviewManager)            │   │
│  └────────────┬─────────────────┘   │
└───────────────┼─────────────────────┘
                │
    ┌───────────▼──────────────┐
    │  CEF Native Library      │
    │  (Chromium Browser)      │
    └──────────────────────────┘
```

## System Requirements

### Minimal Requirements

- **OS**: Any modern Linux distribution (Ubuntu 20.04+, Fedora 35+, Arch, etc.)
- **Architecture**: x86_64 or ARM64
- **RAM**: 4GB minimum (8GB recommended)
- **Disk Space**: ~200MB for CEF binaries

### No Additional Dependencies Required

Unlike some WebView solutions that require system packages like `webkit2gtk-4.1`, **webview_cef bundles everything needed**, including:

- CEF binaries (Chromium browser engine)
- Required libraries
- GPU acceleration support

## Installation & Setup

### 1. Install Flutter

```bash
# If you haven't installed Flutter yet
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### 2. Enable Linux Desktop Support

```bash
flutter config --enable-linux-desktop
```

### 3. Clone & Setup Project

```bash
git clone https://github.com/777genius/multi_editor_flutter.git
cd multi_file_code_editor

# Get dependencies
dart pub get

# Bootstrap workspace (if using monorepo)
dart run melos bootstrap
```

### 4. First Build (CEF Download)

On the **first build**, webview_cef will automatically download the appropriate CEF binaries for your architecture:

```bash
cd example
flutter build linux --release
```

**What happens:**
1. Flutter detects it's the first CEF build
2. Downloads CEF binaries (~150MB) from cdn.spotify.com
3. Extracts to `~/.cache/webview_cef/`
4. Links binaries into your build
5. Compiles the application

**Expected time**: 5-10 minutes (depending on internet speed)

**Subsequent builds** will be much faster as CEF binaries are cached.

## Running the Application

### Development Mode

```bash
cd example
flutter run -d linux
```

### Production Build

```bash
cd example
flutter build linux --release

# Binary will be at:
# build/linux/x64/release/bundle/multi_file_editor_example
```

### Run Production Binary

```bash
./build/linux/x64/release/bundle/multi_file_editor_example
```

## Troubleshooting

### Issue: CEF Download Fails

**Symptoms**: Build fails with network errors during CEF download.

**Solutions**:
1. Check your internet connection
2. Try using a VPN if cdn.spotify.com is blocked
3. Manually download CEF from [cef-builds](https://cef-builds.spotifycdn.com/index.html)
4. Extract to `~/.cache/webview_cef/`

### Issue: Application Crashes on Startup

**Symptoms**: App starts but crashes immediately or shows blank window.

**Solutions**:
1. Ensure GPU drivers are up-to-date
2. Try software rendering:
   ```bash
   LIBGL_ALWAYS_SOFTWARE=1 ./your_app
   ```
3. Check logs:
   ```bash
   flutter run -d linux --verbose
   ```

### Issue: Monaco Editor Not Loading

**Symptoms**: File tree works but editor panel is blank.

**Solutions**:
1. Check JavaScript console (open DevTools in CEF)
2. Verify Monaco assets are bundled:
   ```bash
   ls build/linux/x64/release/bundle/data/flutter_assets/packages/flutter_monaco/assets/monaco/
   ```
3. Check file permissions

### Issue: High Memory Usage

**Symptoms**: Application uses more RAM than expected.

**Cause**: CEF is a full Chromium browser instance.

**Solutions**:
- Expected usage: 200-400MB for editor + 100-150MB per open file
- Close unused files
- Restart application periodically for long sessions

## Distribution

### Packaging for Distribution

#### AppImage (Recommended)

```bash
# Install appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Package your app
./appimagetool-x86_64.AppImage build/linux/x64/release/bundle/ MultiFileCodeEditor.AppImage
```

#### Snap

Create `snap/snapcraft.yaml`:

```yaml
name: multi-file-code-editor
version: '1.0.0'
summary: Professional code editor for Flutter
description: |
  Multi-file code editor with Monaco Editor integration.

base: core22
confinement: strict
grade: stable

apps:
  multi-file-code-editor:
    command: multi_file_editor_example
    plugs:
      - home
      - network
      - opengl

parts:
  flutter-app:
    plugin: dump
    source: build/linux/x64/release/bundle/
```

Build snap:
```bash
snapcraft
```

#### Flatpak

Create `com.example.MultiFileCodeEditor.yml` manifest and build with flatpak-builder.

## Performance Considerations

### Startup Time

- **First launch**: 3-5 seconds (CEF initialization)
- **Subsequent launches**: 1-2 seconds

### Memory Usage

| Component | RAM Usage |
|-----------|-----------|
| CEF Base | 150-200 MB |
| Monaco Editor | 50-100 MB |
| Per open file | 10-30 MB |
| Total (typical) | 300-500 MB |

### GPU Acceleration

CEF uses GPU acceleration by default. To disable:

```bash
export LIBGL_ALWAYS_SOFTWARE=1
./your_app
```

## Comparison with Other WebView Solutions

| Feature | webview_cef | webview_flutter | webkit2gtk |
|---------|-------------|-----------------|------------|
| Linux Support | ✅ Yes | ❌ No | ✅ Yes |
| Embedded Widget | ✅ Yes | ✅ Yes | ⚠️ Depends |
| CEF (Chromium) | ✅ Yes | ❌ No | ❌ No |
| System Dependencies | ❌ None | N/A | ✅ Required |
| Auto Download | ✅ Yes | N/A | ❌ No |
| Binary Size | ~150 MB | N/A | Varies |
| Performance | ⭐⭐⭐⭐⭐ | N/A | ⭐⭐⭐⭐ |

## Known Limitations

1. **Binary Size**: CEF adds ~150MB to application size
2. **API Stability**: webview_cef is marked as "APIs not stable yet"
3. **Wayland Support**: Works but may have minor issues (use X11 for best experience)
4. **HiDPI**: Scaling works but may need manual configuration on some systems

## Future Improvements

- [ ] Reduce CEF binary size with custom builds
- [ ] Better Wayland integration
- [ ] Hardware video decode acceleration
- [ ] Custom CEF command-line flags support

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/777genius/multi_editor_flutter/issues)
- **webview_cef Issues**: [webview_cef GitHub](https://github.com/hlwhl/webview_cef/issues)

---

**Last Updated**: 2025-01-08
**webview_cef Version**: 0.2.2
