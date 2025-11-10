import 'package:freezed_annotation/freezed_annotation.dart';

part 'signature_help.freezed.dart';

/// Signature help information from LSP server.
///
/// Shows function/method parameter information at cursor.
@freezed
class SignatureHelp with _$SignatureHelp {
  const factory SignatureHelp({
    required List<SignatureInformation> signatures,
    int? activeSignature,
    int? activeParameter,
  }) = _SignatureHelp;

  const SignatureHelp._();

  /// Empty signature help (no information available)
  static const empty = SignatureHelp(signatures: []);

  /// Gets the currently active signature
  SignatureInformation? get currentSignature {
    if (signatures.isEmpty) return null;
    final index = activeSignature ?? 0;
    if (index < 0 || index >= signatures.length) return null;
    return signatures[index];
  }
}

/// Information about a function/method signature
@freezed
class SignatureInformation with _$SignatureInformation {
  const factory SignatureInformation({
    required String label,
    String? documentation,
    List<ParameterInformation>? parameters,
    int? activeParameter,
  }) = _SignatureInformation;
}

/// Information about a function parameter
@freezed
class ParameterInformation with _$ParameterInformation {
  const factory ParameterInformation({
    required String label,
    String? documentation,
  }) = _ParameterInformation;
}
