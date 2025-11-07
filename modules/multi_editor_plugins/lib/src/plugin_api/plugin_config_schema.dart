/// Type of configuration field
enum ConfigFieldType { string, number, boolean, select, multiSelect, object }

/// Validation rules for a configuration field
class ConfigFieldSchema {
  final String key;
  final ConfigFieldType type;
  final String? label;
  final String? description;
  final dynamic defaultValue;
  final bool required;
  final List<String>? options; // For select/multiSelect
  final num? min; // For number
  final num? max; // For number
  final String? pattern; // Regex for string
  final Map<String, ConfigFieldSchema>? properties; // For object

  const ConfigFieldSchema({
    required this.key,
    required this.type,
    this.label,
    this.description,
    this.defaultValue,
    this.required = false,
    this.options,
    this.min,
    this.max,
    this.pattern,
    this.properties,
  });

  /// Validate a value against this schema
  ConfigValidationResult validate(dynamic value) {
    final errors = <String>[];

    // Required check
    if (required && (value == null || value == '')) {
      errors.add('Field "$key" is required');
      return ConfigValidationResult(isValid: false, errors: errors);
    }

    if (value == null) {
      return const ConfigValidationResult(isValid: true);
    }

    // Type validation
    switch (type) {
      case ConfigFieldType.string:
        if (value is! String) {
          errors.add('Field "$key" must be a string');
        } else if (pattern != null) {
          final regex = RegExp(pattern!);
          if (!regex.hasMatch(value)) {
            errors.add('Field "$key" does not match pattern: $pattern');
          }
        }
        break;

      case ConfigFieldType.number:
        if (value is! num) {
          errors.add('Field "$key" must be a number');
        } else {
          if (min != null && value < min!) {
            errors.add('Field "$key" must be >= $min');
          }
          if (max != null && value > max!) {
            errors.add('Field "$key" must be <= $max');
          }
        }
        break;

      case ConfigFieldType.boolean:
        if (value is! bool) {
          errors.add('Field "$key" must be a boolean');
        }
        break;

      case ConfigFieldType.select:
        if (value is! String) {
          errors.add('Field "$key" must be a string');
        } else if (options != null && !options!.contains(value)) {
          errors.add('Field "$key" must be one of: ${options!.join(", ")}');
        }
        break;

      case ConfigFieldType.multiSelect:
        if (value is! List) {
          errors.add('Field "$key" must be a list');
        } else if (options != null) {
          for (final item in value) {
            if (!options!.contains(item)) {
              errors.add('Invalid option in "$key": $item');
            }
          }
        }
        break;

      case ConfigFieldType.object:
        if (value is! Map) {
          errors.add('Field "$key" must be an object');
        } else if (properties != null) {
          for (final entry in properties!.entries) {
            final fieldKey = entry.key;
            final fieldSchema = entry.value;
            final fieldValue = value[fieldKey];
            final result = fieldSchema.validate(fieldValue);
            errors.addAll(result.errors);
          }
        }
        break;
    }

    return ConfigValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Get default value for this field
  dynamic getDefault() {
    if (defaultValue != null) return defaultValue;

    switch (type) {
      case ConfigFieldType.string:
      case ConfigFieldType.select:
        return '';
      case ConfigFieldType.number:
        return 0;
      case ConfigFieldType.boolean:
        return false;
      case ConfigFieldType.multiSelect:
        return [];
      case ConfigFieldType.object:
        if (properties != null) {
          final obj = <String, dynamic>{};
          for (final entry in properties!.entries) {
            obj[entry.key] = entry.value.getDefault();
          }
          return obj;
        }
        return {};
    }
  }
}

/// Result of configuration validation
class ConfigValidationResult {
  final bool isValid;
  final List<String> errors;

  const ConfigValidationResult({required this.isValid, this.errors = const []});

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: ${errors.join(", ")}';
}

/// Schema for plugin configuration
class PluginConfigSchema {
  final Map<String, ConfigFieldSchema> fields;

  const PluginConfigSchema(this.fields);

  /// Validate configuration data
  ConfigValidationResult validate(Map<String, dynamic> config) {
    final allErrors = <String>[];

    for (final entry in fields.entries) {
      final key = entry.key;
      final schema = entry.value;
      final value = config[key];

      final result = schema.validate(value);
      allErrors.addAll(result.errors);
    }

    return ConfigValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
    );
  }

  /// Get default configuration
  Map<String, dynamic> getDefaults() {
    final defaults = <String, dynamic>{};
    for (final entry in fields.entries) {
      defaults[entry.key] = entry.value.getDefault();
    }
    return defaults;
  }
}
