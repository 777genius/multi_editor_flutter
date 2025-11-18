import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../stores/runtime_installation_store.dart';
import '../stores/module_list_store.dart';
import 'installation_progress_widget.dart';
import 'module_list_widget.dart';

/// Runtime Installation Dialog
/// Full dialog for installing VS Code runtime
class RuntimeInstallationDialog extends StatefulWidget {
  final RuntimeInstallationStore installationStore;
  final ModuleListStore moduleListStore;
  final InstallationTrigger trigger;

  const RuntimeInstallationDialog({
    super.key,
    required this.installationStore,
    required this.moduleListStore,
    this.trigger = InstallationTrigger.manual,
  });

  @override
  State<RuntimeInstallationDialog> createState() =>
      _RuntimeInstallationDialogState();

  /// Show dialog
  static Future<bool?> show(
    BuildContext context, {
    required RuntimeInstallationStore installationStore,
    required ModuleListStore moduleListStore,
    InstallationTrigger trigger = InstallationTrigger.manual,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RuntimeInstallationDialog(
        installationStore: installationStore,
        moduleListStore: moduleListStore,
        trigger: trigger,
      ),
    );
  }
}

class _RuntimeInstallationDialogState
    extends State<RuntimeInstallationDialog> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.moduleListStore.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Observer(
            builder: (_) {
              if (widget.installationStore.isInstalling ||
                  widget.installationStore.isCompleted) {
                return _buildInstallationProgress();
              }

              return _buildModuleSelection();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModuleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.cloud_download, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Install VS Code Runtime',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select modules to install',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),

        const Divider(height: 32),

        // Module list
        Expanded(
          child: Observer(
            builder: (_) {
              if (widget.moduleListStore.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.moduleListStore.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${widget.moduleListStore.errorMessage}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: widget.moduleListStore.initialize,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return ModuleListWidget(
                store: widget.moduleListStore,
              );
            },
          ),
        ),

        const Divider(height: 32),

        // Footer with actions
        _buildFooter(),
      ],
    );
  }

  Widget _buildFooter() {
    return Observer(
      builder: (_) {
        final selectedCount = widget.moduleListStore.selectedCount;
        final totalSize = widget.moduleListStore.selectedSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Row(
              children: [
                Text(
                  '$selectedCount modules selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  'Total size: ${totalSize.toHumanReadable()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: selectedCount > 0 ? _startInstallation : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Install'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstallationProgress() {
    return Observer(
      builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.installationStore.isCompleted
                  ? 'Installation Complete'
                  : 'Installing VS Code Runtime',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 24),

            // Progress
            Expanded(
              child: InstallationProgressWidget(
                store: widget.installationStore,
              ),
            ),

            const Divider(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.installationStore.canCancel) ...[
                  TextButton(
                    onPressed: _cancelInstallation,
                    child: const Text('Cancel'),
                  ),
                ] else if (widget.installationStore.isCompleted) ...[
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Close'),
                  ),
                ] else if (widget.installationStore.hasFailed) ...[
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _startInstallation,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _startInstallation() async {
    final moduleIds = widget.moduleListStore.selectedModules.toList();

    await widget.installationStore.install(
      moduleIds: moduleIds,
      trigger: widget.trigger,
    );
  }

  Future<void> _cancelInstallation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Installation'),
        content: const Text(
          'Are you sure you want to cancel the installation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.installationStore.cancel(reason: 'Cancelled by user');
    }
  }

  void _reset() {
    widget.installationStore.reset();
  }
}
