import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/command_handler.dart';
import '../commands/cancel_installation_command.dart';
import '../exceptions/application_exception.dart';

/// Handler: Cancel Installation Command
/// Cancels an ongoing installation
@injectable
class CancelInstallationCommandHandler
    implements CommandHandler<CancelInstallationCommand, Unit> {
  final IRuntimeRepository _runtimeRepository;
  final IManifestRepository _manifestRepository;
  final IEventBus _eventBus;

  CancelInstallationCommandHandler(
    this._runtimeRepository,
    this._manifestRepository,
    this._eventBus,
  );

  @override
  Future<Either<ApplicationException, Unit>> handle(
    CancelInstallationCommand command,
  ) async {
    try {
      // 1. Load modules (needed to reconstruct installation)
      final modulesResult = await _manifestRepository.fetchManifest();
      final modules = modulesResult.fold(
        (error) => throw ApplicationException(
          'Failed to load manifest: ${error.message}',
        ),
        (m) => m,
      );

      // 2. Load installation
      final installationResult = await _runtimeRepository.loadInstallation(
        command.installationId,
        modules,
      );

      final installationOption = installationResult.fold(
        (error) => throw ApplicationException(
          'Failed to load installation: ${error.message}',
        ),
        (opt) => opt,
      );

      if (installationOption.isNone()) {
        return left(const NotFoundException('Installation not found'));
      }

      var installation = installationOption.getOrElse(() => throw Exception());

      // 3. Check if cancellable
      if (installation.status != InstallationStatus.pending &&
          installation.status != InstallationStatus.inProgress) {
        return left(InvalidOperationException(
          'Cannot cancel installation in state: ${installation.status.displayName}',
        ));
      }

      // 4. Cancel installation
      installation = installation.cancel(reason: command.reason);

      // 5. Publish events
      for (final event in installation.uncommittedEvents) {
        await _eventBus.publish(event);
      }

      installation = installation.clearEvents();

      // 6. Save state
      await _runtimeRepository.saveInstallation(installation);

      return right(unit);
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Failed to cancel installation: $e', e));
    }
  }
}
