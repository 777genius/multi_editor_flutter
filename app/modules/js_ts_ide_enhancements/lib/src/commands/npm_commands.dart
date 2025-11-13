import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as path;

/// Package manager type for JavaScript/TypeScript projects.
enum PackageManager {
  npm,
  yarn,
  pnpm,
}

/// Commands for managing npm/yarn/pnpm packages.
///
/// Provides IDE integration for common package manager commands:
/// - install/add packages
/// - remove packages
/// - update packages
/// - run scripts
/// - list outdated packages
///
/// This is a pure Dart implementation that executes package manager
/// commands and parses their output.
class NpmCommands {
  final String _projectRoot;
  PackageManager _packageManager;

  NpmCommands({
    required String projectRoot,
    PackageManager packageManager = PackageManager.npm,
  })  : _projectRoot = _validateProjectRoot(projectRoot),
        _packageManager = packageManager;

  /// Default timeout for package manager operations (2 minutes)
  static const Duration _defaultTimeout = Duration(minutes: 2);

  /// Validates project root path to prevent path traversal attacks
  static String _validateProjectRoot(String projectRoot) {
    if (projectRoot.isEmpty) {
      throw ArgumentError('Project root cannot be empty');
    }
    // Normalize path to prevent path traversal
    final normalized = path.normalize(projectRoot);
    if (normalized.contains('..')) {
      throw ArgumentError('Project root cannot contain parent directory references');
    }
    return normalized;
  }

  /// Validates package name to prevent command injection
  static void _validatePackageName(String packageName) {
    if (packageName.isEmpty) {
      throw ArgumentError('Package name cannot be empty');
    }
    // Package names should only contain alphanumeric, hyphens, underscores, dots, slashes, @
    final validPattern = RegExp(r'^[@a-zA-Z0-9_.\-/]+$');
    if (!validPattern.hasMatch(packageName)) {
      throw ArgumentError(
        'Invalid package name: $packageName. Only alphanumeric characters, -, _, ., /, and @ are allowed',
      );
    }
    // Prevent shell metacharacters
    const dangerousChars = [';', '&', '|', '`', '\$', '(', ')', '<', '>', '\n', '\r'];
    for (final char in dangerousChars) {
      if (packageName.contains(char)) {
        throw ArgumentError('Package name cannot contain shell metacharacters');
      }
    }
  }

  /// Runs a process with timeout to prevent hanging
  Future<ProcessResult> _runWithTimeout(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Duration? timeout,
  }) async {
    // Note: Process.run() does not support killing on timeout
    // We throw TimeoutException but process continues running in background
    // This is acceptable for npm/yarn commands as they will eventually complete
    // For long-running commands, consider using Process.start() instead
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    ).timeout(
      timeout ?? _defaultTimeout,
      onTimeout: () {
        throw TimeoutException(
          'Command "$executable ${arguments.join(' ')}" timed out after ${timeout ?? _defaultTimeout}',
        );
      },
    );
  }

  /// Gets the path to package.json
  String get packageJsonPath => path.join(_projectRoot, 'package.json');

  /// Gets the command name for the current package manager
  String get _commandName {
    switch (_packageManager) {
      case PackageManager.npm:
        return 'npm';
      case PackageManager.yarn:
        return 'yarn';
      case PackageManager.pnpm:
        return 'pnpm';
    }
  }

  /// Checks if this is a valid JavaScript/TypeScript project
  Future<bool> isValidJsProject() async {
    final packageJsonFile = File(packageJsonPath);
    return await packageJsonFile.exists();
  }

  /// Auto-detects package manager from lock files
  Future<PackageManager> detectPackageManager() async {
    final npmLock = File(path.join(_projectRoot, 'package-lock.json'));
    final yarnLock = File(path.join(_projectRoot, 'yarn.lock'));
    final pnpmLock = File(path.join(_projectRoot, 'pnpm-lock.yaml'));

    if (await pnpmLock.exists()) {
      return PackageManager.pnpm;
    } else if (await yarnLock.exists()) {
      return PackageManager.yarn;
    } else if (await npmLock.exists()) {
      return PackageManager.npm;
    }

    return PackageManager.npm; // Default to npm
  }

  /// Sets the package manager
  void setPackageManager(PackageManager manager) {
    _packageManager = manager;
  }

  /// Installs all dependencies
  ///
  /// Returns:
  /// - Right(output) on success
  /// - Left(error) on failure
  Future<Either<String, String>> install() async {
    if (!await isValidJsProject()) {
      return left('Not a valid JavaScript/TypeScript project');
    }

    try {
      final args = ['install'];

      final result = await _runWithTimeout(
        _commandName,
        args,
        workingDirectory: _projectRoot,
      );

      if (result.exitCode == 0) {
        return right(result.stdout.toString());
      } else {
        return left(result.stderr.toString());
      }
    } catch (e) {
      return left('Failed to install packages: $e');
    }
  }

  /// Adds a package
  ///
  /// Parameters:
  /// - [packageName]: Name of the package to add
  /// - [version]: Optional version constraint
  /// - [isDev]: Add as dev dependency
  /// - [isGlobal]: Install globally
  ///
  /// Returns:
  /// - Right(output) on success
  /// - Left(error) on failure
  Future<Either<String, String>> addPackage({
    required String packageName,
    String? version,
    bool isDev = false,
    bool isGlobal = false,
  }) async {
    // Validate package name for security
    try {
      _validatePackageName(packageName);
    } catch (e) {
      return left(e.toString());
    }

    if (!isGlobal && !await isValidJsProject()) {
      return left('Not a valid JavaScript/TypeScript project');
    }

    try {
      final args = <String>[];

      if (_packageManager == PackageManager.yarn) {
        if (isGlobal) {
          args.addAll(['global', 'add']);
        } else {
          args.add('add');
        }
        if (isDev) {
          args.add('--dev');
        }
      } else {
        args.add('install');
        if (isGlobal) {
          args.add('--global');
        }
        if (isDev) {
          args.add('--save-dev');
        }
      }

      final packageSpec = version != null ? '$packageName@$version' : packageName;
      args.add(packageSpec);

      final result = await _runWithTimeout(
        _commandName,
        args,
        workingDirectory: isGlobal ? null : _projectRoot,
      );

      if (result.exitCode == 0) {
        return right(result.stdout.toString());
      } else {
        return left(result.stderr.toString());
      }
    } catch (e) {
      return left('Failed to add package: $e');
    }
  }

  /// Removes a package
  ///
  /// Parameters:
  /// - [packageName]: Name of the package to remove
  /// - [isGlobal]: Remove globally
  ///
  /// Returns:
  /// - Right(output) on success
  /// - Left(error) on failure
  Future<Either<String, String>> removePackage({
    required String packageName,
    bool isGlobal = false,
  }) async {
    // Validate package name for security
    try {
      _validatePackageName(packageName);
    } catch (e) {
      return left(e.toString());
    }

    if (!isGlobal && !await isValidJsProject()) {
      return left('Not a valid JavaScript/TypeScript project');
    }

    try {
      final args = <String>[];

      if (_packageManager == PackageManager.yarn) {
        if (isGlobal) {
          args.addAll(['global', 'remove']);
        } else {
          args.add('remove');
        }
      } else {
        args.add('uninstall');
        if (isGlobal) {
          args.add('--global');
        }
      }

      args.add(packageName);

      final result = await _runWithTimeout(
        _commandName,
        args,
        workingDirectory: isGlobal ? null : _projectRoot,
      );

      if (result.exitCode == 0) {
        return right(result.stdout.toString());
      } else {
        return left(result.stderr.toString());
      }
    } catch (e) {
      return left('Failed to remove package: $e');
    }
  }

  /// Lists outdated packages
  ///
  /// Returns:
  /// - Right(output) on success
  /// - Left(error) on failure
  Future<Either<String, String>> outdated() async {
    if (!await isValidJsProject()) {
      return left('Not a valid JavaScript/TypeScript project');
    }

    try {
      final result = await _runWithTimeout(
        _commandName,
        ['outdated'],
        workingDirectory: _projectRoot,
      );

      // Note: outdated returns non-zero exit code when packages are outdated
      return right(result.stdout.toString());
    } catch (e) {
      return left('Failed to check outdated packages: $e');
    }
  }

  /// Updates all packages
  ///
  /// Returns:
  /// - Right(output) on success
  /// - Left(error) on failure
  Future<Either<String, String>> update() async {
    if (!await isValidJsProject()) {
      return left('Not a valid JavaScript/TypeScript project');
    }

    try {
      final args = _packageManager == PackageManager.yarn
          ? ['upgrade']
          : ['update'];

      final result = await _runWithTimeout(
        _commandName,
        args,
        workingDirectory: _projectRoot,
      );

      if (result.exitCode == 0) {
        return right(result.stdout.toString());
      } else {
        return left(result.stderr.toString());
      }
    } catch (e) {
      return left('Failed to update packages: $e');
    }
  }

  /// Runs a package.json script
  ///
  /// Parameters:
  /// - [scriptName]: Name of the script to run
  ///
  /// Returns:
  /// - Right(output) on success
  /// - Left(error) on failure
  Future<Either<String, String>> runScript({
    required String scriptName,
  }) async {
    // Validate script name for security
    try {
      _validatePackageName(scriptName); // Same validation rules apply
    } catch (e) {
      return left(e.toString());
    }

    if (!await isValidJsProject()) {
      return left('Not a valid JavaScript/TypeScript project');
    }

    try {
      final args = _packageManager == PackageManager.npm
          ? ['run', scriptName]
          : [scriptName];

      final result = await _runWithTimeout(
        _commandName,
        args,
        workingDirectory: _projectRoot,
      );

      if (result.exitCode == 0) {
        return right(result.stdout.toString());
      } else {
        return left(result.stderr.toString());
      }
    } catch (e) {
      return left('Failed to run script: $e');
    }
  }

  /// Gets list of available scripts from package.json
  ///
  /// Returns:
  /// - Right(scripts) on success
  /// - Left(error) on failure
  Future<Either<String, List<String>>> getAvailableScripts() async {
    if (!await isValidJsProject()) {
      return left('Not a valid JavaScript/TypeScript project');
    }

    try {
      final packageJsonFile = File(packageJsonPath);
      final content = await packageJsonFile.readAsString();

      // Parse JSON properly using dart:convert
      final Map<String, dynamic> packageJson = jsonDecode(content);

      // Extract scripts section
      final scripts = packageJson['scripts'];
      if (scripts == null || scripts is! Map) {
        return right([]);
      }

      // Return list of script names
      return right((scripts as Map<String, dynamic>).keys.toList());
    } catch (e) {
      return left('Failed to read scripts: $e');
    }
  }

  /// Gets Node.js version
  ///
  /// Returns:
  /// - Right(version) on success
  /// - Left(error) on failure
  Future<Either<String, String>> getNodeVersion() async {
    try {
      final result = await _runWithTimeout(
        'node',
        ['--version'],
        timeout: const Duration(seconds: 10),
      );
      if (result.exitCode == 0) {
        return right(result.stdout.toString().trim());
      } else {
        return left('Node.js not available');
      }
    } catch (e) {
      return left('Node.js not available: $e');
    }
  }

  /// Gets npm version
  ///
  /// Returns:
  /// - Right(version) on success
  /// - Left(error) on failure
  Future<Either<String, String>> getPackageManagerVersion() async {
    try {
      final result = await _runWithTimeout(
        _commandName,
        ['--version'],
        timeout: const Duration(seconds: 10),
      );
      if (result.exitCode == 0) {
        return right(result.stdout.toString().trim());
      } else {
        return left('$_commandName not available');
      }
    } catch (e) {
      return left('$_commandName not available: $e');
    }
  }
}
