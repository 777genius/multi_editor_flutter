import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_auto_save/src/domain/value_objects/auto_save_config.dart';
import 'package:multi_editor_plugin_auto_save/src/domain/value_objects/save_interval.dart';

void main() {
  group('AutoSaveConfig - Creation', () {
    test('should create default configuration', () {
      // Arrange & Act
      final config = AutoSaveConfig.defaultConfig();

      // Assert
      expect(config.enabled, true);
      expect(config.interval.seconds, 5);
      expect(config.onlyWhenIdle, false);
      expect(config.showNotifications, true);
    });

    test('should create with custom values', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(10);

      // Act
      final config = AutoSaveConfig(
        enabled: false,
        interval: interval,
        onlyWhenIdle: true,
        showNotifications: false,
      );

      // Assert
      expect(config.enabled, false);
      expect(config.interval.seconds, 10);
      expect(config.onlyWhenIdle, true);
      expect(config.showNotifications, false);
    });

    test('should have default values for optional parameters', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(3);

      // Act
      final config = AutoSaveConfig(
        enabled: true,
        interval: interval,
      );

      // Assert
      expect(config.onlyWhenIdle, false);
      expect(config.showNotifications, true);
    });
  });

  group('AutoSaveConfig - JSON Serialization', () {
    test('should serialize to JSON', () {
      // Arrange
      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(7),
        onlyWhenIdle: true,
        showNotifications: false,
      );

      // Act
      final json = config.toJson();

      // Assert
      expect(json['enabled'], true);
      expect(json['interval'], isA<Map>());
      expect(json['interval']['seconds'], 7);
      expect(json['onlyWhenIdle'], true);
      expect(json['showNotifications'], false);
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {
        'enabled': false,
        'interval': {'seconds': 15},
        'onlyWhenIdle': true,
        'showNotifications': false,
      };

      // Act
      final config = AutoSaveConfig.fromJson(json);

      // Assert
      expect(config.enabled, false);
      expect(config.interval.seconds, 15);
      expect(config.onlyWhenIdle, true);
      expect(config.showNotifications, false);
    });

    test('should roundtrip through JSON', () {
      // Arrange
      final original = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(20),
        onlyWhenIdle: false,
        showNotifications: true,
      );

      // Act
      final json = original.toJson();
      final restored = AutoSaveConfig.fromJson(json);

      // Assert
      expect(restored.enabled, original.enabled);
      expect(restored.interval.seconds, original.interval.seconds);
      expect(restored.onlyWhenIdle, original.onlyWhenIdle);
      expect(restored.showNotifications, original.showNotifications);
    });
  });

  group('AutoSaveConfig - Modification Methods', () {
    test('should update interval using withInterval', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();
      final newInterval = SaveInterval.fromSeconds(15);

      // Act
      final updated = config.withInterval(newInterval);

      // Assert
      expect(updated.interval.seconds, 15);
      expect(updated.enabled, config.enabled);
      expect(updated.onlyWhenIdle, config.onlyWhenIdle);
      expect(updated.showNotifications, config.showNotifications);
    });

    test('should enable configuration', () {
      // Arrange
      final config = AutoSaveConfig(
        enabled: false,
        interval: SaveInterval.fromSeconds(5),
      );

      // Act
      final enabled = config.enable();

      // Assert
      expect(enabled.enabled, true);
      expect(enabled.interval, config.interval);
    });

    test('should disable configuration', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final disabled = config.disable();

      // Assert
      expect(disabled.enabled, false);
      expect(disabled.interval, config.interval);
    });

    test('should preserve other properties when enabling', () {
      // Arrange
      final config = AutoSaveConfig(
        enabled: false,
        interval: SaveInterval.fromSeconds(12),
        onlyWhenIdle: true,
        showNotifications: false,
      );

      // Act
      final enabled = config.enable();

      // Assert
      expect(enabled.enabled, true);
      expect(enabled.interval.seconds, 12);
      expect(enabled.onlyWhenIdle, true);
      expect(enabled.showNotifications, false);
    });

    test('should preserve other properties when disabling', () {
      // Arrange
      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(8),
        onlyWhenIdle: true,
        showNotifications: true,
      );

      // Act
      final disabled = config.disable();

      // Assert
      expect(disabled.enabled, false);
      expect(disabled.interval.seconds, 8);
      expect(disabled.onlyWhenIdle, true);
      expect(disabled.showNotifications, true);
    });
  });

  group('AutoSaveConfig - Immutability', () {
    test('should create new instance when modifying', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final enabled = config.enable();
      final disabled = config.disable();

      // Assert - Original should be unchanged
      expect(config.enabled, true);
      expect(enabled.enabled, true);
      expect(disabled.enabled, false);
    });

    test('should create new instance with copyWith', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final updated = config.copyWith(onlyWhenIdle: true);

      // Assert
      expect(config.onlyWhenIdle, false);
      expect(updated.onlyWhenIdle, true);
      expect(updated.enabled, config.enabled);
    });
  });

  group('AutoSaveConfig - Equality', () {
    test('should be equal for same values', () {
      // Arrange
      final config1 = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(5),
        onlyWhenIdle: false,
        showNotifications: true,
      );

      final config2 = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(5),
        onlyWhenIdle: false,
        showNotifications: true,
      );

      // Act & Assert
      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should not be equal for different enabled states', () {
      // Arrange
      final config1 = AutoSaveConfig.defaultConfig();
      final config2 = config1.disable();

      // Act & Assert
      expect(config1, isNot(equals(config2)));
    });

    test('should not be equal for different intervals', () {
      // Arrange
      final config1 = AutoSaveConfig.defaultConfig();
      final config2 = config1.withInterval(SaveInterval.fromSeconds(10));

      // Act & Assert
      expect(config1, isNot(equals(config2)));
    });

    test('should not be equal for different onlyWhenIdle', () {
      // Arrange
      final config1 = AutoSaveConfig.defaultConfig();
      final config2 = config1.copyWith(onlyWhenIdle: true);

      // Act & Assert
      expect(config1, isNot(equals(config2)));
    });

    test('should not be equal for different showNotifications', () {
      // Arrange
      final config1 = AutoSaveConfig.defaultConfig();
      final config2 = config1.copyWith(showNotifications: false);

      // Act & Assert
      expect(config1, isNot(equals(config2)));
    });
  });

  group('AutoSaveConfig - Use Cases', () {
    test('Use Case: Create and enable auto-save with 5 second interval', () {
      // Arrange & Act
      final config = AutoSaveConfig.defaultConfig();

      // Assert
      expect(config.enabled, true);
      expect(config.interval.seconds, 5);
    });

    test('Use Case: Disable auto-save while preserving settings', () {
      // Arrange
      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(10),
        showNotifications: false,
      );

      // Act
      final disabled = config.disable();

      // Assert
      expect(disabled.enabled, false);
      expect(disabled.interval.seconds, 10);
      expect(disabled.showNotifications, false);
    });

    test('Use Case: Change interval from 5s to 30s', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final updated = config.withInterval(SaveInterval.fromSeconds(30));

      // Assert
      expect(updated.interval.seconds, 30);
      expect(updated.enabled, true);
    });

    test('Use Case: Enable idle-only saving', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final idleOnly = config.copyWith(onlyWhenIdle: true);

      // Assert
      expect(idleOnly.onlyWhenIdle, true);
      expect(idleOnly.enabled, true);
    });

    test('Use Case: Silent auto-save (no notifications)', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final silent = config.copyWith(showNotifications: false);

      // Assert
      expect(silent.showNotifications, false);
      expect(silent.enabled, true);
    });

    test('Use Case: Complete configuration workflow', () {
      // Arrange - Start with defaults
      var config = AutoSaveConfig.defaultConfig();

      // Act - User disables temporarily
      config = config.disable();
      expect(config.enabled, false);

      // Act - User changes interval
      config = config.withInterval(SaveInterval.fromSeconds(15));
      expect(config.interval.seconds, 15);

      // Act - User enables idle-only mode
      config = config.copyWith(onlyWhenIdle: true);
      expect(config.onlyWhenIdle, true);

      // Act - User re-enables
      config = config.enable();

      // Assert - Final state
      expect(config.enabled, true);
      expect(config.interval.seconds, 15);
      expect(config.onlyWhenIdle, true);
    });
  });

  group('AutoSaveConfig - Edge Cases', () {
    test('should handle minimum interval', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(1);

      // Act
      final config = AutoSaveConfig(enabled: true, interval: interval);

      // Assert
      expect(config.interval.seconds, 1);
    });

    test('should handle maximum interval', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(60);

      // Act
      final config = AutoSaveConfig(enabled: true, interval: interval);

      // Assert
      expect(config.interval.seconds, 60);
    });

    test('should preserve interval when toggling enabled state', () {
      // Arrange
      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(25),
      );

      // Act
      final disabled = config.disable();
      final reEnabled = disabled.enable();

      // Assert
      expect(reEnabled.interval.seconds, 25);
    });

    test('should handle multiple sequential modifications', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final result = config
          .withInterval(SaveInterval.fromSeconds(20))
          .disable()
          .copyWith(onlyWhenIdle: true)
          .copyWith(showNotifications: false)
          .enable();

      // Assert
      expect(result.enabled, true);
      expect(result.interval.seconds, 20);
      expect(result.onlyWhenIdle, true);
      expect(result.showNotifications, false);
    });
  });

  group('AutoSaveConfig - toString', () {
    test('should have readable toString representation', () {
      // Arrange
      final config = AutoSaveConfig.defaultConfig();

      // Act
      final str = config.toString();

      // Assert
      expect(str, contains('AutoSaveConfig'));
      expect(str, contains('enabled'));
      expect(str, contains('interval'));
    });
  });
}
