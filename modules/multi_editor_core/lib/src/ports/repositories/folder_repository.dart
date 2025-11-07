import '../../domain/entities/folder.dart';
import '../../domain/failures/domain_failure.dart';
import '../../domain/value_objects/file_name.dart';

abstract class FolderRepository {
  Future<Either<DomainFailure, Folder>> create({
    required String name,
    String? parentId,
    Map<String, dynamic>? metadata,
  });

  Future<Either<DomainFailure, Folder>> load(String id);

  Future<Either<DomainFailure, void>> delete(String id);

  Future<Either<DomainFailure, Folder>> move({
    required String folderId,
    String? targetParentId,
  });

  Future<Either<DomainFailure, Folder>> rename({
    required String folderId,
    required String newName,
  });

  Stream<Either<DomainFailure, Folder>> watch(String id);

  Future<Either<DomainFailure, List<Folder>>> listInFolder(
    String? parentId,
  );

  Future<Either<DomainFailure, List<Folder>>> listAll();

  Future<Either<DomainFailure, Folder>> getRoot();
}
