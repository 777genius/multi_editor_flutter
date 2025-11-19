import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/utils/context_menu_web.dart';

void main() {
  group('preventNativeContextMenu (web)', () {
    test('should not throw when called outside web context', () {
      // Arrange
      final event = PointerDownEvent(
        position: const Offset(100, 100),
      );

      // Act & Assert
      // When running in non-web environment, the function should catch
      // the error and not throw
      expect(() => preventNativeContextMenu(event), returnsNormally);
    });

    test('should handle multiple calls gracefully', () {
      // Arrange
      final event1 = PointerDownEvent(position: const Offset(0, 0));
      final event2 = PointerDownEvent(position: const Offset(10, 10));
      final event3 = PointerDownEvent(position: const Offset(20, 20));

      // Act & Assert
      // First call should attempt to attach listener, subsequent calls
      // should return early if listener already attached (in web context)
      // or catch error (in non-web context)
      expect(() {
        preventNativeContextMenu(event1);
        preventNativeContextMenu(event2);
        preventNativeContextMenu(event3);
      }, returnsNormally);
    });

    test('should handle secondary button events', () {
      // Arrange
      final event = PointerDownEvent(
        position: const Offset(50, 75),
        buttons: kSecondaryButton,
      );

      // Act & Assert
      expect(() => preventNativeContextMenu(event), returnsNormally);
    });

    test('should handle primary button events', () {
      // Arrange
      final event = PointerDownEvent(
        position: const Offset(200, 300),
        buttons: kPrimaryButton,
      );

      // Act & Assert
      expect(() => preventNativeContextMenu(event), returnsNormally);
    });

    test('should handle events with different pointer kinds', () {
      // Arrange
      final mouseEvent = PointerDownEvent(
        position: const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
      );
      final touchEvent = PointerDownEvent(
        position: const Offset(100, 100),
        kind: PointerDeviceKind.touch,
      );

      // Act & Assert
      expect(() => preventNativeContextMenu(mouseEvent), returnsNormally);
      expect(() => preventNativeContextMenu(touchEvent), returnsNormally);
    });

    test('should handle rapid successive calls without errors', () {
      // Arrange
      final events = List.generate(
        50,
        (index) => PointerDownEvent(
          position: Offset(index.toDouble(), index.toDouble()),
        ),
      );

      // Act & Assert
      // The function should handle rapid calls, with first call attempting
      // to attach listener and subsequent calls either returning early
      // (if in web context) or catching errors (if not in web context)
      expect(() {
        for (final event in events) {
          preventNativeContextMenu(event);
        }
      }, returnsNormally);
    });

    test('should be idempotent when called multiple times', () {
      // Arrange
      final event = PointerDownEvent(position: const Offset(100, 100));

      // Act & Assert
      // Multiple calls with same event should not cause issues
      expect(() {
        preventNativeContextMenu(event);
        preventNativeContextMenu(event);
        preventNativeContextMenu(event);
      }, returnsNormally);
    });

    test('should handle events at boundary positions', () {
      // Arrange
      final zero = PointerDownEvent(position: const Offset(0, 0));
      final negative = PointerDownEvent(position: const Offset(-100, -100));
      final large = PointerDownEvent(position: const Offset(10000, 10000));

      // Act & Assert
      expect(() => preventNativeContextMenu(zero), returnsNormally);
      expect(() => preventNativeContextMenu(negative), returnsNormally);
      expect(() => preventNativeContextMenu(large), returnsNormally);
    });

    test('should handle events with various button combinations', () {
      // Arrange
      final primaryAndSecondary = PointerDownEvent(
        position: const Offset(100, 100),
        buttons: kPrimaryButton | kSecondaryButton,
      );
      final middleButton = PointerDownEvent(
        position: const Offset(100, 100),
        buttons: kMiddleMouseButton,
      );

      // Act & Assert
      expect(() => preventNativeContextMenu(primaryAndSecondary), returnsNormally);
      expect(() => preventNativeContextMenu(middleButton), returnsNormally);
    });

    test('should not return a value', () {
      // Arrange
      final event = PointerDownEvent(position: const Offset(100, 100));

      // Act
      final result = preventNativeContextMenu(event);

      // Assert - function returns void
      expect(result, isNull);
    });

    test('should handle concurrent calls from different contexts', () {
      // Arrange
      final events = [
        PointerDownEvent(
          position: const Offset(10, 10),
          buttons: kPrimaryButton,
        ),
        PointerDownEvent(
          position: const Offset(20, 20),
          buttons: kSecondaryButton,
        ),
        PointerDownEvent(
          position: const Offset(30, 30),
          buttons: kMiddleMouseButton,
        ),
      ];

      // Act & Assert
      // Function should handle being called with different event types
      expect(() {
        for (final event in events) {
          preventNativeContextMenu(event);
        }
      }, returnsNormally);
    });

    test('should handle events with all pointer device kinds', () {
      // Arrange
      final deviceKinds = [
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      ];

      // Act & Assert
      for (final kind in deviceKinds) {
        final event = PointerDownEvent(
          position: const Offset(100, 100),
          kind: kind,
        );
        expect(() => preventNativeContextMenu(event), returnsNormally);
      }
    });

    group('error handling', () {
      test('should gracefully handle errors when not in web environment', () {
        // Arrange
        final event = PointerDownEvent(position: const Offset(100, 100));

        // Act & Assert
        // The try-catch block should prevent any errors from propagating
        // when the web APIs are not available (non-web environment)
        expect(() => preventNativeContextMenu(event), returnsNormally);
      });

      test('should not throw on repeated calls after error', () {
        // Arrange
        final events = List.generate(
          10,
          (i) => PointerDownEvent(position: Offset(i * 10.0, i * 10.0)),
        );

        // Act & Assert
        // Even if first call fails (non-web environment), subsequent
        // calls should also be handled gracefully
        expect(() {
          for (final event in events) {
            preventNativeContextMenu(event);
          }
        }, returnsNormally);
      });
    });

    group('behavior verification', () {
      test('should accept valid PointerDownEvent instances', () {
        // Arrange
        final validEvents = [
          PointerDownEvent(position: const Offset(0, 0)),
          PointerDownEvent(
            position: const Offset(100, 200),
            buttons: kSecondaryButton,
          ),
          PointerDownEvent(
            position: const Offset(50, 50),
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryButton,
          ),
        ];

        // Act & Assert
        for (final event in validEvents) {
          expect(() => preventNativeContextMenu(event), returnsNormally);
        }
      });

      test('should handle events with complete metadata', () {
        // Arrange
        final event = PointerDownEvent(
          timeStamp: const Duration(milliseconds: 1000),
          pointer: 1,
          kind: PointerDeviceKind.mouse,
          device: 0,
          position: const Offset(150, 250),
          localPosition: const Offset(150, 250),
          buttons: kSecondaryButton,
          down: true,
        );

        // Act & Assert
        expect(() => preventNativeContextMenu(event), returnsNormally);
      });
    });
  });
}
