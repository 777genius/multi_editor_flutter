import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('InlayHintsService', () {
    late MockLspClientRepository mockLspRepository;
    late InlayHintsService service;
    late LspSession session;
    late DocumentUri documentUri;
    late TextSelection range;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      service = InlayHintsService(mockLspRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      documentUri = DocumentUri.fromFilePath('/lib/test.dart');
      range = TextSelection(
        start: CursorPosition.create(line: 0, column: 0),
        end: CursorPosition.create(line: 50, column: 0),
      );

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(documentUri);
      registerFallbackValue(range);
      registerFallbackValue(InlayHint(
        position: const Position(line: 1, character: 0),
        label: 'test',
      ));
    });

    tearDown(() async {
      await service.dispose();
    });

    group('getInlayHints', () {
      test('should get inlay hints successfully', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
            kind: InlayHintKind.type,
          ),
          InlayHint(
            position: const Position(line: 10, character: 15),
            label: 'value: ',
            kind: InlayHintKind.parameter,
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        // Act
        final result = await service.getInlayHints(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          range: range,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultHints) {
            expect(resultHints.length, equals(2));
            expect(resultHints[0].label, equals(': String'));
            expect(resultHints[1].label, equals('value: '));
          },
        );
      });

      test('should return cached hints on second call', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        // Act
        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range);
        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range);

        // Assert
        verify(() => mockLspRepository.getInlayHints(
              sessionId: session.id,
              documentUri: documentUri,
              range: range,
            )).called(1);
      });

      test('should return empty when disabled', () async {
        // Arrange
        service.setEnabled(false);

        // Act
        final result = await service.getInlayHints(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          range: range,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (hints) => expect(hints, isEmpty),
        );

        verifyNever(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            ));
      });

      test('should filter type hints when disabled', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
            kind: InlayHintKind.type,
          ),
          InlayHint(
            position: const Position(line: 10, character: 15),
            label: 'value: ',
            kind: InlayHintKind.parameter,
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        service.setShowTypeHints(false);

        // Act
        final result = await service.getInlayHints(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          range: range,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultHints) {
            expect(resultHints.length, equals(1));
            expect(resultHints[0].kind, equals(InlayHintKind.parameter));
          },
        );
      });

      test('should filter parameter hints when disabled', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
            kind: InlayHintKind.type,
          ),
          InlayHint(
            position: const Position(line: 10, character: 15),
            label: 'value: ',
            kind: InlayHintKind.parameter,
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        service.setShowParameterHints(false);

        // Act
        final result = await service.getInlayHints(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          range: range,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultHints) {
            expect(resultHints.length, equals(1));
            expect(resultHints[0].kind, equals(InlayHintKind.type));
          },
        );
      });

      test('should apply filter when returning cached hints', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
            kind: InlayHintKind.type,
          ),
          InlayHint(
            position: const Position(line: 10, character: 15),
            label: 'value: ',
            kind: InlayHintKind.parameter,
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        // First call caches hints
        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range);

        // Disable type hints
        service.setShowTypeHints(false);

        // Act - second call uses cache but applies filter
        final result = await service.getInlayHints(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          range: range,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultHints) {
            expect(resultHints.length, equals(1));
            expect(resultHints[0].kind, equals(InlayHintKind.parameter));
          },
        );
      });

      test('should emit update event', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        final events = <InlayHintsUpdate>[];
        final subscription = service.onHintsChanged.listen(events.add);

        // Act
        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].hints.length, equals(1));

        await subscription.cancel();
      });
    });

    group('resolveInlayHint', () {
      test('should resolve inlay hint', () async {
        // Arrange
        final hint = InlayHint(
          position: const Position(line: 5, character: 10),
          label: ': String',
        );

        final resolvedHint = InlayHint(
          position: const Position(line: 5, character: 10),
          label: ': String',
          tooltip: 'Variable type annotation',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.resolveInlayHint(
              sessionId: any(named: 'sessionId'),
              hint: any(named: 'hint'),
            )).thenAnswer((_) async => right(resolvedHint));

        // Act
        final result = await service.resolveInlayHint(
          languageId: LanguageId.dart,
          hint: hint,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resolved) => expect(resolved.tooltip, equals('Variable type annotation')),
        );
      });
    });

    group('clearInlayHints', () {
      test('should clear hints for document', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range);

        // Act
        service.clearInlayHints(documentUri: documentUri);

        final count = service.getHintCount(documentUri: documentUri);

        // Assert
        expect(count, equals(0));
      });

      test('should emit update event when cleared', () async {
        // Arrange
        final events = <InlayHintsUpdate>[];
        final subscription = service.onHintsChanged.listen(events.add);

        // Act
        service.clearInlayHints(documentUri: documentUri);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].hints, isEmpty);

        await subscription.cancel();
      });
    });

    group('setEnabled', () {
      test('should clear all hints when disabled', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range);

        // Act
        service.setEnabled(false);

        // Assert
        expect(service.isEnabled, isFalse);
        expect(service.getHintCount(documentUri: documentUri), equals(0));
      });

      test('should allow enabling again', () async {
        // Arrange
        service.setEnabled(false);

        // Act
        service.setEnabled(true);

        // Assert
        expect(service.isEnabled, isTrue);
      });
    });

    group('setShowTypeHints', () {
      test('should not trigger events when value unchanged', () {
        // Arrange
        final events = <InlayHintsUpdate>[];
        final subscription = service.onHintsChanged.listen(events.add);

        // Act
        service.setShowTypeHints(true); // Already true by default

        // Assert
        expect(events, isEmpty);

        subscription.cancel();
      });

      test('should update show type hints flag', () {
        // Act
        service.setShowTypeHints(false);

        // Assert
        expect(service.showTypeHints, isFalse);
      });
    });

    group('setShowParameterHints', () {
      test('should not trigger events when value unchanged', () {
        // Arrange
        final events = <InlayHintsUpdate>[];
        final subscription = service.onHintsChanged.listen(events.add);

        // Act
        service.setShowParameterHints(true); // Already true by default

        // Assert
        expect(events, isEmpty);

        subscription.cancel();
      });

      test('should update show parameter hints flag', () {
        // Act
        service.setShowParameterHints(false);

        // Assert
        expect(service.showParameterHints, isFalse);
      });
    });

    group('refreshInlayHints', () {
      test('should force refresh hints', () async {
        // Arrange
        final hints = [
          InlayHint(
            position: const Position(line: 5, character: 10),
            label: ': String',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: any(named: 'range'),
            )).thenAnswer((_) async => right(hints));

        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range);

        // Act
        final result = await service.refreshInlayHints(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          range: range,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockLspRepository.getInlayHints(
              sessionId: session.id,
              documentUri: documentUri,
              range: range,
            )).called(2);
      });
    });

    group('hintsForDocument', () {
      test('should filter updates for specific document', () async {
        // Arrange
        final doc1 = DocumentUri.fromFilePath('/lib/file1.dart');
        final doc2 = DocumentUri.fromFilePath('/lib/file2.dart');

        final events = <InlayHintsUpdate>[];
        final subscription = service.hintsForDocument(documentUri: doc1).listen(events.add);

        // Act
        service.clearInlayHints(documentUri: doc1);
        service.clearInlayHints(documentUri: doc2);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(doc1));

        await subscription.cancel();
      });
    });

    group('getHintCount', () {
      test('should return total count for document across all ranges', () async {
        // Arrange
        final range1 = TextSelection(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 25, column: 0),
        );

        final range2 = TextSelection(
          start: CursorPosition.create(line: 25, column: 0),
          end: CursorPosition.create(line: 50, column: 0),
        );

        final hints1 = [
          InlayHint(position: const Position(line: 5, character: 10), label: ': String'),
          InlayHint(position: const Position(line: 10, character: 15), label: 'value: '),
        ];

        final hints2 = [
          InlayHint(position: const Position(line: 30, character: 5), label: ': int'),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: range1,
            )).thenAnswer((_) async => right(hints1));

        when(() => mockLspRepository.getInlayHints(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              range: range2,
            )).thenAnswer((_) async => right(hints2));

        // Act
        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range1);
        await service.getInlayHints(languageId: LanguageId.dart, documentUri: documentUri, range: range2);

        final count = service.getHintCount(documentUri: documentUri);

        // Assert
        expect(count, equals(3));
      });
    });
  });
}
