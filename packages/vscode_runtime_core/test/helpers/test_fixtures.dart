import 'package:vscode_runtime_core/vscode_runtime_core.dart';

/// Test fixtures for domain objects
class TestFixtures {
  // Platform Identifiers
  static final windowsX64 = PlatformIdentifier.windowsX64;
  static final linuxX64 = PlatformIdentifier.linuxX64;
  static final macOSArm64 = PlatformIdentifier.macOSArm64;

  // Module IDs
  static final nodejsId = ModuleId.nodejs;
  static final vscodeServerId = ModuleId.openVSCodeServer;
  static final baseExtensionsId = ModuleId.baseExtensions;

  // Versions
  static final version1 = RuntimeVersion.fromString('1.0.0');
  static final version2 = RuntimeVersion.fromString('2.0.0');

  // Hashes
  static final validHash = SHA256Hash.fromString('a' * 64);
  static final differentHash = SHA256Hash.fromString('b' * 64);

  // URLs
  static final nodeUrl = DownloadUrl('https://nodejs.org/dist/v20.11.0/node-v20.11.0-win-x64.zip');
  static final vscodeUrl = DownloadUrl('https://github.com/gitpod-io/openvscode-server/releases/download/v1.87.0/openvscode-server-v1.87.0-win-x64.zip');

  // Sizes
  static final size30MB = ByteSize.fromMB(30);
  static final size100MB = ByteSize.fromMB(100);

  /// Create a test PlatformArtifact
  static PlatformArtifact createArtifact({
    DownloadUrl? url,
    SHA256Hash? hash,
    ByteSize? size,
  }) {
    return PlatformArtifact(
      url: url ?? nodeUrl,
      hash: hash ?? validHash,
      size: size ?? size30MB,
    );
  }

  /// Create a test RuntimeModule
  static RuntimeModule createModule({
    ModuleId? id,
    String? name,
    ModuleType? type,
    RuntimeVersion? version,
    Map<PlatformIdentifier, PlatformArtifact>? platformArtifacts,
    List<ModuleId>? dependencies,
    bool isOptional = false,
  }) {
    return RuntimeModule.create(
      id: id ?? nodejsId,
      name: name ?? 'Node.js',
      type: type ?? ModuleType.runtime,
      version: version ?? version1,
      platformArtifacts: platformArtifacts ?? {
        windowsX64: createArtifact(),
        linuxX64: createArtifact(url: DownloadUrl('https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz')),
      },
      dependencies: dependencies,
      isOptional: isOptional,
    );
  }

  /// Create a test RuntimeInstallation
  static RuntimeInstallation createInstallation({
    List<RuntimeModule>? modules,
    PlatformIdentifier? platform,
  }) {
    return RuntimeInstallation.create(
      modules: modules ?? [createModule()],
      platform: platform ?? windowsX64,
    );
  }

  /// Create a module with dependencies
  static RuntimeModule createModuleWithDependencies({
    required ModuleId id,
    required List<ModuleId> dependencies,
  }) {
    return createModule(
      id: id,
      name: id.value,
      dependencies: dependencies,
    );
  }

  /// Create a circular dependency scenario
  static List<RuntimeModule> createCircularDependency() {
    // A depends on B, B depends on C, C depends on A (circular!)
    final moduleA = createModuleWithDependencies(
      id: ModuleId.fromString('module-a'),
      dependencies: [ModuleId.fromString('module-b')],
    );

    final moduleB = createModuleWithDependencies(
      id: ModuleId.fromString('module-b'),
      dependencies: [ModuleId.fromString('module-c')],
    );

    final moduleC = createModuleWithDependencies(
      id: ModuleId.fromString('module-c'),
      dependencies: [ModuleId.fromString('module-a')], // Circular!
    );

    return [moduleA, moduleB, moduleC];
  }

  /// Create a valid dependency chain
  static List<RuntimeModule> createValidDependencyChain() {
    // A depends on B, B depends on C, C has no dependencies
    final moduleC = createModuleWithDependencies(
      id: ModuleId.fromString('module-c'),
      dependencies: [],
    );

    final moduleB = createModuleWithDependencies(
      id: ModuleId.fromString('module-b'),
      dependencies: [ModuleId.fromString('module-c')],
    );

    final moduleA = createModuleWithDependencies(
      id: ModuleId.fromString('module-a'),
      dependencies: [ModuleId.fromString('module-b')],
    );

    return [moduleA, moduleB, moduleC];
  }

  /// Create modules with multiple platforms
  static RuntimeModule createMultiPlatformModule() {
    return createModule(
      platformArtifacts: {
        windowsX64: createArtifact(url: DownloadUrl('https://example.com/win-x64.zip')),
        linuxX64: createArtifact(url: DownloadUrl('https://example.com/linux-x64.tar.xz')),
        macOSArm64: createArtifact(url: DownloadUrl('https://example.com/macos-arm64.tar.gz')),
      },
    );
  }

  /// Create an installation with multiple modules
  static RuntimeInstallation createMultiModuleInstallation() {
    final nodejs = createModule(
      id: nodejsId,
      name: 'Node.js',
    );

    final vscode = createModule(
      id: vscodeServerId,
      name: 'OpenVSCode Server',
      dependencies: [nodejsId],
    );

    final extensions = createModule(
      id: baseExtensionsId,
      name: 'Base Extensions',
      dependencies: [vscodeServerId],
      isOptional: true,
    );

    return RuntimeInstallation.create(
      modules: [nodejs, vscode, extensions],
      platform: windowsX64,
    );
  }
}
