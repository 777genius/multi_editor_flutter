import 'package:test/test.dart';
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

import '../mocks/mock_repositories.dart';
import '../mocks/mock_services.dart';

void main() {
  group('GetRuntimeStatusQueryHandler Integration Tests', () {
    late GetRuntimeStatusQueryHandler handler;
    late MockRuntimeRepository runtimeRepository;
    late MockManifestRepository manifestRepository;

    setUp(() {
      runtimeRepository = MockRuntimeRepository();
      manifestRepository = MockManifestRepository();

      handler = GetRuntimeStatusQueryHandler(
        runtimeRepository,
        manifestRepository,
      );
    });

    test('should return notInstalled when no runtime is installed', () async {
      // Arrange
      final query = GetRuntimeStatusQuery();

      // Act
      final result = await handler.handle(query);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (status) {
          status.map(
            notInstalled: (_) => expect(true, isTrue), // Expected
            installed: (_) => fail('Should be not installed'),
            partiallyInstalled: (_) => fail('Should be not installed'),
            installing: (_) => fail('Should be not installed'),
            failed: (_) => fail('Should be not installed'),
            updateAvailable: (_) => fail('Should be not installed'),
          );
        },
      );
    });

    test('should return installed when runtime is fully installed', () async {
      // Arrange
      final version = RuntimeVersion.fromString('20.11.0');
      runtimeRepository.mockInstalledVersion(version);
      runtimeRepository.mockModuleInstalled(ModuleId.nodejs);
      runtimeRepository.mockModuleInstalled(ModuleId.openVSCodeServer);

      final query = GetRuntimeStatusQuery();

      // Act
      final result = await handler.handle(query);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (status) {
          status.map(
            installed: (s) {
              expect(s.version, version);
              expect(s.installedModules, hasLength(2));
              expect(s.installedAt, isNotNull);
            },
            notInstalled: (_) => fail('Should be installed'),
            partiallyInstalled: (_) => fail('Should be fully installed'),
            installing: (_) => fail('Should be installed'),
            failed: (_) => fail('Should be installed'),
            updateAvailable: (_) => fail('Should be installed'),
          );
        },
      );
    });

    test('should return updateAvailable when newer version exists', () async {
      // Arrange
      final currentVersion = RuntimeVersion.fromString('20.10.0');
      final latestVersion = RuntimeVersion.fromString('20.11.0');

      runtimeRepository.mockInstalledVersion(currentVersion);
      runtimeRepository.mockModuleInstalled(ModuleId.nodejs);

      manifestRepository.mockLatestVersion(latestVersion);

      final query = GetRuntimeStatusQuery();

      // Act
      final result = await handler.handle(query);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (status) {
          status.map(
            updateAvailable: (s) {
              expect(s.currentVersion, currentVersion);
              expect(s.availableVersion, latestVersion);
            },
            installed: (_) => fail('Should have update available'),
            notInstalled: (_) => fail('Should have update available'),
            partiallyInstalled: (_) => fail('Should have update available'),
            installing: (_) => fail('Should have update available'),
            failed: (_) => fail('Should have update available'),
          );
        },
      );
    });

    test('should return installing when installation is in progress', () async {
      // Arrange
      final installation = RuntimeInstallation.create(
        modules: [
          RuntimeModule.create(
            id: ModuleId.nodejs,
            name: 'Node.js',
            type: ModuleType.runtime,
            version: RuntimeVersion.fromString('20.11.0'),
            platformArtifacts: {
              PlatformIdentifier.linuxX64: PlatformArtifact(
                url: DownloadUrl('https://example.com/node.tar.xz'),
                hash: SHA256Hash.fromString('a' * 64),
                size: ByteSize.fromMB(30),
              ),
            },
          ),
        ],
        platform: PlatformIdentifier.linuxX64,
      ).start();

      await runtimeRepository.saveInstallation(installation);

      final query = GetRuntimeStatusQuery();

      // Act
      final result = await handler.handle(query);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (status) {
          status.map(
            installing: (s) {
              expect(s.installationId, installation.id);
              expect(s.progress, installation.progress);
            },
            installed: (_) => fail('Should be installing'),
            notInstalled: (_) => fail('Should be installing'),
            partiallyInstalled: (_) => fail('Should be installing'),
            failed: (_) => fail('Should be installing'),
            updateAvailable: (_) => fail('Should be installing'),
          );
        },
      );
    });

    test('should return failed when last installation failed', () async {
      // Arrange
      final installation = RuntimeInstallation.create(
        modules: [
          RuntimeModule.create(
            id: ModuleId.nodejs,
            name: 'Node.js',
            type: ModuleType.runtime,
            version: RuntimeVersion.fromString('20.11.0'),
            platformArtifacts: {
              PlatformIdentifier.linuxX64: PlatformArtifact(
                url: DownloadUrl('https://example.com/node.tar.xz'),
                hash: SHA256Hash.fromString('a' * 64),
                size: ByteSize.fromMB(30),
              ),
            },
          ),
        ],
        platform: PlatformIdentifier.linuxX64,
      ).start().fail('Download failed');

      await runtimeRepository.saveInstallation(installation);

      final query = GetRuntimeStatusQuery();

      // Act
      final result = await handler.handle(query);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (status) {
          status.map(
            failed: (s) {
              expect(s.error, 'Download failed');
              expect(s.installationId, installation.id);
            },
            installed: (_) => fail('Should be failed'),
            notInstalled: (_) => fail('Should be failed'),
            partiallyInstalled: (_) => fail('Should be failed'),
            installing: (_) => fail('Should be failed'),
            updateAvailable: (_) => fail('Should be failed'),
          );
        },
      );
    });

    test('should return partiallyInstalled when only some modules installed', () async {
      // Arrange
      final version = RuntimeVersion.fromString('20.11.0');
      runtimeRepository.mockInstalledVersion(version);
      runtimeRepository.mockModuleInstalled(ModuleId.nodejs);
      // vscode server NOT installed - partial installation

      manifestRepository.mockModules([
        RuntimeModule.create(
          id: ModuleId.nodejs,
          name: 'Node.js',
          type: ModuleType.runtime,
          version: version,
          platformArtifacts: {
            PlatformIdentifier.linuxX64: PlatformArtifact(
              url: DownloadUrl('https://example.com/node.tar.xz'),
              hash: SHA256Hash.fromString('a' * 64),
              size: ByteSize.fromMB(30),
            ),
          },
        ),
        RuntimeModule.create(
          id: ModuleId.openVSCodeServer,
          name: 'OpenVSCode Server',
          type: ModuleType.server,
          version: version,
          platformArtifacts: {
            PlatformIdentifier.linuxX64: PlatformArtifact(
              url: DownloadUrl('https://example.com/vscode.tar.gz'),
              hash: SHA256Hash.fromString('b' * 64),
              size: ByteSize.fromMB(100),
            ),
          },
        ),
      ]);

      final query = GetRuntimeStatusQuery();

      // Act
      final result = await handler.handle(query);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (status) {
          status.map(
            partiallyInstalled: (s) {
              expect(s.installedModules, hasLength(1));
              expect(s.installedModules.first, ModuleId.nodejs);
              expect(s.missingModules, hasLength(1));
              expect(s.missingModules.first, ModuleId.openVSCodeServer);
            },
            installed: (_) => fail('Should be partially installed'),
            notInstalled: (_) => fail('Should be partially installed'),
            installing: (_) => fail('Should be partially installed'),
            failed: (_) => fail('Should be partially installed'),
            updateAvailable: (_) => fail('Should be partially installed'),
          );
        },
      );
    });
  });
}
