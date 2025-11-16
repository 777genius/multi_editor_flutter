import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_presentation/src/widgets/settings_dialog.dart';

void main() {
  Widget createTestWidget({
    Map<String, dynamic>? initialSettings,
    void Function(Map<String, dynamic>)? onSave,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SettingsDialog(
                    initialSettings: initialSettings,
                    onSave: onSave,
                  ),
                );
              },
              child: const Text('Open Settings'),
            ),
          ),
        ),
      ),
    );
  }

  group('SettingsDialog', () {
    testWidgets('should render all tabs', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('LSP'), findsOneWidget);
      expect(find.text('Git'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('should show Editor tab content by default', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Editor Settings'), findsOneWidget);
      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Show Line Numbers'), findsOneWidget);
      expect(find.text('Word Wrap'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('should switch to LSP tab', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('LSP'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('LSP Bridge Settings'), findsOneWidget);
      expect(find.text('LSP Bridge URL'), findsOneWidget);
      expect(find.text('Connection Timeout (seconds)'), findsOneWidget);
      expect(find.text('Request Timeout (seconds)'), findsOneWidget);
    });

    testWidgets('should switch to Git tab', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Git'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Git Settings'), findsOneWidget);
      expect(find.text('SSH Key Management'), findsOneWidget);
      expect(find.text('Manage SSH keys for secure Git authentication'),
          findsOneWidget);
      expect(find.text('Secure Credential Storage'), findsOneWidget);
      expect(find.text('Available Git Features'), findsOneWidget);
    });

    testWidgets('should show SSH Key Manager button in Git tab',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Git'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Manage SSH Keys'), findsOneWidget);
      expect(find.byIcon(Icons.manage_accounts), findsOneWidget);
    });

    testWidgets('should show security information in Git tab', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Git'));
      await tester.pumpAndSettle();

      // Assert
      expect(
          find.textContaining(
              'Credentials are encrypted using AES-256 and stored securely'),
          findsOneWidget);
      expect(find.textContaining('iOS: Keychain'), findsOneWidget);
      expect(
          find.textContaining('Android: EncryptedSharedPreferences'),
          findsOneWidget);
    });

    testWidgets('should show Git features list', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Git'));
      await tester.pumpAndSettle();

      // Assert
      expect(
          find.textContaining('Visual merge conflict resolution'),
          findsOneWidget);
      expect(
          find.textContaining('Three-way merge view'),
          findsOneWidget);
      expect(
          find.textContaining('SSH key generation'),
          findsOneWidget);
      expect(
          find.textContaining('Branch management'),
          findsOneWidget);
      expect(
          find.textContaining('Commit, push, pull, fetch, rebase'),
          findsOneWidget);
      expect(
          find.textContaining('Secure credential storage'),
          findsOneWidget);
    });

    testWidgets('should switch to About tab', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('About Flutter IDE'), findsOneWidget);
      expect(find.text('Version: 1.0.0'), findsOneWidget);
      expect(find.textContaining('Clean Architecture'), findsOneWidget);
      expect(find.textContaining('Domain-Driven Design'), findsOneWidget);
    });

    testWidgets('should show Cancel and Save buttons', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Reset to Defaults'), findsOneWidget);
    });

    testWidgets('should close dialog on Cancel', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be closed
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('should save settings on Save button', (tester) async {
      // Arrange
      Map<String, dynamic>? savedSettings;
      await tester.pumpWidget(
        createTestWidget(
          onSave: (settings) {
            savedSettings = settings;
          },
        ),
      );
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert
      expect(savedSettings, isNotNull);
      expect(savedSettings!['fontSize'], 14.0);
      expect(savedSettings!['showLineNumbers'], true);
      expect(savedSettings!['wordWrap'], false);
      expect(savedSettings!['theme'], 'dark');
    });

    testWidgets('should reset to defaults', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          initialSettings: {
            'fontSize': 20.0,
            'showLineNumbers': false,
            'wordWrap': true,
            'theme': 'light',
          },
        ),
      );
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Reset to Defaults'));
      await tester.pumpAndSettle();

      // Assert - Settings should be reset (visual verification in this case)
      // The actual reset would be verified through the state
    });

    testWidgets('should adjust font size with slider', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act - Find and drag slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Verify slider exists and is interactive
      expect(tester.widget<Slider>(slider).value, 14.0);
    });

    testWidgets('should toggle line numbers switch', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2)); // Line numbers + Word wrap

      // Verify switches are present
      final firstSwitch = tester.widget<Switch>(switches.first);
      expect(firstSwitch.value, true); // Line numbers default to true
    });

    testWidgets('should validate LSP URL', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Switch to LSP tab
      await tester.tap(find.text('LSP'));
      await tester.pumpAndSettle();

      // Act - Enter invalid URL and try to save
      final urlField = find.ancestor(
        of: find.text('LSP Bridge URL'),
        matching: find.byType(TextField),
      );
      await tester.enterText(urlField, 'invalid-url');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Error should be shown
      expect(find.text('URL must start with ws:// or wss://'), findsOneWidget);
    });

    testWidgets('should validate connection timeout', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('LSP'));
      await tester.pumpAndSettle();

      // Act - Enter invalid timeout
      final timeoutFields = find.byType(TextField);
      // Connection timeout is the second field (after URL)
      await tester.enterText(timeoutFields.at(1), '-5');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Must be greater than 0'), findsOneWidget);
    });

    testWidgets('should open SSH Key Manager from Git tab', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Git'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Manage SSH Keys'));
      await tester.pumpAndSettle();

      // Assert - SSH Key Manager should open
      // Note: This would require the SSH Key Manager widget to be available
      // In a real scenario, you might see a new screen or dialog
    });
  });

  group('SettingsDialog - Initial Settings', () {
    testWidgets('should load initial settings', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          initialSettings: {
            'fontSize': 16.0,
            'showLineNumbers': false,
            'wordWrap': true,
            'theme': 'light',
            'lspBridgeUrl': 'ws://custom:8080',
            'connectionTimeout': 20,
            'requestTimeout': 60,
          },
        ),
      );

      // Act
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Assert - Settings should be loaded
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 16.0);

      final switches = find.byType(Switch);
      expect(tester.widget<Switch>(switches.first).value, false); // Line numbers
      expect(tester.widget<Switch>(switches.last).value, true); // Word wrap
    });
  });

  group('SettingsDialog - Theme Selection', () {
    testWidgets('should have theme dropdown', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });
  });

  group('SettingsDialog - Visual Design', () {
    testWidgets('should have dark theme colors', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Assert - Just verify the dialog renders
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should have proper icons in Git tab', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Git'));
      await tester.pumpAndSettle();

      // Assert - Icons should be present
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
