import 'package:flutter/material.dart';
import '../commands/npm_commands.dart';

/// UI panel for executing npm/yarn/pnpm commands.
///
/// Provides a simple interface for common package manager operations:
/// - install
/// - add/remove packages
/// - update
/// - outdated
/// - run scripts
///
/// Auto-detects package manager (npm/yarn/pnpm) from lock files.
class NpmCommandsPanel extends StatefulWidget {
  final String projectRoot;

  const NpmCommandsPanel({
    super.key,
    required this.projectRoot,
  });

  @override
  State<NpmCommandsPanel> createState() => _NpmCommandsPanelState();
}

class _NpmCommandsPanelState extends State<NpmCommandsPanel> {
  late NpmCommands _npmCommands;
  PackageManager _selectedPackageManager = PackageManager.npm;
  List<String> _availableScripts = [];
  String? _selectedScript;
  String _output = '';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _npmCommands = NpmCommands(
      projectRoot: widget.projectRoot,
      packageManager: _selectedPackageManager,
    );
    _autoDetectPackageManager();
    _loadAvailableScripts();
  }

  Future<void> _autoDetectPackageManager() async {
    final detected = await _npmCommands.detectPackageManager();
    if (mounted) {
      setState(() {
        _selectedPackageManager = detected;
        _npmCommands.setPackageManager(detected);
      });
    }
  }

  Future<void> _loadAvailableScripts() async {
    final result = await _npmCommands.getAvailableScripts();
    result.fold(
      (_) {}, // Ignore error
      (scripts) {
        if (mounted) {
          setState(() {
            _availableScripts = scripts;
            if (scripts.isNotEmpty) {
              _selectedScript = scripts.first;
            }
          });
        }
      },
    );
  }

  Future<void> _executeCommand(
    Future<Either<String, String>> Function() command,
    String commandName,
  ) async {
    if (mounted) {
      setState(() {
        _isRunning = true;
        _output = 'Executing $commandName...\n';
      });
    }

    final result = await command();

    result.fold(
      (error) {
        if (mounted) {
          setState(() {
            _output += '\n❌ Error:\n$error';
            _isRunning = false;
          });
        }
      },
      (output) {
        if (mounted) {
          setState(() {
            _output += '\n✅ Success:\n$output';
            _isRunning = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'JavaScript/TypeScript Commands',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 16),
                DropdownButton<PackageManager>(
                  value: _selectedPackageManager,
                  items: PackageManager.values.map((pm) {
                    return DropdownMenuItem(
                      value: pm,
                      child: Text(pm.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPackageManager = value;
                        _npmCommands.setPackageManager(value);
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning
                      ? null
                      : () => _executeCommand(
                            () => _npmCommands.install(),
                            'install',
                          ),
                  icon: const Icon(Icons.download),
                  label: const Text('install'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning
                      ? null
                      : () => _executeCommand(
                            () => _npmCommands.update(),
                            'update',
                          ),
                  icon: const Icon(Icons.upgrade),
                  label: const Text('update'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning
                      ? null
                      : () => _executeCommand(
                            () => _npmCommands.outdated(),
                            'outdated',
                          ),
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('outdated'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_availableScripts.isNotEmpty) ...[
              Row(
                children: [
                  const Text('Run script: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedScript,
                    items: _availableScripts.map((script) {
                      return DropdownMenuItem(
                        value: script,
                        child: Text(script),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedScript = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isRunning || _selectedScript == null
                        ? null
                        : () => _executeCommand(
                              () => _npmCommands.runScript(
                                scriptName: _selectedScript!,
                              ),
                              'script: $_selectedScript',
                            ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (_isRunning)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _output.isEmpty ? 'Output will appear here...' : _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
