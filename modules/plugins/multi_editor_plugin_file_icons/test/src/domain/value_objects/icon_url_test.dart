import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/icon_url.dart';

void main() {
  group('IconUrl', () {
    group('constructor', () {
      test('should create instance with value', () {
        // Arrange & Act
        const url = IconUrl(value: 'https://cdn.example.com/icon.svg');

        // Assert
        expect(url.value, 'https://cdn.example.com/icon.svg');
      });
    });

    group('parse factory', () {
      test('should parse valid HTTP URL', () {
        // Arrange & Act
        final url = IconUrl.parse('http://cdn.example.com/icon.svg');

        // Assert
        expect(url.value, 'http://cdn.example.com/icon.svg');
      });

      test('should parse valid HTTPS URL', () {
        // Arrange & Act
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Assert
        expect(url.value, 'https://cdn.example.com/icon.svg');
      });

      test('should throw on empty URL', () {
        // Arrange & Act & Assert
        expect(
          () => IconUrl.parse(''),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'URL cannot be empty',
          )),
        );
      });

      test('should throw on URL without protocol', () {
        // Arrange & Act & Assert
        expect(
          () => IconUrl.parse('cdn.example.com/icon.svg'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'URL must start with http:// or https://',
          )),
        );
      });

      test('should throw on FTP URL', () {
        // Arrange & Act & Assert
        expect(
          () => IconUrl.parse('ftp://cdn.example.com/icon.svg'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'URL must start with http:// or https://',
          )),
        );
      });

      test('should parse jsdelivr CDN URL', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdn.jsdelivr.net/npm/vscode-icons/icons/file_type_dart.svg',
        );

        // Assert
        expect(url.value, contains('jsdelivr.net'));
      });

      test('should parse unpkg CDN URL', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://unpkg.com/vscode-icons@latest/icons/file_type_dart.svg',
        );

        // Assert
        expect(url.value, contains('unpkg.com'));
      });

      test('should parse Cloudflare CDN URL', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdnjs.cloudflare.com/ajax/libs/vscode-icons/1.0.0/icon.svg',
        );

        // Assert
        expect(url.value, contains('cdnjs.cloudflare.com'));
      });

      test('should parse Iconify URL', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://api.iconify.design/vscode-icons:file-type-dart.svg',
        );

        // Assert
        expect(url.value, contains('iconify.design'));
      });

      test('should parse GitHub raw URL', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://raw.githubusercontent.com/user/repo/main/icon.svg',
        );

        // Assert
        expect(url.value, contains('raw.githubusercontent.com'));
      });

      test('should parse URL with cdn subdomain', () {
        // Arrange & Act
        final url = IconUrl.parse('https://cdn.mysite.com/icons/dart.svg');

        // Assert
        expect(url.value, contains('cdn.'));
      });

      test('should parse valid custom URL', () {
        // Arrange & Act
        final url = IconUrl.parse('https://example.com/path/to/icon.svg');

        // Assert
        expect(url.value, 'https://example.com/path/to/icon.svg');
      });

      test('should handle URL with query parameters', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdn.example.com/icon.svg?size=64&color=blue',
        );

        // Assert
        expect(url.value, contains('?size=64&color=blue'));
      });

      test('should handle URL with fragment', () {
        // Arrange & Act
        final url = IconUrl.parse('https://cdn.example.com/icon.svg#fragment');

        // Assert
        expect(url.value, contains('#fragment'));
      });

      test('should handle URL with port', () {
        // Arrange & Act
        final url = IconUrl.parse('https://cdn.example.com:8080/icon.svg');

        // Assert
        expect(url.value, contains(':8080'));
      });
    });

    group('fromIconify factory', () {
      test('should create Iconify URL with icon set and name', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-dart',
        );

        // Assert
        expect(url.value, 'https://api.iconify.design/vscode-icons:file-type-dart.svg');
      });

      test('should create Iconify URL for different icon sets', () {
        // Arrange
        final iconSets = [
          {'set': 'mdi', 'name': 'home'},
          {'set': 'fa', 'name': 'user'},
          {'set': 'material-icons', 'name': 'settings'},
        ];

        // Act & Assert
        for (final iconData in iconSets) {
          final url = IconUrl.fromIconify(
            iconSet: iconData['set']!,
            iconName: iconData['name']!,
          );
          expect(url.value, contains(iconData['set']!));
          expect(url.value, contains(iconData['name']!));
        }
      });

      test('should use colon separator between set and name', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-dart',
        );

        // Assert
        expect(url.value, contains('vscode-icons:file-type-dart'));
      });

      test('should append .svg extension', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-dart',
        );

        // Assert
        expect(url.value, endsWith('.svg'));
      });

      test('should handle icon names with hyphens', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-typescript-official',
        );

        // Assert
        expect(url.value, contains('file-type-typescript-official'));
      });

      test('should handle icon names with underscores', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'custom',
          iconName: 'icon_name_test',
        );

        // Assert
        expect(url.value, contains('icon_name_test'));
      });
    });

    group('fromJsDelivr factory', () {
      test('should create jsDelivr URL with package, version, and path', () {
        // Arrange & Act
        final url = IconUrl.fromJsDelivr(
          package: 'vscode-icons',
          version: '1.0.0',
          path: 'icons/file_type_dart.svg',
        );

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/npm/vscode-icons@1.0.0/icons/file_type_dart.svg',
        );
      });

      test('should handle different package names', () {
        // Arrange & Act
        final url = IconUrl.fromJsDelivr(
          package: '@vscode/icons',
          version: '2.0.0',
          path: 'dist/icon.svg',
        );

        // Assert
        expect(url.value, contains('@vscode/icons'));
      });

      test('should handle different versions', () {
        // Arrange
        final versions = ['1.0.0', '2.1.3', 'latest', 'next'];

        // Act & Assert
        for (final version in versions) {
          final url = IconUrl.fromJsDelivr(
            package: 'test-package',
            version: version,
            path: 'icon.svg',
          );
          expect(url.value, contains('@$version'));
        }
      });

      test('should handle nested paths', () {
        // Arrange & Act
        final url = IconUrl.fromJsDelivr(
          package: 'icons',
          version: '1.0.0',
          path: 'dist/assets/svg/icon.svg',
        );

        // Assert
        expect(url.value, contains('dist/assets/svg/icon.svg'));
      });

      test('should construct valid jsDelivr URL format', () {
        // Arrange & Act
        final url = IconUrl.fromJsDelivr(
          package: 'my-icons',
          version: '3.2.1',
          path: 'icons/dart.svg',
        );

        // Assert
        expect(url.value, startsWith('https://cdn.jsdelivr.net/npm/'));
        expect(url.value, contains('my-icons@3.2.1'));
        expect(url.value, endsWith('icons/dart.svg'));
      });
    });

    group('toString', () {
      test('should return value', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final string = url.toString();

        // Assert
        expect(string, 'https://cdn.example.com/icon.svg');
      });

      test('should return value for Iconify URL', () {
        // Arrange
        final url = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-dart',
        );

        // Act
        final string = url.toString();

        // Assert
        expect(string, 'https://api.iconify.design/vscode-icons:file-type-dart.svg');
      });

      test('should return value for jsDelivr URL', () {
        // Arrange
        final url = IconUrl.fromJsDelivr(
          package: 'icons',
          version: '1.0.0',
          path: 'icon.svg',
        );

        // Act
        final string = url.toString();

        // Assert
        expect(string, 'https://cdn.jsdelivr.net/npm/icons@1.0.0/icon.svg');
      });
    });

    group('equality', () {
      test('should be equal when values are the same', () {
        // Arrange
        final url1 = IconUrl.parse('https://cdn.example.com/icon.svg');
        final url2 = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act & Assert
        expect(url1, equals(url2));
        expect(url1.hashCode, equals(url2.hashCode));
      });

      test('should not be equal when values differ', () {
        // Arrange
        final url1 = IconUrl.parse('https://cdn.example.com/icon1.svg');
        final url2 = IconUrl.parse('https://cdn.example.com/icon2.svg');

        // Act & Assert
        expect(url1, isNot(equals(url2)));
      });

      test('should be equal for same Iconify URLs', () {
        // Arrange
        final url1 = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-dart',
        );
        final url2 = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-dart',
        );

        // Act & Assert
        expect(url1, equals(url2));
      });

      test('should be equal for same jsDelivr URLs', () {
        // Arrange
        final url1 = IconUrl.fromJsDelivr(
          package: 'icons',
          version: '1.0.0',
          path: 'icon.svg',
        );
        final url2 = IconUrl.fromJsDelivr(
          package: 'icons',
          version: '1.0.0',
          path: 'icon.svg',
        );

        // Act & Assert
        expect(url1, equals(url2));
      });
    });

    group('copyWith', () {
      test('should copy with new value', () {
        // Arrange
        final original = IconUrl.parse('https://cdn.example.com/icon1.svg');

        // Act
        final copied = original.copyWith(
          value: 'https://cdn.example.com/icon2.svg',
        );

        // Assert
        expect(copied.value, 'https://cdn.example.com/icon2.svg');
        expect(original.value, 'https://cdn.example.com/icon1.svg');
      });
    });

    group('edge cases', () {
      test('should handle very long URLs', () {
        // Arrange
        final longPath = 'path/' * 50 + 'icon.svg';
        final longUrl = 'https://cdn.example.com/$longPath';

        // Act
        final url = IconUrl.parse(longUrl);

        // Assert
        expect(url.value, longUrl);
        expect(url.value.length, greaterThan(200));
      });

      test('should handle URLs with special characters', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdn.example.com/icons/file%20type%20dart.svg',
        );

        // Assert
        expect(url.value, contains('%20'));
      });

      test('should handle URLs with unicode', () {
        // Arrange & Act
        final url = IconUrl.parse('https://cdn.example.com/图标/icon.svg');

        // Assert
        expect(url.value, contains('图标'));
      });

      test('should handle localhost URLs', () {
        // Arrange & Act
        final url = IconUrl.parse('http://localhost:3000/icon.svg');

        // Assert
        expect(url.value, 'http://localhost:3000/icon.svg');
      });

      test('should handle IP address URLs', () {
        // Arrange & Act
        final url = IconUrl.parse('http://192.168.1.1/icon.svg');

        // Assert
        expect(url.value, 'http://192.168.1.1/icon.svg');
      });

      test('should handle URL with multiple query parameters', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdn.example.com/icon.svg?size=64&color=blue&format=svg',
        );

        // Assert
        expect(url.value, contains('size=64'));
        expect(url.value, contains('color=blue'));
        expect(url.value, contains('format=svg'));
      });

      test('should handle different image formats', () {
        // Arrange
        final formats = ['svg', 'png', 'jpg', 'webp', 'gif'];

        // Act & Assert
        for (final format in formats) {
          final url = IconUrl.parse('https://cdn.example.com/icon.$format');
          expect(url.value, endsWith('.$format'));
        }
      });
    });

    group('validation errors', () {
      test('should provide clear error for empty URL', () {
        // Arrange & Act & Assert
        expect(
          () => IconUrl.parse(''),
          throwsA(predicate((e) =>
              e is ArgumentError && e.message == 'URL cannot be empty')),
        );
      });

      test('should provide clear error for missing protocol', () {
        // Arrange & Act & Assert
        expect(
          () => IconUrl.parse('cdn.example.com/icon.svg'),
          throwsA(predicate((e) =>
              e is ArgumentError &&
              e.message == 'URL must start with http:// or https://')),
        );
      });

      test('should provide clear error for invalid URL format', () {
        // Arrange & Act & Assert
        expect(
          () => IconUrl.parse('https://'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('practical examples', () {
      test('should create URL for Dart file icon from Iconify', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'vscode-icons',
          iconName: 'file-type-dart',
        );

        // Assert
        expect(url.value, 'https://api.iconify.design/vscode-icons:file-type-dart.svg');
        expect(url.toString(), contains('vscode-icons'));
        expect(url.toString(), contains('file-type-dart'));
      });

      test('should create URL for icon from jsDelivr CDN', () {
        // Arrange & Act
        final url = IconUrl.fromJsDelivr(
          package: 'vscode-icons',
          version: '12.0.0',
          path: 'icons/file_type_dart.svg',
        );

        // Assert
        expect(url.value, startsWith('https://cdn.jsdelivr.net/npm/'));
        expect(url.toString(), contains('vscode-icons@12.0.0'));
        expect(url.toString(), endsWith('file_type_dart.svg'));
      });

      test('should create URL for Material Icons', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'mdi',
          iconName: 'file-document',
        );

        // Assert
        expect(url.value, 'https://api.iconify.design/mdi:file-document.svg');
      });

      test('should create URL for Font Awesome icon', () {
        // Arrange & Act
        final url = IconUrl.fromIconify(
          iconSet: 'fa',
          iconName: 'file-code',
        );

        // Assert
        expect(url.value, 'https://api.iconify.design/fa:file-code.svg');
      });

      test('should create URL from custom CDN', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdn.mycompany.com/assets/icons/dart.svg',
        );

        // Assert
        expect(url.value, 'https://cdn.mycompany.com/assets/icons/dart.svg');
      });

      test('should create URL from GitHub raw content', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://raw.githubusercontent.com/vscode-icons/vscode-icons/master/icons/file_type_dart.svg',
        );

        // Assert
        expect(url.value, contains('raw.githubusercontent.com'));
        expect(url.value, contains('vscode-icons'));
      });
    });

    group('CDN support', () {
      test('should accept jsdelivr URLs', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdn.jsdelivr.net/npm/package@1.0.0/icon.svg',
        );

        // Assert
        expect(url.value, contains('jsdelivr.net'));
      });

      test('should accept unpkg URLs', () {
        // Arrange & Act
        final url = IconUrl.parse('https://unpkg.com/package@1.0.0/icon.svg');

        // Assert
        expect(url.value, contains('unpkg.com'));
      });

      test('should accept Cloudflare CDN URLs', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://cdnjs.cloudflare.com/ajax/libs/package/1.0.0/icon.svg',
        );

        // Assert
        expect(url.value, contains('cdnjs.cloudflare.com'));
      });

      test('should accept Iconify API URLs', () {
        // Arrange & Act
        final url = IconUrl.parse(
          'https://api.iconify.design/vscode-icons:file-type-dart.svg',
        );

        // Assert
        expect(url.value, contains('iconify.design'));
      });

      test('should accept generic CDN URLs', () {
        // Arrange & Act
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Assert
        expect(url.value, contains('cdn.'));
      });
    });
  });
}
