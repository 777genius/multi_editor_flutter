import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('FoldingService', () {
    late MockLspClientRepository mockLspRepository;
    late FoldingService service;
    late LspSession session;
    late DocumentUri documentUri;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      service = FoldingService(mockLspRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      documentUri = DocumentUri.fromFilePath('/lib/test.dart');

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(documentUri);
    });

    tearDown(() async {
      await service.dispose();
    });

    group('getFoldingRanges', () {
      test('should get folding ranges successfully', () async {
        // Arrange
        final ranges = [
          FoldingRange(
            startLine: 5,
            endLine: 15,
            kind: FoldingRangeKind.region,
          ),
          FoldingRange(
            startLine: 20,
            endLine: 30,
            kind: FoldingRangeKind.comment,
          ),
          FoldingRange(
            startLine: 35,
            endLine: 50,
            kind: FoldingRangeKind.imports,
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        // Act
        final result = await service.getFoldingRanges(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultRanges) {
            expect(resultRanges.length, equals(3));
            expect(resultRanges[0].startLine, equals(5));
            expect(resultRanges[1].startLine, equals(20));
            expect(resultRanges[2].startLine, equals(35));
          },
        );
      });

      test('should sort ranges by start line', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 30, endLine: 40),
          FoldingRange(startLine: 10, endLine: 20),
          FoldingRange(startLine: 50, endLine: 60),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        // Act
        final result = await service.getFoldingRanges(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultRanges) {
            expect(resultRanges[0].startLine, equals(10));
            expect(resultRanges[1].startLine, equals(30));
            expect(resultRanges[2].startLine, equals(50));
          },
        );
      });

      test('should return cached ranges on second call', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 5, endLine: 15),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        // Act
        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);
        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Assert
        verify(() => mockLspRepository.getFoldingRanges(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should emit folding update event', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 5, endLine: 15),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        final events = <FoldingUpdate>[];
        final subscription = service.onFoldingChanged.listen(events.add);

        // Act
        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].ranges.length, equals(1));

        await subscription.cancel();
      });
    });

    group('foldRange', () {
      test('should fold a range', () async {
        // Arrange
        final range = FoldingRange(startLine: 10, endLine: 20);

        final ranges = [range];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        service.foldRange(documentUri: documentUri, range: range);

        // Assert
        expect(service.isFolded(documentUri: documentUri, range: range), isTrue);
        expect(service.getFoldedCount(documentUri: documentUri), equals(1));
      });

      test('should emit update event when folded', () async {
        // Arrange
        final range = FoldingRange(startLine: 10, endLine: 20);
        final ranges = [range];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        final events = <FoldingUpdate>[];
        final subscription = service.onFoldingChanged.listen(events.add);

        // Act
        service.foldRange(documentUri: documentUri, range: range);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, greaterThan(0));
        expect(events.last.foldedLines.contains(10), isTrue);

        await subscription.cancel();
      });
    });

    group('unfoldRange', () {
      test('should unfold a range', () async {
        // Arrange
        final range = FoldingRange(startLine: 10, endLine: 20);
        final ranges = [range];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        service.foldRange(documentUri: documentUri, range: range);

        // Act
        service.unfoldRange(documentUri: documentUri, range: range);

        // Assert
        expect(service.isFolded(documentUri: documentUri, range: range), isFalse);
        expect(service.getFoldedCount(documentUri: documentUri), equals(0));
      });
    });

    group('toggleFold', () {
      test('should toggle fold state', () async {
        // Arrange
        final range = FoldingRange(startLine: 10, endLine: 20);
        final ranges = [range];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act & Assert
        expect(service.isFolded(documentUri: documentUri, range: range), isFalse);

        service.toggleFold(documentUri: documentUri, range: range);
        expect(service.isFolded(documentUri: documentUri, range: range), isTrue);

        service.toggleFold(documentUri: documentUri, range: range);
        expect(service.isFolded(documentUri: documentUri, range: range), isFalse);
      });
    });

    group('foldAll', () {
      test('should fold all ranges', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 5, endLine: 15),
          FoldingRange(startLine: 20, endLine: 30),
          FoldingRange(startLine: 35, endLine: 50),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        service.foldAll(documentUri: documentUri);

        // Assert
        expect(service.getFoldedCount(documentUri: documentUri), equals(3));
      });
    });

    group('unfoldAll', () {
      test('should unfold all ranges', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 5, endLine: 15),
          FoldingRange(startLine: 20, endLine: 30),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        service.foldAll(documentUri: documentUri);

        // Act
        service.unfoldAll(documentUri: documentUri);

        // Assert
        expect(service.getFoldedCount(documentUri: documentUri), equals(0));
      });
    });

    group('foldAllByKind', () {
      test('should fold only ranges of specific kind', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 5, endLine: 15, kind: FoldingRangeKind.comment),
          FoldingRange(startLine: 20, endLine: 30, kind: FoldingRangeKind.region),
          FoldingRange(startLine: 35, endLine: 50, kind: FoldingRangeKind.comment),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        service.foldAllByKind(documentUri: documentUri, kind: FoldingRangeKind.comment);

        // Assert
        expect(service.getFoldedCount(documentUri: documentUri), equals(2));
        expect(service.isFolded(documentUri: documentUri, range: ranges[0]), isTrue);
        expect(service.isFolded(documentUri: documentUri, range: ranges[1]), isFalse);
        expect(service.isFolded(documentUri: documentUri, range: ranges[2]), isTrue);
      });
    });

    group('foldAllComments', () {
      test('should fold all comment ranges', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 5, endLine: 15, kind: FoldingRangeKind.comment),
          FoldingRange(startLine: 20, endLine: 30, kind: FoldingRangeKind.region),
          FoldingRange(startLine: 35, endLine: 50, kind: FoldingRangeKind.comment),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        service.foldAllComments(documentUri: documentUri);

        // Assert
        expect(service.getFoldedCount(documentUri: documentUri), equals(2));
      });
    });

    group('foldAllImports', () {
      test('should fold all import ranges', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 1, endLine: 5, kind: FoldingRangeKind.imports),
          FoldingRange(startLine: 10, endLine: 20, kind: FoldingRangeKind.region),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        service.foldAllImports(documentUri: documentUri);

        // Assert
        expect(service.getFoldedCount(documentUri: documentUri), equals(1));
      });
    });

    group('foldAtLine', () {
      test('should fold range at specific line', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 10, endLine: 20),
          FoldingRange(startLine: 25, endLine: 35),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        final result = service.foldAtLine(documentUri: documentUri, line: 10);

        // Assert
        expect(result, isTrue);
        expect(service.getFoldedCount(documentUri: documentUri), equals(1));
      });

      test('should return false when no range at line', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 10, endLine: 20),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        final result = service.foldAtLine(documentUri: documentUri, line: 99);

        // Assert
        expect(result, isFalse);
      });
    });

    group('clearFoldingRanges', () {
      test('should clear ranges and folded state', () async {
        // Arrange
        final ranges = [
          FoldingRange(startLine: 10, endLine: 20),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getFoldingRanges(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(ranges));

        await service.getFoldingRanges(languageId: LanguageId.dart, documentUri: documentUri);
        service.foldAll(documentUri: documentUri);

        // Act
        service.clearFoldingRanges(documentUri: documentUri);

        // Assert
        expect(service.getFoldingRangeCount(documentUri: documentUri), equals(0));
        expect(service.getFoldedCount(documentUri: documentUri), equals(0));
      });
    });

    group('FoldingUpdate', () {
      test('should calculate all folded correctly', () {
        // Arrange
        final update = FoldingUpdate(
          documentUri: documentUri,
          ranges: [
            FoldingRange(startLine: 1, endLine: 5),
            FoldingRange(startLine: 10, endLine: 15),
          ],
          foldedLines: {1, 10},
        );

        // Assert
        expect(update.allFolded, isTrue);
        expect(update.noneFolded, isFalse);
      });

      test('should calculate none folded correctly', () {
        // Arrange
        final update = FoldingUpdate(
          documentUri: documentUri,
          ranges: [
            FoldingRange(startLine: 1, endLine: 5),
            FoldingRange(startLine: 10, endLine: 15),
          ],
          foldedLines: {},
        );

        // Assert
        expect(update.allFolded, isFalse);
        expect(update.noneFolded, isTrue);
      });
    });
  });
}
