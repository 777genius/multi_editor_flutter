import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_file_entry.freezed.dart';
part 'recent_file_entry.g.dart';

@freezed
sealed class RecentFileEntry with _$RecentFileEntry {
  const RecentFileEntry._();

  const factory RecentFileEntry({
    required String fileId,
    required String fileName,
    required String filePath,
    required DateTime lastOpened,
  }) = _RecentFileEntry;

  factory RecentFileEntry.fromJson(Map<String, dynamic> json) =>
      _$RecentFileEntryFromJson(json);

  factory RecentFileEntry.create({
    required String fileId,
    required String fileName,
    required String filePath,
  }) {
    return RecentFileEntry(
      fileId: fileId,
      fileName: fileName,
      filePath: filePath,
      lastOpened: DateTime.now(),
    );
  }

  RecentFileEntry touch() => copyWith(lastOpened: DateTime.now());

  String get displayName => fileName;

  Duration timeSince(DateTime now) => now.difference(lastOpened);
}
