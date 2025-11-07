import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_manifest.freezed.dart';
part 'plugin_manifest.g.dart';

@freezed
sealed class PluginManifest with _$PluginManifest {
  const PluginManifest._();

  const factory PluginManifest({
    required String id,
    required String name,
    required String version,
    String? description,
    String? author,
    @Default([]) List<String> dependencies,
    @Default({}) Map<String, String> capabilities,
    @Default([]) List<String> activationEvents,
    @Default({}) Map<String, dynamic> metadata,
  }) = _PluginManifest;

  factory PluginManifest.fromJson(Map<String, dynamic> json) =>
      _$PluginManifestFromJson(json);

  bool requiresCapability(String capability) =>
      capabilities.containsKey(capability);

  bool hasActivationEvent(String event) => activationEvents.contains(event);
}
