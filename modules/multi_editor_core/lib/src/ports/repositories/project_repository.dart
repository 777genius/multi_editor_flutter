import '../../domain/entities/project.dart';
import '../../domain/failures/domain_failure.dart';
import '../../domain/value_objects/file_name.dart';

abstract class ProjectRepository {
  Future<Either<DomainFailure, Project>> create({
    required String name,
    String? description,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  });

  Future<Either<DomainFailure, Project>> load(String id);

  Future<Either<DomainFailure, void>> save(Project project);

  Future<Either<DomainFailure, void>> delete(String id);

  Stream<Either<DomainFailure, Project>> watch(String id);

  Future<Either<DomainFailure, List<Project>>> listAll();

  Future<Either<DomainFailure, Project>> getCurrent();
}
