import 'plugin_config_schema.dart';

/// Builder for constructing ConfigFieldSchema with a fluent API
///
/// Example usage:
/// ```dart
/// final schema = ConfigFieldSchemaBuilder()
///   .withKey('timeout')
///   .asNumber()
///   .withLabel('Request Timeout')
///   .withDescription('Timeout in milliseconds')
///   .withDefault(5000)
///   .withRange(min: 1000, max: 60000)
///   .required()
///   .build();
/// ```
class ConfigFieldSchemaBuilder {
  String? _key;
  ConfigFieldType? _type;
  String? _label;
  String? _description;
  dynamic _defaultValue;
  bool _required = false;
  List<String>? _options;
  num? _min;
  num? _max;
  String? _pattern;
  Map<String, ConfigFieldSchema>? _properties;

  ConfigFieldSchemaBuilder();

  /// Set the field key (required)
  ConfigFieldSchemaBuilder withKey(String key) {
    _key = key;
    return this;
  }

  /// Set the field type to string
  ConfigFieldSchemaBuilder asString() {
    _type = ConfigFieldType.string;
    return this;
  }

  /// Set the field type to number
  ConfigFieldSchemaBuilder asNumber() {
    _type = ConfigFieldType.number;
    return this;
  }

  /// Set the field type to boolean
  ConfigFieldSchemaBuilder asBoolean() {
    _type = ConfigFieldType.boolean;
    return this;
  }

  /// Set the field type to select
  ConfigFieldSchemaBuilder asSelect(List<String> options) {
    _type = ConfigFieldType.select;
    _options = options;
    return this;
  }

  /// Set the field type to multiSelect
  ConfigFieldSchemaBuilder asMultiSelect(List<String> options) {
    _type = ConfigFieldType.multiSelect;
    _options = options;
    return this;
  }

  /// Set the field type to object
  ConfigFieldSchemaBuilder asObject(Map<String, ConfigFieldSchema> properties) {
    _type = ConfigFieldType.object;
    _properties = properties;
    return this;
  }

  /// Set the field label
  ConfigFieldSchemaBuilder withLabel(String label) {
    _label = label;
    return this;
  }

  /// Set the field description
  ConfigFieldSchemaBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  /// Set the default value
  ConfigFieldSchemaBuilder withDefault(dynamic value) {
    _defaultValue = value;
    return this;
  }

  /// Mark the field as required
  ConfigFieldSchemaBuilder required() {
    _required = true;
    return this;
  }

  /// Mark the field as optional
  ConfigFieldSchemaBuilder optional() {
    _required = false;
    return this;
  }

  /// Set min/max range for number fields
  ConfigFieldSchemaBuilder withRange({num? min, num? max}) {
    _min = min;
    _max = max;
    return this;
  }

  /// Set validation pattern for string fields
  ConfigFieldSchemaBuilder withPattern(String pattern) {
    _pattern = pattern;
    return this;
  }

  /// Build the ConfigFieldSchema
  ///
  /// Throws [ArgumentError] if required fields are missing or invalid
  ConfigFieldSchema build() {
    // Validate required fields
    if (_key == null || _key!.isEmpty) {
      throw ArgumentError('Field key is required');
    }
    if (_type == null) {
      throw ArgumentError('Field type is required');
    }

    // Validate type-specific requirements
    if (_type == ConfigFieldType.select || _type == ConfigFieldType.multiSelect) {
      if (_options == null || _options!.isEmpty) {
        throw ArgumentError('Options are required for select/multiSelect fields');
      }
    }

    if (_type == ConfigFieldType.object) {
      if (_properties == null || _properties!.isEmpty) {
        throw ArgumentError('Properties are required for object fields');
      }
    }

    // Validate default value type
    if (_defaultValue != null) {
      _validateDefaultValue();
    }

    return ConfigFieldSchema(
      key: _key!,
      type: _type!,
      label: _label,
      description: _description,
      defaultValue: _defaultValue,
      required: _required,
      options: _options,
      min: _min,
      max: _max,
      pattern: _pattern,
      properties: _properties,
    );
  }

  void _validateDefaultValue() {
    switch (_type!) {
      case ConfigFieldType.string:
      case ConfigFieldType.select:
        if (_defaultValue is! String) {
          throw ArgumentError('Default value must be a string for $_type fields');
        }
        break;
      case ConfigFieldType.number:
        if (_defaultValue is! num) {
          throw ArgumentError('Default value must be a number for $_type fields');
        }
        break;
      case ConfigFieldType.boolean:
        if (_defaultValue is! bool) {
          throw ArgumentError('Default value must be a boolean for $_type fields');
        }
        break;
      case ConfigFieldType.multiSelect:
        if (_defaultValue is! List) {
          throw ArgumentError('Default value must be a list for $_type fields');
        }
        break;
      case ConfigFieldType.object:
        if (_defaultValue is! Map) {
          throw ArgumentError('Default value must be a map for $_type fields');
        }
        break;
    }
  }

  /// Reset the builder to initial state
  void reset() {
    _key = null;
    _type = null;
    _label = null;
    _description = null;
    _defaultValue = null;
    _required = false;
    _options = null;
    _min = null;
    _max = null;
    _pattern = null;
    _properties = null;
  }

  /// Create a builder from an existing schema
  factory ConfigFieldSchemaBuilder.fromSchema(ConfigFieldSchema schema) {
    final builder = ConfigFieldSchemaBuilder();
    builder.withKey(schema.key);
    builder._type = schema.type;

    if (schema.label != null && schema.label!.isNotEmpty) {
      builder.withLabel(schema.label!);
    }
    if (schema.description != null && schema.description!.isNotEmpty) {
      builder.withDescription(schema.description!);
    }
    if (schema.defaultValue != null) {
      builder.withDefault(schema.defaultValue);
    }

    if (schema.required) {
      builder.required();
    }

    if (schema.options != null) {
      builder._options = schema.options;
    }
    if (schema.min != null) {
      builder._min = schema.min;
    }
    if (schema.max != null) {
      builder._max = schema.max;
    }
    if (schema.pattern != null) {
      builder.withPattern(schema.pattern!);
    }
    if (schema.properties != null) {
      builder._properties = schema.properties;
    }

    return builder;
  }
}

/// Builder for constructing PluginConfigSchema with a fluent API
///
/// Example usage:
/// ```dart
/// final configSchema = PluginConfigSchemaBuilder()
///   .addField(
///     ConfigFieldSchemaBuilder()
///       .withKey('enabled')
///       .asBoolean()
///       .withDefault(true)
///       .required()
///       .build(),
///   )
///   .addField(
///     ConfigFieldSchemaBuilder()
///       .withKey('timeout')
///       .asNumber()
///       .withDefault(5000)
///       .withRange(min: 1000, max: 60000)
///       .build(),
///   )
///   .build();
/// ```
class PluginConfigSchemaBuilder {
  final Map<String, ConfigFieldSchema> _fields = {};

  PluginConfigSchemaBuilder();

  /// Add a single field schema
  PluginConfigSchemaBuilder addField(ConfigFieldSchema field) {
    _fields[field.key] = field;
    return this;
  }

  /// Add multiple field schemas
  PluginConfigSchemaBuilder addFields(List<ConfigFieldSchema> fields) {
    for (final field in fields) {
      _fields[field.key] = field;
    }
    return this;
  }

  /// Add a field using a builder function
  PluginConfigSchemaBuilder field(
    void Function(ConfigFieldSchemaBuilder) builderFn,
  ) {
    final builder = ConfigFieldSchemaBuilder();
    builderFn(builder);
    final field = builder.build();
    _fields[field.key] = field;
    return this;
  }

  /// Remove a field by key
  PluginConfigSchemaBuilder removeField(String key) {
    _fields.remove(key);
    return this;
  }

  /// Build the PluginConfigSchema
  PluginConfigSchema build() {
    if (_fields.isEmpty) {
      throw ArgumentError('At least one field is required');
    }

    return PluginConfigSchema(Map.unmodifiable(_fields));
  }

  /// Reset the builder to initial state
  void reset() {
    _fields.clear();
  }

  /// Create a builder from an existing schema
  factory PluginConfigSchemaBuilder.fromSchema(PluginConfigSchema schema) {
    final builder = PluginConfigSchemaBuilder();
    for (final field in schema.fields.values) {
      builder.addField(field);
    }
    return builder;
  }
}
