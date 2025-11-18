import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/runtime_status_store.dart';

/// Runtime Status Widget
/// Shows current runtime status with actions
class RuntimeStatusWidget extends StatelessWidget {
  final RuntimeStatusStore store;
  final VoidCallback? onInstallRequested;
  final VoidCallback? onUpdateRequested;

  const RuntimeStatusWidget({
    super.key,
    required this.store,
    this.onInstallRequested,
    this.onUpdateRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (store.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (store.errorMessage != null) {
          return _buildError(context);
        }

        if (store.status == null) {
          return _buildUnknown(context);
        }

        return store.status!.map(
          notInstalled: (_) => _buildNotInstalled(context),
          installed: (s) => _buildInstalled(context, s),
          partiallyInstalled: (s) => _buildPartiallyInstalled(context, s),
          installing: (s) => _buildInstalling(context, s),
          failed: (s) => _buildFailed(context, s),
          updateAvailable: (s) => _buildUpdateAvailable(context, s),
        );
      },
    );
  }

  Widget _buildError(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: store.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknown(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.help_outline),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('Status unknown'),
            ),
            ElevatedButton(
              onPressed: store.refresh,
              child: const Text('Check Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotInstalled(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VS Code Runtime Not Installed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Install the runtime to use VS Code plugins',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onInstallRequested,
              icon: const Icon(Icons.download),
              label: const Text('Install'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalled(
    BuildContext context,
    _Installed status,
  ) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Runtime Installed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${status.version}',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: store.checkForUpdates,
              child: const Text('Check for Updates'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartiallyInstalled(
    BuildContext context,
    _PartiallyInstalled status,
  ) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partially Installed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${status.missingModules.length} modules missing',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onInstallRequested,
              child: const Text('Complete Installation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalling(
    BuildContext context,
    _Installing status,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Installing...'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: status.progress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailed(
    BuildContext context,
    _Failed status,
  ) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Installation Failed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.error,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onInstallRequested,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateAvailable(
    BuildContext context,
    _UpdateAvailable status,
  ) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.update, color: Colors.blue.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${status.currentVersion} → ${status.availableVersion}',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onUpdateRequested,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
