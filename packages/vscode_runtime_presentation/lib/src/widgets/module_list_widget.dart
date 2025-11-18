import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';
import '../stores/module_list_store.dart';

/// Module List Widget
/// Displays selectable list of modules
class ModuleListWidget extends StatelessWidget {
  final ModuleListStore store;

  const ModuleListWidget({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Column(
          children: [
            // Filters
            _buildFilters(context),

            const SizedBox(height: 16),

            // Module list
            Expanded(
              child: _buildModuleList(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      children: [
        // Select all critical
        ElevatedButton.icon(
          onPressed: store.selectAllCritical,
          icon: const Icon(Icons.check_box, size: 20),
          label: const Text('Select All Critical'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),

        const SizedBox(width: 8),

        // Clear selection
        TextButton.icon(
          onPressed: store.clearSelection,
          icon: const Icon(Icons.clear, size: 20),
          label: const Text('Clear'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),

        const Spacer(),

        // Show optional toggle
        Observer(
          builder: (_) => FilterChip(
            label: const Text('Show Optional'),
            selected: store.showOptional,
            onSelected: (_) => store.toggleShowOptional(),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleList(BuildContext context) {
    final modules = store.modules;

    if (modules.isEmpty) {
      return const Center(
        child: Text('No modules available'),
      );
    }

    return ListView.builder(
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleItem(context, module);
      },
    );
  }

  Widget _buildModuleItem(BuildContext context, ModuleInfoDto module) {
    return Observer(
      builder: (_) {
        final isSelected = store.selectedModules.contains(module.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: module.isInstalled
                ? null
                : (_) => store.toggleModule(module.id),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    module.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (module.isInstalled) ...[
                  const Chip(
                    label: Text('Installed'),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(module.description),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Type
                    Chip(
                      label: Text(module.typeDisplayName),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),

                    // Optional badge
                    if (module.isOptional)
                      const Chip(
                        label: Text('Optional'),
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),

                    // Size
                    if (module.sizeForCurrentPlatform != null)
                      Chip(
                        label: Text(
                          module.sizeForCurrentPlatform!.toHumanReadable(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),

                    // Dependencies
                    if (module.hasDependencies)
                      Chip(
                        label: Text('${module.dependencies.length} deps'),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
