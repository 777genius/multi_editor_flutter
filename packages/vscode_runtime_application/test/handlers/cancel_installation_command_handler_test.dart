import 'package:test/test.dart';
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

import '../mocks/mock_repositories.dart';
import '../mocks/mock_services.dart';

void main() {
  group('CancelInstallationCommandHandler Integration Tests', () {
    late CancelInstallationCommandHandler handler;
    late MockRuntimeRepository runtimeRepository;
    late MockEventBus eventBus;

    setUp(() {
      runtimeRepository = MockRuntimeRepository();
      eventBus = MockEventBus();

      handler = CancelInstallationCommandHandler(
        runtimeRepository,
        eventBus,
      );
    });

    test('should cancel ongoing installation successfully', () async {
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
      ).start(); // Start installation

      await runtimeRepository.saveInstallation(installation);

      final command = CancelInstallationCommand(
        installationId: installation.id,
        reason: 'User requested',
      );

      // Act
      final result = await handler.handle(command);

      // Assert
      expect(result.isRight(), isTrue);

      // Verify installation was cancelled
      final loadedInstallation = await runtimeRepository.getInstallation(installation.id);
      expect(loadedInstallation.isRight(), isTrue);

      loadedInstallation.fold(
        (_) => fail('Should load installation'),
        (optInstall) {
          optInstall.fold(
            () => fail('Installation should exist'),
            (install) {
              expect(install.status, InstallationStatus.cancelled);
            },
          );
        },
      );

      // Verify cancellation event was published
      final cancelEvents = eventBus.getEventsOfType<InstallationCancelled>();
      expect(cancelEvents, hasLength(1));
      expect(cancelEvents.first.reason, 'User requested');
    });

    test('should fail when installation does not exist', () async {
      // Arrange
      final nonExistentId = InstallationId.generate();

      final command = CancelInstallationCommand(
        installationId: nonExistentId,
      );

      // Act
      final result = await handler.handle(command);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, contains('not found')),
        (_) => fail('Should have failed'),
      );
    });

    test('should fail when installation is already completed', () async {
      // Arrange
      final module = RuntimeModule.create(
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
      );

      final installation = RuntimeInstallation.create(
        modules: [module],
        platform: PlatformIdentifier.linuxX64,
      ).start().markModuleDownloaded(module.id).markModuleVerified(module.id).markModuleInstalled(module.id); // Complete

      await runtimeRepository.saveInstallation(installation);

      final command = CancelInstallationCommand(
        installationId: installation.id,
      );

      // Act
      final result = await handler.handle(command);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, contains('cannot be cancelled')),
        (_) => fail('Should have failed'),
      );
    });

    test('should include reason in cancellation', () async {
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

      final command = CancelInstallationCommand(
        installationId: installation.id,
        reason: 'Network disconnected',
      );

      // Act
      final result = await handler.handle(command);

      // Assert
      expect(result.isRight(), isTrue);

      final loadedInstallation = await runtimeRepository.getInstallation(installation.id);
      loadedInstallation.fold(
        (_) => fail('Should load'),
        (opt) => opt.fold(
          () => fail('Should exist'),
          (install) {
            install.cancelReason.fold(
              () => fail('Should have reason'),
              (reason) => expect(reason, 'Network disconnected'),
            );
          },
        ),
      );
    });
  });
}
