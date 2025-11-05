import 'package:flutter/material.dart';
import 'header_actions.dart';

class AppHeader extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSettings;
  final VoidCallback onShowAbout;

  const AppHeader({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onShowSettings,
    required this.onShowAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.code,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Multi-File Code Editor',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          HeaderActions(
            themeMode: themeMode,
            onToggleTheme: onToggleTheme,
            onShowSettings: onShowSettings,
            onShowAbout: onShowAbout,
          ),
        ],
      ),
    );
  }
}
