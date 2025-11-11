/// Host function interface
///
/// Base interface for all host functions that plugins can call.
/// Each host function is a capability provided by the host system.
///
/// ## Design Principles
///
/// - **Single Responsibility**: Each function does one thing
/// - **Type Safety**: Strongly typed result
/// - **Async by Default**: All operations are async for consistency
///
/// ## Example Implementation
///
/// ```dart
/// class GetCurrentFileFunction extends HostFunction<FileDocument> {
///   final ICodeEditorRepository _repository;
///
///   GetCurrentFileFunction(this._repository);
///
///   @override
///   HostFunctionSignature get signature => HostFunctionSignature(
///     name: 'get_current_file',
///     description: 'Get the currently open file',
///     params: [],
///     returnType: 'FileDocument',
///   );
///
///   @override
///   Future<FileDocument> call(List<dynamic> args) async {
///     return await _repository.getCurrentFile();
///   }
/// }
/// ```
///
/// ## With Parameters
///
/// ```dart
/// class OpenFileFunction extends HostFunction<void> {
///   final ICodeEditorRepository _repository;
///
///   OpenFileFunction(this._repository);
///
///   @override
///   HostFunctionSignature get signature => HostFunctionSignature(
///     name: 'open_file',
///     description: 'Open a file in the editor',
///     params: [
///       HostFunctionParam('path', 'String', 'File path to open'),
///     ],
///     returnType: 'void',
///   );
///
///   @override
///   Future<void> call(List<dynamic> args) async {
///     if (args.isEmpty) {
///       throw ArgumentError('Missing required parameter: path');
///     }
///
///     final path = args[0] as String;
///     await _repository.openFile(path);
///   }
/// }
/// ```
abstract class HostFunction<TResult> {
  /// Function signature
  ///
  /// Describes function name, parameters, and return type.
  /// Used for validation and documentation.
  HostFunctionSignature get signature;

  /// Call function
  ///
  /// Execute the host function with provided arguments.
  ///
  /// ## Parameters
  ///
  /// - `args`: Positional arguments (validate based on signature)
  ///
  /// ## Returns
  ///
  /// Function result (typed as TResult)
  ///
  /// ## Throws
  ///
  /// - `ArgumentError`: If arguments are invalid
  /// - `HostFunctionException`: If execution fails
  Future<TResult> call(List<dynamic> args);

  // Optional: Validate arguments before execution

  /// Validate arguments
  ///
  /// Check if arguments match signature, accounting for optional parameters.
  ///
  /// Valid if:
  /// - args.length >= number of required parameters
  /// - args.length <= total number of parameters
  ///
  /// Override for custom validation.
  bool validateArgs(List<dynamic> args) {
    // Count required (non-optional) parameters
    final requiredCount = signature.params.where((p) => !p.optional).length;
    final totalCount = signature.params.length;

    // Must provide at least required params, but no more than total params
    return args.length >= requiredCount && args.length <= totalCount;
  }
}

/// Host function signature
///
/// Describes a host function's interface.
class HostFunctionSignature {
  /// Function name
  final String name;

  /// Function description
  final String description;

  /// Function parameters
  final List<HostFunctionParam> params;

  /// Return type name
  final String returnType;

  /// Whether function is experimental
  final bool experimental;

  /// Minimum required host version
  final String? minHostVersion;

  const HostFunctionSignature({
    required this.name,
    required this.description,
    this.params = const [],
    required this.returnType,
    this.experimental = false,
    this.minHostVersion,
  });

  /// Convert to JSON (for documentation/debugging)
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'params': params.map((p) => p.toJson()).toList(),
        'returnType': returnType,
        if (experimental) 'experimental': true,
        if (minHostVersion != null) 'minHostVersion': minHostVersion,
      };

  @override
  String toString() =>
      '$returnType $name(${params.map((p) => '${p.type} ${p.name}').join(', ')})';
}

/// Host function parameter
///
/// Describes a parameter of a host function.
class HostFunctionParam {
  /// Parameter name
  final String name;

  /// Parameter type name
  final String type;

  /// Parameter description
  final String description;

  /// Whether parameter is optional
  final bool optional;

  /// Default value (if optional)
  ///
  /// **Note**: This should only be set when [optional] is `true`.
  /// Setting [defaultValue] when [optional] is `false` has no effect and
  /// may indicate a logic error.
  final dynamic defaultValue;

  const HostFunctionParam(
    this.name,
    this.type,
    this.description, {
    this.optional = false,
    this.defaultValue,
  }) : assert(
          optional || defaultValue == null,
          'defaultValue should only be set when optional is true',
        );

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'description': description,
        if (optional) 'optional': true,
        if (defaultValue != null) 'defaultValue': defaultValue,
      };

  @override
  String toString() => '$type $name${optional ? '?' : ''}';
}
