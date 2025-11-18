import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

/// Mock implementation of IDownloadService for testing
class MockDownloadService implements IDownloadService {
  final Map<DownloadUrl, File> _downloadedFiles = {};
  bool _shouldFail = false;
  String? _failureReason;
  double _progressStep = 0.1;

  @override
  Future<Either<DomainException, File>> download({
    required DownloadUrl url,
    required ByteSize expectedSize,
    void Function(ByteSize received, ByteSize total)? onProgress,
    Object? cancelToken,
  }) async {
    if (_shouldFail) {
      return left(DomainException(_failureReason ?? 'Download failed'));
    }

    // Simulate progress
    if (onProgress != null) {
      var current = 0;
      final total = expectedSize.bytes;
      while (current < total) {
        current = (current + (total * _progressStep)).round().clamp(0, total);
        await Future.delayed(const Duration(milliseconds: 10));
        onProgress(ByteSize(current), expectedSize);
      }
    }

    // Return mock file
    final file = _downloadedFiles[url] ?? File('/tmp/mock_download_${url.hashCode}.tar.gz');
    return right(file);
  }

  // Helper methods for testing
  void mockDownloadedFile(DownloadUrl url, File file) {
    _downloadedFiles[url] = file;
  }

  void mockFailure(String reason) {
    _shouldFail = true;
    _failureReason = reason;
  }

  void mockSuccess() {
    _shouldFail = false;
    _failureReason = null;
  }

  void setProgressStep(double step) {
    _progressStep = step;
  }

  void reset() {
    _downloadedFiles.clear();
    _shouldFail = false;
    _failureReason = null;
    _progressStep = 0.1;
  }
}

/// Mock implementation of IVerificationService for testing
class MockVerificationService implements IVerificationService {
  bool _shouldFail = false;

  @override
  Future<Either<DomainException, Unit>> verify({
    required File file,
    required SHA256Hash expectedHash,
  }) async {
    if (_shouldFail) {
      return left(VerificationException('Hash mismatch'));
    }
    return right(unit);
  }

  @override
  Future<Either<DomainException, Unit>> verifySize({
    required File file,
    required ByteSize expectedSize,
  }) async {
    if (_shouldFail) {
      return left(VerificationException('Size mismatch'));
    }
    return right(unit);
  }

  // Helper methods for testing
  void mockFailure() {
    _shouldFail = true;
  }

  void mockSuccess() {
    _shouldFail = false;
  }

  void reset() {
    _shouldFail = false;
  }
}

/// Mock implementation of IExtractionService for testing
class MockExtractionService implements IExtractionService {
  bool _shouldFail = false;

  @override
  Future<Either<DomainException, Directory>> extract({
    required File archiveFile,
    required String targetDirectory,
    void Function(double progress)? onProgress,
  }) async {
    if (_shouldFail) {
      return left(DomainException('Extraction failed'));
    }

    // Simulate progress
    if (onProgress != null) {
      for (var i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 10));
        onProgress(i / 10);
      }
    }

    final dir = Directory('/tmp/mock_extract/$targetDirectory');
    return right(dir);
  }

  // Helper methods for testing
  void mockFailure() {
    _shouldFail = true;
  }

  void mockSuccess() {
    _shouldFail = false;
  }

  void reset() {
    _shouldFail = false;
  }
}

/// Mock implementation of IPlatformService for testing
class MockPlatformService implements IPlatformService {
  PlatformIdentifier _currentPlatform = PlatformIdentifier.linuxX64;

  @override
  Future<Either<DomainException, PlatformIdentifier>> getCurrentPlatform() async {
    return right(_currentPlatform);
  }

  @override
  Future<Either<DomainException, bool>> isPlatformSupported(
    PlatformIdentifier platform,
  ) async {
    return right(true);
  }

  @override
  Future<Either<DomainException, String>> getOSInfo() async {
    return right('Mock OS Info');
  }

  @override
  Future<Either<DomainException, ByteSize>> getAvailableDiskSpace() async {
    return right(ByteSize.fromGB(100));
  }

  @override
  Future<Either<DomainException, bool>> hasRequiredPermissions() async {
    return right(true);
  }

  // Helper methods for testing
  void mockPlatform(PlatformIdentifier platform) {
    _currentPlatform = platform;
  }

  void reset() {
    _currentPlatform = PlatformIdentifier.linuxX64;
  }
}

/// Mock implementation of IFileSystemService for testing
class MockFileSystemService implements IFileSystemService {
  final Map<ModuleId, Directory> _moduleDirectories = {};
  final Directory _downloadDirectory = Directory('/tmp/mock_downloads');

  @override
  Future<Either<DomainException, Directory>> getModuleDirectory(
    ModuleId moduleId,
  ) async {
    final dir = _moduleDirectories[moduleId] ?? Directory('/tmp/mock_modules/${moduleId.value}');
    return right(dir);
  }

  @override
  Future<Either<DomainException, Directory>> getDownloadDirectory() async {
    return right(_downloadDirectory);
  }

  @override
  Future<Either<DomainException, Unit>> deleteModule(ModuleId moduleId) async {
    _moduleDirectories.remove(moduleId);
    return right(unit);
  }

  @override
  Future<Either<DomainException, Unit>> ensureDirectoryExists(
    Directory directory,
  ) async {
    return right(unit);
  }

  @override
  Future<Either<DomainException, bool>> directoryExists(Directory directory) async {
    return right(true);
  }

  // Helper methods for testing
  void mockModuleDirectory(ModuleId moduleId, Directory directory) {
    _moduleDirectories[moduleId] = directory;
  }

  void reset() {
    _moduleDirectories.clear();
  }
}

/// Mock implementation of IEventBus for testing
class MockEventBus implements IEventBus {
  final List<DomainEvent> publishedEvents = [];

  @override
  Future<void> publish(DomainEvent event) async {
    publishedEvents.add(event);
  }

  @override
  Stream<T> on<T extends DomainEvent>() {
    return Stream.fromIterable(
      publishedEvents.whereType<T>(),
    );
  }

  // Helper methods for testing
  List<T> getEventsOfType<T extends DomainEvent>() {
    return publishedEvents.whereType<T>().toList();
  }

  void reset() {
    publishedEvents.clear();
  }
}
