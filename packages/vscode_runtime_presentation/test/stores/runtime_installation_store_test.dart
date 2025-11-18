import 'package:test/test.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';
import 'package:vscode_runtime_presentation/vscode_runtime_presentation.dart';

// Mock command handlers for testing
class MockInstallRuntimeCommandHandler implements InstallRuntimeCommandHandler {
  bool shouldFail = false;
  void Function(ModuleId, double)? capturedOnProgress;

  @override
  Future<Either<ApplicationException, Unit>> handle(
    InstallRuntimeCommand command,
  ) async {
    capturedOnProgress = command.onProgress;

    if (shouldFail) {
      return left(ApplicationException('Test error'));
    }

    // Simulate installation with progress
    if (command.onProgress != null) {
      await Future.delayed(const Duration(milliseconds: 10));
      command.onProgress!(ModuleId.nodejs, 0.5);
      await Future.delayed(const Duration(milliseconds: 10));
      command.onProgress!(ModuleId.nodejs, 1.0);
    }

    return right(unit);
  }
}

class MockCancelInstallationCommandHandler
    implements CancelInstallationCommandHandler {
  @override
  Future<Either<ApplicationException, Unit>> handle(
    CancelInstallationCommand command,
  ) async {
    return right(unit);
  }
}

class MockGetInstallationProgressQueryHandler
    implements GetInstallationProgressQueryHandler {
  InstallationProgressDto? mockProgress;

  @override
  Future<Either<ApplicationException, InstallationProgressDto>> handle(
    GetInstallationProgressQuery query,
  ) async {
    if (mockProgress != null) {
      return right(mockProgress!);
    }
    return left(ApplicationException('No progress available'));
  }
}

void main() {
  group('RuntimeInstallationStore', () {
    late RuntimeInstallationStore store;
    late MockInstallRuntimeCommandHandler installHandler;
    late MockCancelInstallationCommandHandler cancelHandler;
    late MockGetInstallationProgressQueryHandler progressHandler;

    setUp(() {
      installHandler = MockInstallRuntimeCommandHandler();
      cancelHandler = MockCancelInstallationCommandHandler();
      progressHandler = MockGetInstallationProgressQueryHandler();

      store = RuntimeInstallationStore(
        installHandler,
        cancelHandler,
        progressHandler,
      );
    });

    group('initial state', () {
      test('should have correct initial values', () {
        expect(store.currentInstallationId, isNull);
        expect(store.status, InstallationStatus.pending);
        expect(store.overallProgress, 0.0);
        expect(store.currentModule, isNull);
        expect(store.currentModuleProgress, 0.0);
        expect(store.errorMessage, isNull);
        expect(store.installedModuleCount, 0);
        expect(store.totalModuleCount, 0);
      });

      test('computed values should be correct', () {
        expect(store.isInstalling, isFalse);
        expect(store.isCompleted, isFalse);
        expect(store.hasFailed, isFalse);
        expect(store.canCancel, isFalse);
        expect(store.progressText, 'Preparing...');
        expect(store.statusMessage, 'Ready to install');
      });
    });

    group('install action', () {
      test('should update status during installation', () async {
        // Track reactions
        final statusChanges = <InstallationStatus>[];
        mobx.reaction(
          (_) => store.status,
          (InstallationStatus status) => statusChanges.add(status),
        );

        // Act
        await store.install(
          moduleIds: [ModuleId.nodejs],
          trigger: InstallationTrigger.manual,
        );

        // Assert
        expect(statusChanges, contains(InstallationStatus.inProgress));
        expect(store.status, InstallationStatus.completed);
        expect(store.isCompleted, isTrue);
      });

      test('should track progress during installation', () async {
        // Track progress changes
        final progressValues = <double>[];
        mobx.reaction(
          (_) => store.currentModuleProgress,
          (double progress) => progressValues.add(progress),
        );

        // Act
        await store.install(
          moduleIds: [ModuleId.nodejs],
        );

        // Assert
        expect(progressValues, isNotEmpty);
        expect(progressValues, contains(0.5));
        expect(progressValues, contains(1.0));
      });

      test('should update current module during installation', () async {
        // Track module changes
        final moduleChanges = <ModuleId?>[];
        mobx.reaction(
          (_) => store.currentModule,
          (ModuleId? module) => moduleChanges.add(module),
        );

        // Act
        await store.install(
          moduleIds: [ModuleId.nodejs],
        );

        // Assert
        expect(moduleChanges, contains(ModuleId.nodejs));
      });

      test('should calculate overall progress correctly', () async {
        // Act
        await store.install(
          moduleIds: [ModuleId.nodejs, ModuleId.openVSCodeServer],
        );

        // Simulate installing first module
        installHandler.capturedOnProgress!(ModuleId.nodejs, 1.0);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - should be 50% after first module
        expect(store.overallProgress, closeTo(0.5, 0.01));

        // Simulate installing second module
        installHandler.capturedOnProgress!(ModuleId.openVSCodeServer, 1.0);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - should be 100% after both modules
        expect(store.overallProgress, closeTo(1.0, 0.01));
      });

      test('should handle installation failure', () async {
        // Arrange
        installHandler.shouldFail = true;

        // Act
        await store.install(
          moduleIds: [ModuleId.nodejs],
        );

        // Assert
        expect(store.status, InstallationStatus.failed);
        expect(store.hasFailed, isTrue);
        expect(store.errorMessage, isNotNull);
        expect(store.errorMessage, contains('Test error'));
      });

      test('should set module counts correctly', () async {
        // Act
        await store.install(
          moduleIds: [ModuleId.nodejs, ModuleId.openVSCodeServer, ModuleId.baseExtensions],
        );

        // Assert
        expect(store.totalModuleCount, 3);
      });

      test('statusMessage should update with status', () async {
        // Track status messages
        final messages = <String>[];
        mobx.reaction(
          (_) => store.statusMessage,
          (String message) => messages.add(message),
        );

        // Act
        await store.install(moduleIds: [ModuleId.nodejs]);

        // Assert
        expect(messages, isNotEmpty);
        expect(messages.any((m) => m.contains('Installing')), isTrue);
        expect(messages.last, contains('completed successfully'));
      });
    });

    group('cancel action', () {
      test('should not cancel when not in progress', () async {
        // Act
        await store.cancel();

        // Assert - should still be pending
        expect(store.status, InstallationStatus.pending);
      });

      test('should cancel when installation is in progress', () async {
        // Arrange - start installation (don't await to keep it "in progress")
        store.install(moduleIds: [ModuleId.nodejs]);
        await Future.delayed(const Duration(milliseconds: 10));

        // Ensure we're in progress
        expect(store.isInstalling, isTrue);

        // Act
        await store.cancel(reason: 'User requested');

        // Assert
        expect(store.status, InstallationStatus.cancelled);
      });

      test('canCancel computed should be true during installation', () async {
        // Start installation
        final future = store.install(moduleIds: [ModuleId.nodejs]);

        // During installation
        await Future.delayed(const Duration(milliseconds: 5));
        expect(store.canCancel, isTrue);

        // After completion
        await future;
        expect(store.canCancel, isFalse);
      });
    });

    group('reset action', () {
      test('should reset all state', () async {
        // Arrange - do an installation first
        await store.install(moduleIds: [ModuleId.nodejs]);

        // Act
        store.reset();

        // Assert - should be back to initial state
        expect(store.currentInstallationId, isNull);
        expect(store.status, InstallationStatus.pending);
        expect(store.overallProgress, 0.0);
        expect(store.currentModule, isNull);
        expect(store.currentModuleProgress, 0.0);
        expect(store.errorMessage, isNull);
        expect(store.installedModuleCount, 0);
        expect(store.totalModuleCount, 0);
      });
    });

    group('loadProgress action', () {
      test('should load progress for existing installation', () async {
        // Arrange
        final installationId = InstallationId.generate();
        final mockProgress = InstallationProgressDto(
          installationId: installationId,
          status: InstallationStatus.inProgress,
          overallProgress: 0.75,
          currentModule: some(ModuleId.openVSCodeServer),
          currentModuleProgress: 0.5,
          installedModuleCount: 1,
          totalModuleCount: 2,
          statusMessages: ['Installing OpenVSCode Server...'],
        );

        progressHandler.mockProgress = mockProgress;

        // Act
        await store.loadProgress(installationId: installationId);

        // Assert
        expect(store.currentInstallationId, installationId);
        expect(store.status, InstallationStatus.inProgress);
        expect(store.overallProgress, 0.75);
        expect(store.currentModule, ModuleId.openVSCodeServer);
        expect(store.currentModuleProgress, 0.5);
        expect(store.installedModuleCount, 1);
        expect(store.totalModuleCount, 2);
      });

      test('should handle error when loading progress', () async {
        // Arrange
        progressHandler.mockProgress = null; // Will cause error

        // Act
        await store.loadProgress(installationId: InstallationId.generate());

        // Assert
        expect(store.errorMessage, isNotNull);
        expect(store.errorMessage, contains('No progress available'));
      });
    });

    group('computed values', () {
      test('isInstalling should be true when in progress', () async {
        // Start installation
        final future = store.install(moduleIds: [ModuleId.nodejs]);

        await Future.delayed(const Duration(milliseconds: 5));
        expect(store.isInstalling, isTrue);

        await future;
        expect(store.isInstalling, isFalse);
      });

      test('isCompleted should be true when completed', () async {
        expect(store.isCompleted, isFalse);

        await store.install(moduleIds: [ModuleId.nodejs]);

        expect(store.isCompleted, isTrue);
      });

      test('hasFailed should be true when failed', () async {
        installHandler.shouldFail = true;

        expect(store.hasFailed, isFalse);

        await store.install(moduleIds: [ModuleId.nodejs]);

        expect(store.hasFailed, isTrue);
      });

      test('progressText should format correctly', () {
        // Initial state
        expect(store.progressText, 'Preparing...');

        // Set some module counts (simulating installation)
        store.installedModuleCount = 1;
        store.totalModuleCount = 3;

        expect(store.progressText, '1 / 3 modules');
      });

      test('statusMessage should reflect current status', () {
        // Pending
        expect(store.statusMessage, 'Ready to install');

        // Set to in progress
        store.status = InstallationStatus.inProgress;
        store.currentModule = ModuleId.nodejs;
        expect(store.statusMessage, contains('Installing'));
        expect(store.statusMessage, contains('nodejs'));

        // Set to completed
        store.status = InstallationStatus.completed;
        expect(store.statusMessage, contains('completed successfully'));

        // Set to failed
        store.status = InstallationStatus.failed;
        store.errorMessage = 'Network error';
        expect(store.statusMessage, contains('failed'));
        expect(store.statusMessage, contains('Network error'));

        // Set to cancelled
        store.status = InstallationStatus.cancelled;
        expect(store.statusMessage, contains('cancelled'));
      });
    });

    group('reactive behavior', () {
      test('should trigger reactions on state changes', () async {
        var reactionCount = 0;

        // Setup reaction
        mobx.reaction(
          (_) => store.status,
          (_) => reactionCount++,
        );

        // Act - trigger multiple state changes
        await store.install(moduleIds: [ModuleId.nodejs]);

        // Assert - should have triggered reactions
        expect(reactionCount, greaterThan(0));
      });

      test('should trigger autorun on any observable change', () async {
        var autorunCount = 0;

        // Setup autorun
        mobx.autorun((_) {
          // Access observables
          store.status;
          store.overallProgress;
          store.currentModule;
          autorunCount++;
        });

        // Initial run
        expect(autorunCount, 1);

        // Act - change state
        await store.install(moduleIds: [ModuleId.nodejs]);

        // Assert - should have run multiple times
        expect(autorunCount, greaterThan(1));
      });
    });
  });
}
