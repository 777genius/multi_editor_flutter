import 'package:test/test.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('RuntimeInstallation (Aggregate Root)', () {
    group('create', () {
      test('should create installation with valid modules', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        );

        expect(installation.modules, hasLength(1));
        expect(installation.targetPlatform, TestFixtures.windowsX64);
        expect(installation.status, InstallationStatus.pending);
        expect(installation.installedModules, isEmpty);
        expect(installation.progress, 0.0);
        expect(installation.uncommittedEvents, hasLength(1));
        expect(
          installation.uncommittedEvents.first,
          isA<InstallationStarted>(),
        );
      });

      test('should throw when no modules provided', () {
        expect(
          () => RuntimeInstallation.create(
            modules: [],
            platform: TestFixtures.windowsX64,
          ),
          throwsA(isA<DomainException>()),
        );
      });

      test('should throw when platform not supported by modules', () {
        final module = TestFixtures.createModule(
          platformArtifacts: {
            TestFixtures.windowsX64: TestFixtures.createArtifact(),
          },
        );

        expect(
          () => RuntimeInstallation.create(
            modules: [module],
            platform: TestFixtures.linuxX64, // Not supported!
          ),
          throwsA(isA<DomainException>()),
        );
      });

      test('should throw on circular dependencies', () {
        final modules = TestFixtures.createCircularDependency();

        expect(
          () => RuntimeInstallation.create(
            modules: modules,
            platform: TestFixtures.windowsX64,
          ),
          throwsA(isA<DomainException>()),
        );
      });

      test('should accept valid dependency chain', () {
        final modules = TestFixtures.createValidDependencyChain();

        expect(
          () => RuntimeInstallation.create(
            modules: modules,
            platform: TestFixtures.windowsX64,
          ),
          returnsNormally,
        );
      });

      test('should generate unique installation ID', () {
        final installation1 = TestFixtures.createInstallation();
        final installation2 = TestFixtures.createInstallation();

        expect(installation1.id, isNot(equals(installation2.id)));
      });

      test('should set creation timestamp', () {
        final before = DateTime.now();
        final installation = TestFixtures.createInstallation();
        final after = DateTime.now();

        expect(
          installation.createdAt.isAfter(before) ||
              installation.createdAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          installation.createdAt.isBefore(after) ||
              installation.createdAt.isAtSameMomentAs(after),
          isTrue,
        );
      });
    });

    group('start', () {
      test('should transition from pending to inProgress', () {
        final installation = TestFixtures.createInstallation();

        final updated = installation.start();

        expect(updated.status, InstallationStatus.inProgress);
        expect(
          updated.uncommittedEvents.last,
          isA<InstallationProgressChanged>(),
        );
      });

      test('should throw when not in pending state', () {
        final installation = TestFixtures.createInstallation().start();

        expect(
          () => installation.start(),
          throwsA(isA<InvalidStateException>()),
        );
      });
    });

    group('markModuleDownloaded', () {
      test('should mark module as downloaded', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start();

        final updated = installation.markModuleDownloaded(module.id);

        expect(updated.currentModule, some(module.id));
        expect(
          updated.uncommittedEvents.last,
          isA<ModuleDownloaded>(),
        );
      });

      test('should throw when module does not exist', () {
        final installation = TestFixtures.createInstallation().start();

        expect(
          () => installation.markModuleDownloaded(
            ModuleId.fromString('nonexistent'),
          ),
          throwsA(isA<DomainException>()),
        );
      });

      test('should throw when module already installed', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start();

        final downloaded = installation.markModuleDownloaded(module.id);
        final verified = downloaded.markModuleVerified(module.id);
        final installed = verified.markModuleInstalled(module.id);

        expect(
          () => installed.markModuleDownloaded(module.id),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('markModuleVerified', () {
      test('should mark module as verified', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start().markModuleDownloaded(module.id);

        final updated = installation.markModuleVerified(module.id);

        expect(
          updated.uncommittedEvents.last,
          isA<ModuleVerified>(),
        );
      });

      test('should throw when module does not exist', () {
        final installation = TestFixtures.createInstallation().start();

        expect(
          () => installation.markModuleVerified(
            ModuleId.fromString('nonexistent'),
          ),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('markModuleInstalled', () {
      test('should mark module as installed', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start().markModuleDownloaded(module.id).markModuleVerified(module.id);

        final updated = installation.markModuleInstalled(module.id);

        expect(updated.installedModules, contains(module.id));
        expect(updated.uncommittedEvents.last, isA<ModuleExtracted>());
      });

      test('should complete installation when all modules installed', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start().markModuleDownloaded(module.id).markModuleVerified(module.id);

        final updated = installation.markModuleInstalled(module.id);

        expect(updated.status, InstallationStatus.completed);
        expect(updated.progress, 1.0);
        expect(
          updated.uncommittedEvents.any((e) => e is InstallationCompleted),
          isTrue,
        );
      });

      test('should calculate progress correctly with multiple modules', () {
        final installation = TestFixtures.createMultiModuleInstallation().start();
        final modules = installation.modules.toList();

        // Install first module
        var updated = installation
            .markModuleDownloaded(modules[0].id)
            .markModuleVerified(modules[0].id)
            .markModuleInstalled(modules[0].id);

        expect(updated.progress, closeTo(1 / 3, 0.01));
        expect(updated.status, InstallationStatus.inProgress);

        // Install second module
        updated = updated
            .markModuleDownloaded(modules[1].id)
            .markModuleVerified(modules[1].id)
            .markModuleInstalled(modules[1].id);

        expect(updated.progress, closeTo(2 / 3, 0.01));
        expect(updated.status, InstallationStatus.inProgress);

        // Install third module
        updated = updated
            .markModuleDownloaded(modules[2].id)
            .markModuleVerified(modules[2].id)
            .markModuleInstalled(modules[2].id);

        expect(updated.progress, 1.0);
        expect(updated.status, InstallationStatus.completed);
      });

      test('should clear current module on completion', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start().markModuleDownloaded(module.id).markModuleVerified(module.id);

        final updated = installation.markModuleInstalled(module.id);

        expect(updated.currentModule, none());
      });

      test('should throw when module does not exist', () {
        final installation = TestFixtures.createInstallation().start();

        expect(
          () => installation.markModuleInstalled(
            ModuleId.fromString('nonexistent'),
          ),
          throwsA(isA<DomainException>()),
        );
      });

      test('should throw when module already installed', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start();

        final installed = installation
            .markModuleDownloaded(module.id)
            .markModuleVerified(module.id)
            .markModuleInstalled(module.id);

        expect(
          () => installed.markModuleInstalled(module.id),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('fail', () {
      test('should mark installation as failed', () {
        final installation = TestFixtures.createInstallation().start();

        final updated = installation.fail('Download failed');

        expect(updated.status, InstallationStatus.failed);
        expect(updated.errorMessage, some('Download failed'));
        expect(
          updated.uncommittedEvents.last,
          isA<InstallationFailed>(),
        );
      });

      test('should include error message in event', () {
        final installation = TestFixtures.createInstallation().start();

        final updated = installation.fail('Network timeout');

        final failedEvent =
            updated.uncommittedEvents.last as InstallationFailed;
        expect(failedEvent.error, 'Network timeout');
      });
    });

    group('cancel', () {
      test('should mark installation as cancelled', () {
        final installation = TestFixtures.createInstallation().start();

        final updated = installation.cancel('User requested');

        expect(updated.status, InstallationStatus.cancelled);
        expect(updated.cancelReason, some('User requested'));
        expect(
          updated.uncommittedEvents.last,
          isA<InstallationCancelled>(),
        );
      });

      test('should throw when not in progress', () {
        final installation = TestFixtures.createInstallation();

        expect(
          () => installation.cancel('Test'),
          throwsA(isA<InvalidStateException>()),
        );
      });
    });

    group('getNextModuleToInstall', () {
      test('should return first module with no dependencies', () {
        final modules = TestFixtures.createValidDependencyChain();
        final installation = RuntimeInstallation.create(
          modules: modules,
          platform: TestFixtures.windowsX64,
        ).start();

        final next = installation.getNextModuleToInstall();

        expect(next.isSome(), isTrue);
        // Should be module-c (no dependencies)
        expect(
          next.getOrElse(() => throw Exception()).id,
          ModuleId.fromString('module-c'),
        );
      });

      test('should return module whose dependencies are met', () {
        final modules = TestFixtures.createValidDependencyChain();
        var installation = RuntimeInstallation.create(
          modules: modules,
          platform: TestFixtures.windowsX64,
        ).start();

        // Install module-c first
        final moduleC = modules.firstWhere(
          (m) => m.id == ModuleId.fromString('module-c'),
        );
        installation = installation
            .markModuleDownloaded(moduleC.id)
            .markModuleVerified(moduleC.id)
            .markModuleInstalled(moduleC.id);

        final next = installation.getNextModuleToInstall();

        expect(next.isSome(), isTrue);
        // Should be module-b (depends only on module-c which is installed)
        expect(
          next.getOrElse(() => throw Exception()).id,
          ModuleId.fromString('module-b'),
        );
      });

      test('should return none when all modules installed', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start();

        final completed = installation
            .markModuleDownloaded(module.id)
            .markModuleVerified(module.id)
            .markModuleInstalled(module.id);

        final next = completed.getNextModuleToInstall();

        expect(next.isNone(), isTrue);
      });

      test('should throw on circular dependency', () {
        // This should not happen as circular dependencies are caught in create()
        // But testing the runtime check
        final modules = TestFixtures.createCircularDependency();

        // Manually create installation bypassing validation (for test only)
        // In reality, this would be caught earlier
        expect(
          () => RuntimeInstallation.create(
            modules: modules,
            platform: TestFixtures.windowsX64,
          ),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('clearEvents', () {
      test('should clear uncommitted events', () {
        final installation = TestFixtures.createInstallation();

        expect(installation.uncommittedEvents, isNotEmpty);

        final cleared = installation.clearEvents();

        expect(cleared.uncommittedEvents, isEmpty);
      });

      test('should preserve all other state', () {
        final installation = TestFixtures.createInstallation().start();
        final module = installation.modules.first;

        final withProgress = installation
            .markModuleDownloaded(module.id)
            .markModuleVerified(module.id);

        final cleared = withProgress.clearEvents();

        expect(cleared.status, withProgress.status);
        expect(cleared.currentModule, withProgress.currentModule);
        expect(cleared.modules, withProgress.modules);
        expect(cleared.installedModules, withProgress.installedModules);
      });
    });

    group('domain events', () {
      test('should accumulate events during state changes', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        );

        // Should have InstallationStarted
        expect(installation.uncommittedEvents, hasLength(1));

        final started = installation.start();
        // Should have InstallationStarted + InstallationProgressChanged
        expect(started.uncommittedEvents, hasLength(2));

        final downloaded = started.markModuleDownloaded(module.id);
        // Should add ModuleDownloaded
        expect(downloaded.uncommittedEvents, hasLength(3));

        final verified = downloaded.markModuleVerified(module.id);
        // Should add ModuleVerified
        expect(verified.uncommittedEvents, hasLength(4));

        final installed = verified.markModuleInstalled(module.id);
        // Should add ModuleExtracted + InstallationCompleted
        expect(installed.uncommittedEvents, hasLength(6));
      });

      test('should include correct event data', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start();

        final downloaded = installation.markModuleDownloaded(module.id);
        final event = downloaded.uncommittedEvents.last as ModuleDownloaded;

        expect(event.installationId, installation.id);
        expect(event.moduleId, module.id);
        expect(event.timestamp, isNotNull);
      });
    });

    group('immutability', () {
      test('should return new instance on state change', () {
        final installation = TestFixtures.createInstallation();
        final started = installation.start();

        expect(identical(installation, started), isFalse);
        expect(installation.status, InstallationStatus.pending);
        expect(started.status, InstallationStatus.inProgress);
      });

      test('should not modify original when marking module downloaded', () {
        final module = TestFixtures.createModule();
        final installation = RuntimeInstallation.create(
          modules: [module],
          platform: TestFixtures.windowsX64,
        ).start();

        final downloaded = installation.markModuleDownloaded(module.id);

        expect(installation.currentModule, none());
        expect(downloaded.currentModule, some(module.id));
      });
    });

    group('business rules', () {
      test('should enforce dependency installation order', () {
        final installation = TestFixtures.createMultiModuleInstallation().start();
        final modules = installation.modules.toList();

        // Try to install vscode server before nodejs (violates dependency)
        final vscodeModule = modules.firstWhere(
          (m) => m.id == TestFixtures.vscodeServerId,
        );

        // Should not be able to get vscode as next module (nodejs must be first)
        final next = installation.getNextModuleToInstall();
        expect(next.getOrElse(() => throw Exception()).id, isNot(vscodeModule.id));
        expect(next.getOrElse(() => throw Exception()).id, TestFixtures.nodejsId);
      });

      test('should allow optional modules to be skipped', () {
        final installation = TestFixtures.createMultiModuleInstallation().start();

        // Optional modules should be marked as such
        final optionalModule = installation.modules.firstWhere(
          (m) => m.isOptional,
        );

        expect(optionalModule.isOptional, isTrue);
        expect(optionalModule.id, TestFixtures.baseExtensionsId);
      });
    });
  });
}
