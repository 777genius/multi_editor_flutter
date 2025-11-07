import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/gestures.dart';

bool _listenerAttached = false;

/// Web-specific implementation for preventing native context menu.
/// This function attaches a single global listener to prevent the browser's
/// context menu from appearing on the file tree area.
void preventNativeContextMenu(PointerDownEvent event) {
  if (_listenerAttached) return;

  try {
    // Attach a global listener to prevent context menu
    web.window.addEventListener(
      'contextmenu',
      ((web.Event e) {
        e.preventDefault();
      }.toJS) as web.EventListener,
    );

    _listenerAttached = true;
  } catch (e) {
    // Ignore errors if not in web context
  }
}
