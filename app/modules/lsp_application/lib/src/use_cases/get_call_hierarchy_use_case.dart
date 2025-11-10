import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Gets call hierarchy (callers and callees).
///
/// Call hierarchy shows:
/// - **Incoming calls**: Who calls this function? (callers)
/// - **Outgoing calls**: What does this function call? (callees)
///
/// This is used for:
/// - Understanding code flow
/// - Finding all callers of a function
/// - Tracing execution paths
/// - Refactoring impact analysis
///
/// Example:
/// ```dart
/// final useCase = GetCallHierarchyUseCase(lspRepository);
///
/// // Get call hierarchy for a function
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/lib/service.dart'),
///   position: CursorPosition.create(line: 10, column: 5), // On function name
/// );
///
/// result.fold(
///   (failure) => showError(failure),
///   (hierarchyResult) {
///     print('Incoming calls (callers): ${hierarchyResult.incomingCalls.length}');
///     print('Outgoing calls (callees): ${hierarchyResult.outgoingCalls.length}');
///     displayCallHierarchy(hierarchyResult);
///   },
/// );
/// ```
class GetCallHierarchyUseCase {
  final ILspClientRepository _lspRepository;

  GetCallHierarchyUseCase(this._lspRepository);

  /// Gets call hierarchy for a symbol at position.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [position]: Position of the symbol
  /// - [direction]: Direction of hierarchy (incoming, outgoing, or both)
  ///
  /// Returns:
  /// - Right(CallHierarchyResult) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, CallHierarchyResult>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required CursorPosition position,
    CallHierarchyDirection direction = CallHierarchyDirection.both,
  }) async {
    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Prepare call hierarchy at position
        final prepareResult = await _lspRepository.prepareCallHierarchy(
          sessionId: session.id,
          documentUri: documentUri,
          position: position,
        );

        return prepareResult.fold(
          (failure) => left(failure),
          (item) async {
            if (item == null) {
              // No symbol at position
              return left(const LspFailure.unexpected(
                message: 'No call hierarchy item found at position',
              ));
            }

            List<CallHierarchyIncomingCall> incomingCalls = [];
            List<CallHierarchyOutgoingCall> outgoingCalls = [];

            // Get incoming calls (who calls this function?)
            if (direction == CallHierarchyDirection.incoming ||
                direction == CallHierarchyDirection.both) {
              final incomingResult =
                  await _lspRepository.getIncomingCalls(
                sessionId: session.id,
                item: item,
              );

              incomingResult.fold(
                (_) => null, // Ignore errors for incoming calls
                (calls) => incomingCalls = calls,
              );
            }

            // Get outgoing calls (what does this function call?)
            if (direction == CallHierarchyDirection.outgoing ||
                direction == CallHierarchyDirection.both) {
              final outgoingResult =
                  await _lspRepository.getOutgoingCalls(
                sessionId: session.id,
                item: item,
              );

              outgoingResult.fold(
                (_) => null, // Ignore errors for outgoing calls
                (calls) => outgoingCalls = calls,
              );
            }

            return right(CallHierarchyResult(
              item: item,
              incomingCalls: incomingCalls,
              outgoingCalls: outgoingCalls,
            ));
          },
        );
      },
    );
  }
}

/// Direction for call hierarchy query.
enum CallHierarchyDirection {
  /// Get only incoming calls (callers)
  incoming,

  /// Get only outgoing calls (callees)
  outgoing,

  /// Get both incoming and outgoing calls
  both,
}
