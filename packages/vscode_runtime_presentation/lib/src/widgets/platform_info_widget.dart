import 'package:flutter/material.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

/// Platform Info Widget
/// Displays platform information and compatibility
class PlatformInfoWidget extends StatelessWidget {
  final PlatformInfoDto platformInfo;

  const PlatformInfoWidget({
    super.key,
    required this.platformInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            // Platform details
            _buildInfoRow(
              context,
              icon: Icons.computer,
              label: 'Platform',
              value: platformInfo.displayString,
            ),

            _buildInfoRow(
              context,
              icon: Icons.info,
              label: 'OS Version',
              value: platformInfo.osVersion,
            ),

            _buildInfoRow(
              context,
              icon: Icons.memory,
              label: 'Processors',
              value: '${platformInfo.numberOfProcessors}',
            ),

            _buildInfoRow(
              context,
              icon: Icons.storage,
              label: 'Available Space',
              value: platformInfo.availableDiskSpace.toHumanReadable(),
            ),

            const Divider(height: 24),

            // Compatibility status
            _buildCompatibilityStatus(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityStatus(BuildContext context) {
    if (platformInfo.canInstallRuntime) {
      return Container(
        padding: const EdgeInsets.all(12),
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
                'Platform is supported and ready for installation',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
          ],
        ),
      );
    } else {
      final warning = platformInfo.installationWarning ?? 'Cannot install runtime';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                warning,
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      );
    }
  }
}
