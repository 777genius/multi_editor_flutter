import 'package:flutter/material.dart';

class HeaderActions extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSettings;
  final VoidCallback onShowAbout;

  const HeaderActions({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onShowSettings,
    required this.onShowAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
          ),
          tooltip: 'Toggle theme',
          onPressed: onToggleTheme,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: onShowSettings,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'About',
          onPressed: onShowAbout,
        ),
      ],
    );
  }
}
