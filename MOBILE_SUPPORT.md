# Mobile Support Guide

This document explains how to re-enable Android and iOS support, and what limitations exist.

## Current Status

🔧 **Mobile platforms are temporarily disabled** to focus on desktop/web experience.

- ✅ Technical capability: Full Monaco Editor support via `webview_flutter`
- ⚠️ UI/UX limitation: Layout not optimized for mobile screens

## Why Mobile Support is Disabled

The editor was initially designed with mobile support, but the current focus shifted to desktop/web platforms because:

1. **Desktop-first UI** - Fixed sidebars, multi-panel layout
2. **Unified WebView** - Using `webview_cef` for all desktop platforms
3. **Development focus** - Optimizing desktop experience first

## How to Re-enable Mobile Support

### Step 1: Update `flutter_monaco_web/pubspec.yaml`

Uncomment the mobile dependencies:

```yaml
# modules/flutter_monaco_web/pubspec.yaml

platforms:
  android:    # ← Uncomment
  ios:        # ← Uncomment
  macos:
  windows:
  linux:
  web:

dependencies:
  flutter:
    sdk: flutter

  # WebView packages for different platforms
  webview_flutter: ^4.13.0  # ← Uncomment (for Android, iOS, macOS)
  webview_cef: ^0.2.2        # Desktop (Windows, macOS, Linux)
```

### Step 2: Update Platform Controller

Modify `modules/flutter_monaco_web/lib/src/platform/platform_webview.dart`:

Add back the import:
```dart
import 'package:webview_flutter/webview_flutter.dart' as wf;
```

Add back `FlutterWebViewController` class (see git history for reference).

Update `PlatformWebViewFactory`:
```dart
class PlatformWebViewFactory {
  static PlatformWebViewController createController() {
    if (kIsWeb) {
      return WebWebViewController();
    } else if (PlatformDetector.isWindows ||
               PlatformDetector.isLinux) {
      return CefWebViewController();
    } else if (PlatformDetector.isMacOS) {
      // Choose: CEF for consistency or webview_flutter for native feel
      return CefWebViewController(); // or FlutterWebViewController()
    } else {
      // Android, iOS
      return FlutterWebViewController();
    }
  }
}
```

### Step 3: Update `monaco_controller.dart`

Add back `_initializeFlutterWebView()` method and update the initialization logic:

```dart
// Initialize WebView based on platform
if (kIsWeb) {
  await _initializeWebWebView(/* ... */);
} else if (PlatformDetector.isWindows ||
           PlatformDetector.isLinux) {
  await _initializeCefWebView(/* ... */);
} else {
  // Android, iOS, (optionally macOS)
  await _initializeFlutterWebView(/* ... */);
}
```

### Step 4: Update `webViewWidget` getter

```dart
Widget get webViewWidget {
  if (kIsWeb) {
    return (_webViewController as WebWebViewController).build();
  } else if (_webViewController is CefWebViewController) {
    final cefController = (_webViewController as CefWebViewController).cefController;
    return cefController!.webviewWidget;
  } else {
    // Mobile platforms
    return wf.WebViewWidget(
      controller: (_webViewController as FlutterWebViewController).flutterController,
    );
  }
}
```

### Step 5: Run on Mobile

```bash
flutter pub get
flutter run -d android  # or -d ios
```

## Known Limitations on Mobile

### 1. Layout Issues

The current UI uses fixed layouts designed for desktop screens:

**Problems:**
- File tree sidebar is always visible (takes up screen space)
- Code editor and file tree compete for space
- No responsive breakpoints
- Action buttons assume mouse hover

**What needs work:**
```dart
// Current (Desktop):
Row(
  children: [
    SizedBox(width: 250, child: FileTreeView()),  // Fixed width
    Expanded(child: EditorView()),
  ],
)

// Needed for Mobile:
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      // Mobile: Stack with drawer
      return Stack(
        children: [
          EditorView(),
          if (_drawerOpen) FileTreeDrawer(),
        ],
      );
    } else {
      // Desktop: Side by side
      return Row(/* ... */);
    }
  },
)
```

### 2. Touch Interactions

Current interactions are keyboard/mouse-first:

**Issues:**
- Context menus assume right-click
- Drag-and-drop uses mouse events
- No long-press gestures
- Small touch targets

**What needs work:**
- Add `GestureDetector` for long-press context menus
- Increase touch target sizes (min 48x48 dp)
- Add swipe gestures for navigation
- Touch-friendly drag handles

### 3. Performance Considerations

Monaco Editor in WebView on mobile:

**Pros:**
- Full Monaco Editor features
- Consistent experience across platforms

**Cons:**
- Higher memory usage (~200MB+ per editor)
- Battery drain from WebView
- Slower than native text input

### 4. Monaco Editor Limitations on Mobile

Monaco Editor itself has mobile challenges:

- Virtual keyboard overlays editor
- Text selection is difficult
- No autocomplete popup positioning
- Scrolling conflicts with page scroll

## Recommended Mobile UI Changes

If you want proper mobile support, consider these changes:

### 1. Responsive Layout System

```dart
class EditorScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Code Editor'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: FileTreeView(),
      ),
      body: EditorView(),
      bottomNavigationBar: _buildMobileToolbar(),
    );
  }
}
```

### 2. Simplified Mobile Editor

Consider using a simpler text editor for mobile instead of Monaco:

```dart
// Alternative for mobile
class MobileCodeEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: null,
      style: TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }
}
```

### 3. Touch-Optimized File Tree

```dart
ListTile(
  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  leading: Icon(fileIcon, size: 32),  // Larger icons
  title: Text(fileName, style: TextStyle(fontSize: 16)),
  onTap: () => openFile(),
  onLongPress: () => showMobileContextMenu(),  // Long-press menu
)
```

## Testing on Mobile

After re-enabling mobile support:

```bash
# Test on Android emulator
flutter run -d emulator-5554

# Test on iOS simulator
flutter run -d iPhone

# Test on physical device
flutter run -d <device-id>

# Debug layout issues
flutter run --dart-define=DEBUG_LAYOUT=true
```

## Alternative: Mobile-First Fork

If you need a mobile-optimized version, consider:

1. Fork the repository
2. Create a `mobile` branch
3. Redesign UI components for mobile
4. Use conditional imports for platform-specific code
5. Maintain separate mobile and desktop codebases

## Migration Path

**Phase 1: Re-enable (Quick)**
- Uncomment dependencies
- Add back FlutterWebViewController
- Test basic functionality
- **Effort**: 2-4 hours
- **Result**: Works but poor UX

**Phase 2: Basic Responsive (Medium)**
- Add responsive breakpoints
- Collapsible sidebar
- Touch-friendly buttons
- **Effort**: 1-2 weeks
- **Result**: Usable on mobile

**Phase 3: Mobile-Optimized (Full)**
- Complete UI redesign for mobile
- Custom mobile editor
- Touch gestures
- Native feel
- **Effort**: 1-2 months
- **Result**: Production mobile app

## Get Help

- **Issues**: [GitHub Issues](https://github.com/777genius/multi_editor_flutter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/777genius/multi_editor_flutter/discussions)

---

**Last Updated**: 2025-01-08

**Note**: The team currently prioritizes desktop/web experience. Mobile support contributions are welcome!
