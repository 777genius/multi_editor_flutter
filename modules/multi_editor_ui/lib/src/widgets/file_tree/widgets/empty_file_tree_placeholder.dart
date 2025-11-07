import 'package:flutter/material.dart';

class EmptyFileTreePlaceholder extends StatelessWidget {
  final bool isHovered;

  const EmptyFileTreePlaceholder({super.key, this.isHovered = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHovered ? Icons.folder_open : Icons.folder,
              size: 64,
              color: isHovered
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isHovered ? 'Drop here to move to root' : 'No files yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isHovered
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (!isHovered) ...[
              const SizedBox(height: 8),
              Text(
                'Create your first file or folder',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
