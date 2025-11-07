import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain_failure.freezed.dart';

@freezed
sealed class DomainFailure with _$DomainFailure {
  const DomainFailure._();

  const factory DomainFailure.notFound({
    required String entityType,
    required String entityId,
    String? message,
  }) = _NotFound;

  const factory DomainFailure.alreadyExists({
    required String entityType,
    required String entityId,
    String? message,
  }) = _AlreadyExists;

  const factory DomainFailure.validationError({
    required String field,
    required String reason,
    String? value,
  }) = _ValidationError;

  const factory DomainFailure.permissionDenied({
    required String operation,
    required String resource,
    String? message,
  }) = _PermissionDenied;

  const factory DomainFailure.syncError({
    required String operation,
    String? message,
    Object? cause,
  }) = _SyncError;

  const factory DomainFailure.unexpected({
    required String message,
    Object? cause,
    StackTrace? stackTrace,
  }) = _Unexpected;

  String get displayMessage => when(
        notFound: (type, id, msg) =>
            msg ?? '$type with id "$id" not found',
        alreadyExists: (type, id, msg) =>
            msg ?? '$type with id "$id" already exists',
        validationError: (field, reason, value) =>
            'Validation error in $field: $reason',
        permissionDenied: (operation, resource, msg) =>
            msg ?? 'Permission denied for $operation on $resource',
        syncError: (operation, msg, cause) =>
            msg ?? 'Sync error during $operation',
        unexpected: (msg, cause, stackTrace) => msg,
      );
}
