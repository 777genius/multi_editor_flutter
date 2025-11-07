import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/file_document.dart';
import '../../domain/entities/folder.dart';

part 'editor_event.freezed.dart';

@freezed
sealed class EditorEvent with _$EditorEvent {
  const EditorEvent._();

  const factory EditorEvent.fileOpened({
    required FileDocument file,
  }) = FileOpened;

  const factory EditorEvent.fileClosed({
    required String fileId,
  }) = FileClosed;

  const factory EditorEvent.fileContentChanged({
    required String fileId,
    required String content,
  }) = FileContentChanged;

  const factory EditorEvent.fileSaved({
    required FileDocument file,
  }) = FileSaved;

  const factory EditorEvent.fileCreated({
    required FileDocument file,
  }) = FileCreated;

  const factory EditorEvent.fileDeleted({
    required String fileId,
  }) = FileDeleted;

  const factory EditorEvent.fileRenamed({
    required String fileId,
    required String oldName,
    required String newName,
  }) = FileRenamed;

  const factory EditorEvent.fileMoved({
    required String fileId,
    required String oldFolderId,
    required String newFolderId,
  }) = FileMoved;

  const factory EditorEvent.folderCreated({
    required Folder folder,
  }) = FolderCreated;

  const factory EditorEvent.folderDeleted({
    required String folderId,
  }) = FolderDeleted;

  const factory EditorEvent.folderRenamed({
    required String folderId,
    required String oldName,
    required String newName,
  }) = FolderRenamed;

  const factory EditorEvent.folderMoved({
    required String folderId,
    String? oldParentId,
    String? newParentId,
  }) = FolderMoved;

  const factory EditorEvent.projectChanged({
    required String projectId,
  }) = ProjectChanged;
}
