import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import 'package:vscode_runtime_application/src/handlers/get_runtime_status_query_handler.dart';
import 'package:vscode_runtime_application/src/queries/get_runtime_status_query.dart';
import 'package:vscode_runtime_application/src/exceptions/application_exception.dart';

class MockRuntimeRepository extends Mock implements IRuntimeRepository {}
class MockManifestRepository extends Mock implements IManifestRepository {}

void main() {
  late GetRuntimeStatusQueryHandler handler;
  late MockRuntimeRepository mockRuntimeRepo;
  late MockManifestRepository mockManifestRepo;

  setUp(() {
    mockRuntimeRepo = MockRuntimeRepository();
    mockManifestRepo = MockManifestRepository();
    handler = GetRuntimeStatusQueryHandler(mockRuntimeRepo, mockManifestRepo);
  });

  group('GetRuntimeStatusQueryHandler', () {
    group('Not Installed', () {
      test('should return not installed when no version found', () async {
        // Arrange
        final query = GetRuntimeStatusQuery();

        when(() => mockRuntimeRepo.getInstalledVersion()).thenAnswer(
          (_) async => right(none()),
        );

        // Act
        final result = await handler.handle(query);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should return DTO'),
          (dto) {
            expect(dto.isInstalled, isFalse);
            expect(dto.isPartiallyInstalled, isFalse);
            expect(dto.isNotInstalled, isTrue);
          },
        );

        verify(() => mockRuntimeRepo.getInstalledVersion()).called(1);
        verifyNever(() => mockManifestRepo.fetchManifest());
      });
    });

    group('Fully Installed', () {
      test('should return installed when all critical modules present', () async {
        // Arrange
        final query = GetRuntimeStatusQuery();
        final version = RuntimeVersion(1, 0, 0);

        final coreModule = RuntimeModule(
          id: ModuleId('core'),
          name: 'Core',
          description: 'Core module',
          version: version,
          isRequired: true,
          isCritical: true,
          dependencies: [],
          supportedPlatforms: [PlatformIdentifier.linux],
          artifacts: [],
        );

        final manifest = RuntimeManifest(
          version: version,
          modules: [coreModule],
        );

        when(() => mockRuntimeRepo.getInstalledVersion()).thenAnswer(
          (_) async => right(some(version)),
        );

        when(() => mockManifestRepo.fetchManifest()).thenAnswer(
          (_) async => right(manifest),
        );

        when(() => mockRuntimeRepo.isModuleInstalled(ModuleId('core'))).thenAnswer(
          (_) async => right(true),
        );

        // Act
        final result = await handler.handle(query);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should return DTO'),
          (dto) {
            expect(dto.isInstalled, isTrue);
            expect(dto.version, equals(version));
          },
        );
      });
    });

    group('Error Handling', () {
      test('should return error when version check fails', () async {
        // Arrange
        final query = GetRuntimeStatusQuery();

        when(() => mockRuntimeRepo.getInstalledVersion()).thenAnswer(
          (_) async => left(const DomainException('Version check failed')),
        );

        // Act
        final result = await handler.handle(query);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) {
            expect(error, isA<ApplicationException>());
            expect(error.message, contains('Failed to get installed version'));
          },
          (_) => fail('Should return error'),
        );
      });
    });
  });
}
