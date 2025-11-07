import '../../domain/entities/file_document.dart';
import '../../domain/failures/domain_failure.dart';
import '../../domain/value_objects/file_name.dart';

abstract class FileRepository {
  Future<Either<DomainFailure, FileDocument>> create({
    required String folderId,
    required String name,
    String? initialContent,
    String? language,
    Map<String, dynamic>? metadata,
  });

  Future<Either<DomainFailure, FileDocument>> load(String id);

  Future<Either<DomainFailure, void>> save(FileDocument file);

  Future<Either<DomainFailure, void>> delete(String id);

  Future<Either<DomainFailure, FileDocument>> move({
    required String fileId,
    required String targetFolderId,
  });

  Future<Either<DomainFailure, FileDocument>> rename({
    required String fileId,
    required String newName,
  });

  Future<Either<DomainFailure, FileDocument>> duplicate({
    required String fileId,
    String? newName,
  });

  Stream<Either<DomainFailure, FileDocument>> watch(String id);

  Future<Either<DomainFailure, List<FileDocument>>> listInFolder(
    String folderId,
  );

  Future<Either<DomainFailure, List<FileDocument>>> search({
    String? query,
    String? language,
    String? folderId,
  });
}
