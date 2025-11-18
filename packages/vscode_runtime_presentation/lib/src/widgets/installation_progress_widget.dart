import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/runtime_installation_store.dart';

/// Installation Progress Widget
/// Shows detailed installation progress
class InstallationProgressWidget extends StatelessWidget {
  final RuntimeInstallationStore store;

  const InstallationProgressWidget({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status message
            Text(
              store.statusMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 24),

            // Overall progress
            _buildProgressSection(
              context,
              label: 'Overall Progress',
              progress: store.overallProgress,
              text: store.progressText,
            ),

            const SizedBox(height: 16),

            // Current module progress
            if (store.currentModule != null) ...[
              _buildProgressSection(
                context,
                label: 'Current Module: ${store.currentModule!.value}',
                progress: store.currentModuleProgress,
                text: '${(store.currentModuleProgress * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 16),
            ],

            // Module count
            Text(
              'Modules: ${store.installedModules}/${store.totalModules}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            // Error message
            if (store.hasFailed && store.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        store.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Success message
            if (store.isCompleted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Installation completed successfully!',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProgressSection(
    BuildContext context, {
    required String label,
    required double progress,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
