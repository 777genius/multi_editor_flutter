import '../../domain/failures/domain_failure.dart';
import '../../domain/value_objects/file_name.dart';

abstract class ValidationService {
  Either<DomainFailure, void> validateFileName(String name);

  Either<DomainFailure, void> validateFilePath(String path);

  Either<DomainFailure, void> validateFolderName(String name);

  Either<DomainFailure, void> validateProjectName(String name);

  Either<DomainFailure, void> validateFileContent(String content);

  bool isValidLanguage(String language);

  bool hasValidExtension(String fileName);
}
