import 'package:flutter/gestures.dart';

/// Stub implementation for non-web platforms.
/// Does nothing as native context menu is not an issue on desktop/mobile.
void preventNativeContextMenu(PointerDownEvent event) {
  // No-op for non-web platforms
}
