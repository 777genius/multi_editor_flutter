import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_id.freezed.dart';
part 'plugin_id.g.dart';

@freezed
sealed class PluginId with _$PluginId {
  const PluginId._();

  const factory PluginId({
    required String value,
  }) = _PluginId;

  factory PluginId.fromJson(Map<String, dynamic> json) =>
      _$PluginIdFromJson(json);

  factory PluginId.generate(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (normalized.isEmpty) {
      throw ArgumentError('Invalid plugin name: cannot be empty after normalization');
    }

    return PluginId(value: 'plugin.$normalized');
  }

  bool get isValid => value.isNotEmpty && value.startsWith('plugin.');

  String get name => value.replaceFirst('plugin.', '');
}
