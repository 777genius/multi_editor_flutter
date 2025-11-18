import 'dart:io';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path/path.dart' as path;
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

/// Download Service Implementation
/// Handles file downloads with progress tracking and cancellation
class DownloadService implements IDownloadService {
  final dio.Dio _dio;
  final String _downloadDir;
  final Map<CancelToken, StreamController<DownloadProgress>> _progressControllers = {};

  DownloadService({
    dio.Dio? dioClient,
    String? downloadDir,
  })  : _dio = dioClient ??
            dio.Dio(
              dio.BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 10),
                followRedirects: true,
                maxRedirects: 5,
              ),
            ),
        _downloadDir = downloadDir ?? '/tmp/vscode_runtime_downloads';

  @override
  Future<Either<DomainException, File>> download({
    required DownloadUrl url,
    required ByteSize expectedSize,
    void Function(ByteSize received, ByteSize total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Generate target path from URL filename
      final filename = url.filename;
      final targetPath = path.join(_downloadDir, filename);
      final targetFile = File(targetPath);

      // Ensure download directory exists
      await Directory(_downloadDir).create(recursive: true);

      // Map domain CancelToken to Dio CancelToken
      dio.CancelToken? dioCancelToken;
      if (cancelToken != null) {
        dioCancelToken = dio.CancelToken();
        // If domain token is cancelled, cancel dio token
        if (cancelToken.isCancelled) {
          dioCancelToken.cancel();
        }
      }

      // Download with progress tracking
      await _dio.download(
        url.value,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final downloadedSize = ByteSize(received);
            final totalSize = ByteSize(total);

            // Call progress callback
            onProgress?.call(downloadedSize, totalSize);

            // Emit to stream if exists
            if (cancelToken != null && _progressControllers.containsKey(cancelToken)) {
              _progressControllers[cancelToken]?.add(
                DownloadProgress.fromBytes(received, total),
              );
            }
          }
        },
        cancelToken: dioCancelToken,
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (!await targetFile.exists()) {
        return left(
          const DomainException('Download completed but file not found'),
        );
      }

      // Verify size matches expected
      final actualSize = await targetFile.length();
      if (actualSize != expectedSize.bytes) {
        return left(
          DomainException(
            'Downloaded file size mismatch: expected ${expectedSize.bytes}, got $actualSize',
          ),
        );
      }

      return right(targetFile);
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        return left(const DomainException('Download cancelled'));
      }
      return left(
        DomainException('Download failed: ${e.message}'),
      );
    } catch (e) {
      return left(
        DomainException('Download error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Unit>> cancelDownload(CancelToken token) async {
    try {
      // Domain CancelToken doesn't have cancel method in current implementation
      // Mark as cancelled
      token.cancel();

      // Close progress stream if exists
      if (_progressControllers.containsKey(token)) {
        await _progressControllers[token]?.close();
        _progressControllers.remove(token);
      }

      return right(unit);
    } catch (e) {
      return left(
        DomainException('Failed to cancel download: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<DownloadProgress> getProgressStream(CancelToken token) {
    if (!_progressControllers.containsKey(token)) {
      _progressControllers[token] = StreamController<DownloadProgress>.broadcast();
    }
    return _progressControllers[token]!.stream;
  }

  /// Cleanup progress controllers
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}
