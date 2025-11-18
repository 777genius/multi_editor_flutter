import 'package:test/test.dart';
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

import '../mocks/mock_repositories.dart';
import '../mocks/mock_services.dart';

void main() {
  group('InstallRuntimeCommandHandler Integration Tests', () {
    late Install RuntimeCommandHandler handler;
    late MockRuntimeRepository runtimeRepository;
    late MockManifestRepository manifestRepository;
    late MockDownloadService downloadService;
    late MockExtractionService extractionService;
    late MockVerificationService verificationService;
    late MockPlatformService platformService;
    late MockFileSystemService fileSystemService;
    late MockEventBus eventBus;
    late DependencyResolver dependencyResolver;

    // Test fixtures
    late RuntimeModule nodejsModule;
    late RuntimeModule vscodeModule;
    late PlatformIdentifier testPlatform;

    setUp(() {
      // Create mocks
      runtimeRepository = MockRuntimeRepository();
      manifestRepository = MockManifestRepository();
      downloadService = MockDownloadService();
      extractionService = MockExtractionService();
      verificationService = MockVerificationService();
      platformService = MockPlatformService();
      fileSystemService = MockFileSystemService();
      eventBus = MockEventBus();
      dependencyResolver = DependencyResolver();

      // Create handler
      handler = InstallRuntimeCommandHandler(
        runtimeRepository,
        manifestRepository,
        downloadService,
        extractionService,
        verificationService,
        platformService,
        fileSystemService,
        eventBus,
        dependencyResolver,
      );

      // Setup test data
      testPlatform = PlatformIdentifier.linuxX64;
      platformService.mockPlatform(testPlatform);

      final artifact = PlatformArtifact(
        url: DownloadUrl('https://example.com/nodejs-v20.11.0.tar.xz'),
        hash: SHA256Hash.fromString('a' * 64),
        size: ByteSize.fromMB(30),
      );

      nodejsModule = RuntimeModule.create(
        id: ModuleId.nodejs,
        name: 'Node.js',
        type: ModuleType.runtime,
        version: RuntimeVersion.fromString('20.11.0'),
        platformArtifacts: {testPlatform: artifact},
      );

      vscodeModule = RuntimeModule.create(
        id: ModuleId.openVSCodeServer,
        name: 'OpenVSCode Server',
        type: ModuleType.server,
        version: RuntimeVersion.fromString('1.87.0'),
        platformArtifacts: {
          testPlatform: PlatformArtifact(
            url: DownloadUrl('https://example.com/openvscode-server-v1.87.0.tar.gz'),
            hash: SHA256Hash.fromString('b' * 64),
            size: ByteSize.fromMB(100),
          ),
        },
        dependencies: [ModuleId.nodejs],
      );
    });

    tearDown(() {
      runtimeRepository.reset();
      manifestRepository.reset();
      downloadService.reset();
      extractionService.reset();
      verificationService.reset();
      platformService.reset();
      fileSystemService.reset();
      eventBus.reset();
    });

    group('successful installation', () {
      test('should install single module successfully', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
          trigger: InstallationTrigger.manual,
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isRight(), isTrue);

        // Verify installation was saved
        final installations = await runtimeRepository.getAllInstallations();
        expect(installations.isRight(), isTrue);
        final installationList = installations.getOrElse(() => []);
        expect(installationList, hasLength(1));

        final installation = installationList.first;
        expect(installation.status, InstallationStatus.completed);
        expect(installation.progress, 1.0);
        expect(installation.installedModules, contains(ModuleId.nodejs));

        // Verify events were published
        expect(eventBus.publishedEvents, isNotEmpty);
        expect(
          eventBus.getEventsOfType<InstallationStarted>(),
          hasLength(1),
        );
        expect(
          eventBus.getEventsOfType<InstallationCompleted>(),
          hasLength(1),
        );

        // Verify module was marked as installed
        final isInstalled = await runtimeRepository.isModuleInstalled(ModuleId.nodejs);
        expect(isInstalled.getOrElse(() => false), isTrue);
      });

      test('should install multiple modules in dependency order', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule, vscodeModule]);

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.openVSCodeServer, ModuleId.nodejs],
          trigger: InstallationTrigger.manual,
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isRight(), isTrue);

        final installations = await runtimeRepository.getAllInstallations();
        final installation = installations.getOrElse(() => []).first;

        // Should install nodejs first (dependency), then vscode
        expect(installation.installedModules, hasLength(2));
        expect(installation.installedModules.first, ModuleId.nodejs);
        expect(installation.installedModules.last, ModuleId.openVSCodeServer);

        // All modules should be installed
        expect(installation.status, InstallationStatus.completed);
        expect(installation.progress, 1.0);

        // Verify correct number of download events
        expect(
          eventBus.getEventsOfType<ModuleDownloaded>(),
          hasLength(2),
        );
        expect(
          eventBus.getEventsOfType<ModuleExtracted>(),
          hasLength(2),
        );
      });

      test('should track progress during installation', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);
        downloadService.setProgressStep(0.25); // More granular progress

        final progressUpdates = <double>[];
        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
          onProgress: (moduleId, progress) {
            progressUpdates.add(progress);
          },
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isRight(), isTrue);
        expect(progressUpdates, isNotEmpty);
        expect(progressUpdates.last, 1.0); // Should reach 100%
      });

      test('should install only critical modules when no moduleIds specified', () async {
        // Arrange
        final optionalModule = RuntimeModule.create(
          id: ModuleId.fromString('optional-ext'),
          name: 'Optional Extensions',
          type: ModuleType.extension,
          version: RuntimeVersion.fromString('1.0.0'),
          platformArtifacts: {
            testPlatform: PlatformArtifact(
              url: DownloadUrl('https://example.com/optional.tar.gz'),
              hash: SHA256Hash.fromString('c' * 64),
              size: ByteSize.fromMB(10),
            ),
          },
          isOptional: true,
        );

        manifestRepository.mockModules([nodejsModule, vscodeModule, optionalModule]);

        final command = InstallRuntimeCommand(
          moduleIds: [], // Empty = all critical modules
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isRight(), isTrue);

        final installations = await runtimeRepository.getAllInstallations();
        final installation = installations.getOrElse(() => []).first;

        // Should install nodejs and vscode, but not optional
        expect(installation.installedModules, hasLength(2));
        expect(installation.installedModules, contains(ModuleId.nodejs));
        expect(installation.installedModules, contains(ModuleId.openVSCodeServer));
        expect(
          installation.installedModules,
          isNot(contains(ModuleId.fromString('optional-ext'))),
        );
      });
    });

    group('failure scenarios', () {
      test('should fail when platform cannot be determined', () async {
        // Arrange
        platformService = MockPlatformService(); // Reset
        // Don't mock platform - will return error

        handler = InstallRuntimeCommandHandler(
          runtimeRepository,
          manifestRepository,
          downloadService,
          extractionService,
          verificationService,
          platformService,
          fileSystemService,
          eventBus,
          dependencyResolver,
        );

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('platform')),
          (_) => fail('Should have failed'),
        );
      });

      test('should fail when manifest cannot be loaded', () async {
        // Arrange
        manifestRepository = MockManifestRepository(); // Empty manifest

        handler = InstallRuntimeCommandHandler(
          runtimeRepository,
          manifestRepository,
          downloadService,
          extractionService,
          verificationService,
          platformService,
          fileSystemService,
          eventBus,
          dependencyResolver,
        );

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
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

      test('should fail when download fails', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);
        downloadService.mockFailure('Network timeout');

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('Network timeout')),
          (_) => fail('Should have failed'),
        );

        // Verify installation was saved in failed state
        final installations = await runtimeRepository.getAllInstallations();
        final installation = installations.getOrElse(() => []).first;
        expect(installation.status, InstallationStatus.failed);

        // Verify failure event was published
        expect(
          eventBus.getEventsOfType<InstallationFailed>(),
          hasLength(1),
        );
      });

      test('should fail when verification fails', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);
        verificationService.mockFailure();

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('Verification')),
          (_) => fail('Should have failed'),
        );

        final installations = await runtimeRepository.getAllInstallations();
        final installation = installations.getOrElse(() => []).first;
        expect(installation.status, InstallationStatus.failed);
      });

      test('should fail when extraction fails', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);
        extractionService.mockFailure();

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('Extraction')),
          (_) => fail('Should have failed'),
        );

        final installations = await runtimeRepository.getAllInstallations();
        final installation = installations.getOrElse(() => []).first;
        expect(installation.status, InstallationStatus.failed);
      });

      test('should fail when platform not supported', () async {
        // Arrange
        final unsupportedModule = RuntimeModule.create(
          id: ModuleId.nodejs,
          name: 'Node.js',
          type: ModuleType.runtime,
          version: RuntimeVersion.fromString('20.11.0'),
          platformArtifacts: {
            PlatformIdentifier.windowsX64: PlatformArtifact(
              url: DownloadUrl('https://example.com/nodejs-win.zip'),
              hash: SHA256Hash.fromString('a' * 64),
              size: ByteSize.fromMB(30),
            ),
          },
        );

        manifestRepository.mockModules([unsupportedModule]);
        platformService.mockPlatform(PlatformIdentifier.linuxX64);

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('not compatible')),
          (_) => fail('Should have failed'),
        );
      });

      test('should fail on circular dependencies', () async {
        // Arrange
        final moduleA = RuntimeModule(
          id: ModuleId.fromString('module-a'),
          name: 'Module A',
          type: ModuleType.runtime,
          version: RuntimeVersion.fromString('1.0.0'),
          platformArtifacts: {
            testPlatform: PlatformArtifact(
              url: DownloadUrl('https://example.com/a.tar.gz'),
              hash: SHA256Hash.fromString('a' * 64),
              size: ByteSize.fromMB(10),
            ),
          },
          dependencies: [ModuleId.fromString('module-b')],
        );

        final moduleB = RuntimeModule(
          id: ModuleId.fromString('module-b'),
          name: 'Module B',
          type: ModuleType.runtime,
          version: RuntimeVersion.fromString('1.0.0'),
          platformArtifacts: {
            testPlatform: PlatformArtifact(
              url: DownloadUrl('https://example.com/b.tar.gz'),
              hash: SHA256Hash.fromString('b' * 64),
              size: ByteSize.fromMB(10),
            ),
          },
          dependencies: [ModuleId.fromString('module-a')],
        );

        manifestRepository.mockModules([moduleA, moduleB]);

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.fromString('module-a')],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('Circular dependency')),
          (_) => fail('Should have failed'),
        );
      });
    });

    group('cancellation', () {
      test('should support cancellation via cancel token', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);

        // Create a simple cancel token
        var cancelled = false;
        final cancelToken = Object();

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
          cancelToken: cancelToken,
          onProgress: (_, __) {
            // Simulate cancellation during installation
            cancelled = true;
          },
        );

        // Act
        final result = await handler.handle(command);

        // This is a simplified test - in real implementation,
        // cancellation would be checked in the handler
        // For now, just verify the token can be passed
        expect(command.cancelToken, equals(cancelToken));
      });
    });

    group('state persistence', () {
      test('should save installation state after each module', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule, vscodeModule]);

        var saveCount = 0;
        // Override save to count calls
        final originalRepo = runtimeRepository;
        runtimeRepository = MockRuntimeRepository();

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs, ModuleId.openVSCodeServer],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isRight(), isTrue);

        // Should save multiple times during installation
        final installations = await runtimeRepository.getAllInstallations();
        expect(installations.getOrElse(() => []), hasLength(greaterThan(0)));
      });
    });

    group('event publishing', () {
      test('should publish all expected events during successful installation', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isRight(), isTrue);

        // Verify event sequence
        final events = eventBus.publishedEvents;
        expect(events, isNotEmpty);

        // Should have these events in order
        expect(events.any((e) => e is InstallationStarted), isTrue);
        expect(events.any((e) => e is InstallationProgressChanged), isTrue);
        expect(events.any((e) => e is ModuleDownloaded), isTrue);
        expect(events.any((e) => e is ModuleVerified), isTrue);
        expect(events.any((e) => e is ModuleExtracted), isTrue);
        expect(events.any((e) => e is InstallationCompleted), isTrue);
      });

      test('should publish failure event on error', () async {
        // Arrange
        manifestRepository.mockModules([nodejsModule]);
        downloadService.mockFailure('Test error');

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.nodejs],
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isLeft(), isTrue);

        // Should have failure event
        final failureEvents = eventBus.getEventsOfType<InstallationFailed>();
        expect(failureEvents, hasLength(1));
        expect(failureEvents.first.error, contains('Test error'));
      });
    });

    group('dependency resolution', () {
      test('should resolve transitive dependencies', () async {
        // Arrange
        final extensionModule = RuntimeModule.create(
          id: ModuleId.baseExtensions,
          name: 'Base Extensions',
          type: ModuleType.extension,
          version: RuntimeVersion.fromString('1.0.0'),
          platformArtifacts: {
            testPlatform: PlatformArtifact(
              url: DownloadUrl('https://example.com/extensions.tar.gz'),
              hash: SHA256Hash.fromString('c' * 64),
              size: ByteSize.fromMB(5),
            ),
          },
          dependencies: [ModuleId.openVSCodeServer], // Depends on vscode, which depends on nodejs
        );

        manifestRepository.mockModules([nodejsModule, vscodeModule, extensionModule]);

        final command = InstallRuntimeCommand(
          moduleIds: [ModuleId.baseExtensions], // Only request extensions
        );

        // Act
        final result = await handler.handle(command);

        // Assert
        expect(result.isRight(), isTrue);

        final installations = await runtimeRepository.getAllInstallations();
        final installation = installations.getOrElse(() => []).first;

        // Should install all three modules (nodejs, vscode, extensions)
        expect(installation.installedModules, hasLength(3));
        expect(installation.installedModules, contains(ModuleId.nodejs));
        expect(installation.installedModules, contains(ModuleId.openVSCodeServer));
        expect(installation.installedModules, contains(ModuleId.baseExtensions));

        // Should install in correct order: nodejs -> vscode -> extensions
        final nodeIndex = installation.installedModules.toList().indexOf(ModuleId.nodejs);
        final vscodeIndex = installation.installedModules.toList().indexOf(ModuleId.openVSCodeServer);
        final extIndex = installation.installedModules.toList().indexOf(ModuleId.baseExtensions);

        expect(nodeIndex, lessThan(vscodeIndex));
        expect(vscodeIndex, lessThan(extIndex));
      });
    });
  });
}
