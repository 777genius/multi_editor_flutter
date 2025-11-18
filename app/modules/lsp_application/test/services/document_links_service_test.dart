import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}
class MockDocumentLinkHandler extends Mock implements DocumentLinkHandler {}

void main() {
  group('DocumentLinksService', () {
    late MockLspClientRepository mockLspRepository;
    late DocumentLinksService service;
    late LspSession session;
    late DocumentUri documentUri;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      service = DocumentLinksService(mockLspRepository);

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
      registerFallbackValue(DocumentLink(
        range: const Range(start: Position(line: 0, character: 0), end: Position(line: 0, character: 10)),
      ));
    });

    tearDown(() async {
      await service.dispose();
    });

    group('getDocumentLinks', () {
      test('should get document links successfully', () async {
        // Arrange
        final links = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 20)),
            target: 'https://example.com',
          ),
          DocumentLink(
            range: const Range(start: Position(line: 5, character: 10), end: Position(line: 5, character: 30)),
            target: 'file:///lib/other.dart',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(links));

        // Act
        final result = await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultLinks) {
            expect(resultLinks.length, equals(2));
            expect(resultLinks[0].target, equals('https://example.com'));
            expect(resultLinks[1].target, equals('file:///lib/other.dart'));
          },
        );

        verify(() => mockLspRepository.getDocumentLinks(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should return cached links on second call', () async {
        // Arrange
        final links = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
            target: 'https://example.com',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(links));

        // Act
        await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );
        await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        verify(() => mockLspRepository.getDocumentLinks(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should return empty when disabled', () async {
        // Arrange
        service.setEnabled(false);

        // Act
        final result = await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (links) => expect(links, isEmpty),
        );

        verifyNever(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            ));
      });

      test('should emit update event', () async {
        // Arrange
        final links = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
            target: 'https://example.com',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(links));

        final events = <DocumentLinksUpdate>[];
        final subscription = service.onLinksChanged.listen(events.add);

        // Act
        await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].links.length, equals(1));

        await subscription.cancel();
      });
    });

    group('resolveDocumentLink', () {
      test('should return link if already has target', () async {
        // Arrange
        final link = DocumentLink(
          range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
          target: 'https://example.com',
        );

        // Act
        final result = await service.resolveDocumentLink(
          languageId: LanguageId.dart,
          link: link,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resolvedLink) => expect(resolvedLink.target, equals('https://example.com')),
        );

        verifyNever(() => mockLspRepository.resolveDocumentLink(
              sessionId: any(named: 'sessionId'),
              link: any(named: 'link'),
            ));
      });

      test('should resolve link without target', () async {
        // Arrange
        final link = DocumentLink(
          range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
        );

        final resolvedLink = DocumentLink(
          range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
          target: 'https://resolved.com',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.resolveDocumentLink(
              sessionId: any(named: 'sessionId'),
              link: any(named: 'link'),
            )).thenAnswer((_) async => right(resolvedLink));

        // Act
        final result = await service.resolveDocumentLink(
          languageId: LanguageId.dart,
          link: link,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resolved) => expect(resolved.target, equals('https://resolved.com')),
        );
      });
    });

    group('openDocumentLink', () {
      test('should open HTTP link', () async {
        // Arrange
        final link = DocumentLink(
          range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
          target: 'https://example.com',
        );

        final mockHandler = MockDocumentLinkHandler();
        when(() => mockHandler.openUrl(any())).thenAnswer((_) async {});

        // Act
        final result = await service.openDocumentLink(
          languageId: LanguageId.dart,
          link: link,
          linkHandler: mockHandler,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockHandler.openUrl('https://example.com')).called(1);
      });

      test('should open file link', () async {
        // Arrange
        final link = DocumentLink(
          range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
          target: 'file:///lib/other.dart',
        );

        final mockHandler = MockDocumentLinkHandler();
        when(() => mockHandler.openFile(any())).thenAnswer((_) async {});

        // Act
        final result = await service.openDocumentLink(
          languageId: LanguageId.dart,
          link: link,
          linkHandler: mockHandler,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockHandler.openFile('/lib/other.dart')).called(1);
      });

      test('should open custom scheme link', () async {
        // Arrange
        final link = DocumentLink(
          range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
          target: 'package:test/test.dart',
        );

        final mockHandler = MockDocumentLinkHandler();
        when(() => mockHandler.openCustom(any())).thenAnswer((_) async {});

        // Act
        final result = await service.openDocumentLink(
          languageId: LanguageId.dart,
          link: link,
          linkHandler: mockHandler,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockHandler.openCustom('package:test/test.dart')).called(1);
      });

      test('should fail when link has no target', () async {
        // Arrange
        final link = DocumentLink(
          range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.resolveDocumentLink(
              sessionId: any(named: 'sessionId'),
              link: any(named: 'link'),
            )).thenAnswer((_) async => right(link));

        final mockHandler = MockDocumentLinkHandler();

        // Act
        final result = await service.openDocumentLink(
          languageId: LanguageId.dart,
          link: link,
          linkHandler: mockHandler,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('clearDocumentLinks', () {
      test('should clear links for document', () async {
        // Arrange
        final links = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
            target: 'https://example.com',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(links));

        await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Act
        service.clearDocumentLinks(documentUri: documentUri);

        final count = service.getLinkCount(documentUri: documentUri);

        // Assert
        expect(count, equals(0));
      });

      test('should emit update event when cleared', () async {
        // Arrange
        final events = <DocumentLinksUpdate>[];
        final subscription = service.onLinksChanged.listen(events.add);

        // Act
        service.clearDocumentLinks(documentUri: documentUri);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].links, isEmpty);

        await subscription.cancel();
      });
    });

    group('setEnabled', () {
      test('should clear all links when disabled', () async {
        // Arrange
        final links = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
            target: 'https://example.com',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(links));

        await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Act
        service.setEnabled(false);

        final count = service.getTotalLinkCount();

        // Assert
        expect(count, equals(0));
        expect(service.isEnabled, isFalse);
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

    group('refreshDocumentLinks', () {
      test('should force refresh links', () async {
        // Arrange
        final links = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
            target: 'https://example.com',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(links));

        await service.getDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Act
        final result = await service.refreshDocumentLinks(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockLspRepository.getDocumentLinks(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(2);
      });
    });

    group('linksForDocument', () {
      test('should filter updates for specific document', () async {
        // Arrange
        final doc1 = DocumentUri.fromFilePath('/lib/file1.dart');
        final doc2 = DocumentUri.fromFilePath('/lib/file2.dart');

        final events = <DocumentLinksUpdate>[];
        final subscription = service.linksForDocument(documentUri: doc1).listen(events.add);

        // Act
        service.clearDocumentLinks(documentUri: doc1);
        service.clearDocumentLinks(documentUri: doc2);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(doc1));

        await subscription.cancel();
      });
    });

    group('getTotalLinkCount', () {
      test('should return total count across all documents', () async {
        // Arrange
        final doc1 = DocumentUri.fromFilePath('/lib/file1.dart');
        final doc2 = DocumentUri.fromFilePath('/lib/file2.dart');

        final links1 = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
            target: 'https://example1.com',
          ),
          DocumentLink(
            range: const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 10)),
            target: 'https://example2.com',
          ),
        ];

        final links2 = [
          DocumentLink(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 10)),
            target: 'https://example3.com',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: doc1,
            )).thenAnswer((_) async => right(links1));

        when(() => mockLspRepository.getDocumentLinks(
              sessionId: any(named: 'sessionId'),
              documentUri: doc2,
            )).thenAnswer((_) async => right(links2));

        // Act
        await service.getDocumentLinks(languageId: LanguageId.dart, documentUri: doc1);
        await service.getDocumentLinks(languageId: LanguageId.dart, documentUri: doc2);

        final total = service.getTotalLinkCount();

        // Assert
        expect(total, equals(3));
      });
    });
  });
}
