import 'package:flutter/foundation.dart';

/// Security configuration for the IDE
///
/// Centralizes all security-related settings with different
/// configurations for development and production.
class SecurityConfig {
  /// Whether to use encrypted WebSocket (wss://) instead of ws://
  final bool useSecureWebSocket;

  /// Whether to enable file access sandbox
  final bool enableFileSandbox;

  /// Allowed base directories for file access
  final List<String> allowedDirectories;

  /// Whether debug logging is enabled
  final bool enableDebugLogging;

  /// WebSocket connection timeout
  final Duration connectionTimeout;

  /// Whether to validate SSL certificates (disable for development)
  final bool validateSSLCertificates;

  const SecurityConfig({
    required this.useSecureWebSocket,
    required this.enableFileSandbox,
    required this.allowedDirectories,
    required this.enableDebugLogging,
    this.connectionTimeout = const Duration(seconds: 10),
    this.validateSSLCertificates = true,
  });

  /// Development configuration - less restrictive for debugging
  factory SecurityConfig.development() {
    return const SecurityConfig(
      useSecureWebSocket: false, // ws:// for localhost
      enableFileSandbox: false, // Allow all files in development
      allowedDirectories: [], // Empty = allow all
      enableDebugLogging: true, // Enable debug prints
      validateSSLCertificates: false, // Allow self-signed certs
    );
  }

  /// Production configuration - maximum security
  factory SecurityConfig.production({
    required List<String> allowedDirectories,
  }) {
    return SecurityConfig(
      useSecureWebSocket: true, // wss:// for encryption
      enableFileSandbox: true, // Strict file access control
      allowedDirectories: allowedDirectories,
      enableDebugLogging: false, // No debug logs in production
      validateSSLCertificates: true, // Validate all certificates
    );
  }

  /// Get appropriate config based on build mode
  factory SecurityConfig.fromEnvironment({
    List<String>? productionAllowedDirs,
  }) {
    if (kReleaseMode) {
      return SecurityConfig.production(
        allowedDirectories: productionAllowedDirs ??
            [
              '/home',
              '/Users',
              'C:\\Users',
            ],
      );
    } else {
      return SecurityConfig.development();
    }
  }

  /// Get WebSocket URL with appropriate protocol
  String getWebSocketUrl({
    required String host,
    required int port,
    String path = '',
  }) {
    final protocol = useSecureWebSocket ? 'wss' : 'ws';
    return '$protocol://$host:$port$path';
  }

  /// Check if file path is allowed
  bool isPathAllowed(String filePath) {
    if (!enableFileSandbox) {
      return true; // Development mode - allow all
    }

    if (allowedDirectories.isEmpty) {
      return false; // Production with no allowed dirs - deny all
    }

    // Normalize path
    final normalizedPath = filePath.replaceAll('\\', '/');

    // Check if path starts with any allowed directory
    for (final allowedDir in allowedDirectories) {
      final normalizedAllowed = allowedDir.replaceAll('\\', '/');
      if (normalizedPath.startsWith(normalizedAllowed)) {
        return true;
      }
    }

    return false;
  }

  /// Log debug message (only in development)
  void debugLog(String message) {
    if (enableDebugLogging) {
      debugPrint('[IDE] $message');
    }
  }

  /// Log warning (always logged, but less verbose in production)
  void warnLog(String message) {
    if (enableDebugLogging) {
      debugPrint('[IDE WARNING] $message');
    } else {
      // In production, use shorter format
      print('WARN: $message');
    }
  }

  /// Log error (always logged)
  void errorLog(String message, [Object? error, StackTrace? stackTrace]) {
    if (enableDebugLogging) {
      debugPrint('[IDE ERROR] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('Stack: $stackTrace');
    } else {
      // In production, log concisely
      print('ERROR: $message');
      if (error != null) print('Cause: $error');
    }
  }
}

/// Global security configuration instance
SecurityConfig? _globalSecurityConfig;

/// Get global security configuration
SecurityConfig getSecurityConfig() {
  _globalSecurityConfig ??= SecurityConfig.fromEnvironment();
  return _globalSecurityConfig!;
}

/// Initialize security configuration
void initializeSecurityConfig({
  List<String>? productionAllowedDirs,
}) {
  _globalSecurityConfig = SecurityConfig.fromEnvironment(
    productionAllowedDirs: productionAllowedDirs,
  );
}
