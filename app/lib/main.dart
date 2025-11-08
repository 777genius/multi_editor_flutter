import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ide_presentation/ide_presentation.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

/// Main entry point for Flutter IDE application
///
/// Architecture:
/// - Clean Architecture + DDD + SOLID + Hexagonal
/// - MobX for reactive state management
/// - GetIt + Injectable for dependency injection
/// - Provider for widget tree dependencies
///
/// Startup flow:
/// 1. Initialize Flutter bindings
/// 2. Configure dependency injection (GetIt)
/// 3. Setup system UI (status bar, orientation)
/// 4. Run app with MaterialApp
///
/// Example:
/// ```bash
/// # Development mode
/// flutter run
///
/// # Production mode
/// flutter run --release
///
/// # Web
/// flutter run -d chrome
/// ```
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependency injection
  await configureDependencies();

  // Setup system UI
  await _setupSystemUI();

  // Run app
  runApp(const FlutterIdeApp());
}

/// FlutterIdeApp
///
/// Root widget that sets up:
/// - MaterialApp configuration
/// - Theme (dark mode for code editor)
/// - Provider for stores (optional, using GetIt instead)
/// - Initial route (IdeScreen)
class FlutterIdeApp extends StatelessWidget {
  const FlutterIdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter IDE',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.dark, // Default to dark theme (better for coding)

      // Initial screen
      home: const IdeScreen(),

      // Performance optimizations
      builder: (context, child) {
        return MediaQuery(
          // Prevent font scaling (important for code editor)
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }

  /// Builds light theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF3F3F3),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF000000),
        elevation: 1,
      ),
    );
  }

  /// Builds dark theme (VS Code inspired)
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),

      // AppBar theme (VS Code dark)
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2D30),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
      ),

      // Card theme
      cardTheme: const CardTheme(
        color: Color(0xFF252526),
        elevation: 0,
      ),

      // Text theme
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 13,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Color(0xFFCCCCCC),
      ),
    );
  }
}

/// Setup system UI (status bar, orientation)
Future<void> _setupSystemUI() async {
  // Set preferred orientations (all)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style (status bar, navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Status bar (top)
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,

      // Navigation bar (bottom, Android)
      systemNavigationBarColor: Color(0xFF1E1E1E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}
