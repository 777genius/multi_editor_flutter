import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Gets type hierarchy (supertypes and subtypes).
///
/// Type hierarchy shows:
/// - **Supertypes**: Parent classes, interfaces (what this extends/implements)
/// - **Subtypes**: Child classes, implementations (what extends/implements this)
///
/// This is used for:
/// - Understanding class inheritance
/// - Finding all implementations of an interface
/// - Exploring type relationships
/// - Refactoring class hierarchies
///
/// Example:
/// ```dart
/// final useCase = GetTypeHierarchyUseCase(lspRepository);
///
/// // Get type hierarchy for a class/interface
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/lib/repository.dart'),
///   position: CursorPosition.create(line: 5, column: 6), // On class name
/// );
///
/// result.fold(
///   (failure) => showError(failure),
///   (hierarchyResult) {
///     print('Supertypes: ${hierarchyResult.supertypes.length}');
///     print('Subtypes: ${hierarchyResult.subtypes.length}');
///     displayTypeHierarchy(hierarchyResult);
///   },
/// );
/// ```
class GetTypeHierarchyUseCase {
  final ILspClientRepository _lspRepository;

  GetTypeHierarchyUseCase(this._lspRepository);

  /// Gets type hierarchy for a type at position.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [position]: Position of the type
  /// - [direction]: Direction of hierarchy (supertypes, subtypes, or both)
  ///
  /// Returns:
  /// - Right(TypeHierarchyResult) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, TypeHierarchyResult>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required CursorPosition position,
    TypeHierarchyDirection direction = TypeHierarchyDirection.both,
  }) async {
    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Prepare type hierarchy at position
        final prepareResult = await _lspRepository.prepareTypeHierarchy(
          sessionId: session.id,
          documentUri: documentUri,
          position: position,
        );

        return prepareResult.fold(
          (failure) => left(failure),
          (item) async {
            if (item == null) {
              // No type at position
              return left(const LspFailure.unexpected(
                message: 'No type hierarchy item found at position',
              ));
            }

            List<TypeHierarchyItem> supertypes = [];
            List<TypeHierarchyItem> subtypes = [];

            // Get supertypes (what this extends/implements)
            if (direction == TypeHierarchyDirection.supertypes ||
                direction == TypeHierarchyDirection.both) {
              final supertypesResult =
                  await _lspRepository.getSupertypes(
                sessionId: session.id,
                item: item,
              );

              supertypesResult.fold(
                (_) => null, // Ignore errors
                (types) => supertypes = types,
              );
            }

            // Get subtypes (what extends/implements this)
            if (direction == TypeHierarchyDirection.subtypes ||
                direction == TypeHierarchyDirection.both) {
              final subtypesResult =
                  await _lspRepository.getSubtypes(
                sessionId: session.id,
                item: item,
              );

              subtypesResult.fold(
                (_) => null, // Ignore errors
                (types) => subtypes = types,
              );
            }

            return right(TypeHierarchyResult(
              item: item,
              supertypes: supertypes,
              subtypes: subtypes,
            ));
          },
        );
      },
    );
  }
}

/// Direction for type hierarchy query.
enum TypeHierarchyDirection {
  /// Get only supertypes (parents)
  supertypes,

  /// Get only subtypes (children)
  subtypes,

  /// Get both supertypes and subtypes
  both,
}
