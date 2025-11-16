import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../application/use_cases/generate_ssh_key_use_case.dart';

/// SSH Key Manager Widget
///
/// Provides UI for:
/// - Generating new SSH keys
/// - Viewing existing keys
/// - Copying public keys
/// - Deleting keys
class SshKeyManager extends ConsumerStatefulWidget {
  const SshKeyManager({super.key});

  @override
  ConsumerState<SshKeyManager> createState() => _SshKeyManagerState();
}

class _SshKeyManagerState extends ConsumerState<SshKeyManager> {
  final _useCase = GetIt.instance<GenerateSshKeyUseCase>();
  List<String> _existingKeys = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _useCase.listKeys();

    result.fold(
      (failure) {
        setState(() {
          _errorMessage = failure.userMessage;
          _isLoading = false;
        });
      },
      (keys) {
        setState(() {
          _existingKeys = keys;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _generateKey() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => const SshKeyGeneratorDialog(),
    );

    if (result != null) {
      await _loadKeys();
    }
  }

  Future<void> _copyPublicKey(String publicKeyPath) async {
    final result = await _useCase.getPublicKeyContent(
      publicKeyPath: publicKeyPath,
    );

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to copy: ${failure.userMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      (content) async {
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Public key copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteKey(String publicKeyPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SSH Key'),
        content: Text('Are you sure you want to delete this key?\n\n$publicKeyPath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _useCase.deleteKey(publicKeyPath: publicKeyPath);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete: ${failure.userMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Key deleted successfully')),
            );
            _loadKeys();
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Key Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKeys,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateKey,
        icon: const Icon(Icons.add),
        label: const Text('Generate Key'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadKeys,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_existingKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vpn_key_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No SSH Keys',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate an SSH key to connect to remote repositories',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _existingKeys.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final keyPath = _existingKeys[index];
        final keyName = keyPath.split('/').last;
        return ListTile(
          leading: const Icon(Icons.vpn_key),
          title: Text(
            keyName,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          subtitle: Text(keyPath),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyPublicKey(keyPath),
                tooltip: 'Copy public key',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _deleteKey(keyPath),
                tooltip: 'Delete key',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// SSH Key Generator Dialog
class SshKeyGeneratorDialog extends StatefulWidget {
  const SshKeyGeneratorDialog({super.key});

  @override
  State<SshKeyGeneratorDialog> createState() => _SshKeyGeneratorDialogState();
}

class _SshKeyGeneratorDialogState extends State<SshKeyGeneratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _keyNameController = TextEditingController();
  final _passphraseController = TextEditingController();

  SshKeyType _selectedKeyType = SshKeyType.ed25519;
  bool _isGenerating = false;
  bool _showPassphrase = false;
  SshKeyPair? _generatedKey;

  @override
  void dispose() {
    _emailController.dispose();
    _keyNameController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    final useCase = GetIt.instance<GenerateSshKeyUseCase>();

    final result = await useCase(
      email: _emailController.text,
      keyType: _selectedKeyType,
      keyName: _keyNameController.text.isEmpty ? null : _keyNameController.text,
      passphrase: _passphraseController.text.isEmpty ? null : _passphraseController.text,
    );

    setState(() {
      _isGenerating = false;
    });

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate key: ${failure.userMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      (keyPair) {
        setState(() {
          _generatedKey = keyPair;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedKey != null) {
      return _buildSuccessDialog();
    }

    return AlertDialog(
      title: const Text('Generate SSH Key'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Type',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<SshKeyType>(
                  segments: const [
                    ButtonSegment(
                      value: SshKeyType.ed25519,
                      label: Text('ED25519'),
                      tooltip: 'Modern, secure, recommended',
                    ),
                    ButtonSegment(
                      value: SshKeyType.rsa,
                      label: Text('RSA'),
                      tooltip: 'Traditional, widely compatible',
                    ),
                    ButtonSegment(
                      value: SshKeyType.ecdsa,
                      label: Text('ECDSA'),
                      tooltip: 'Elliptic curve, good balance',
                    ),
                  ],
                  selected: {_selectedKeyType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedKeyType = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'your@email.com',
                    helperText: 'Used as key comment',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _keyNameController,
                  decoration: InputDecoration(
                    labelText: 'Key Name (optional)',
                    hintText: 'id_${_selectedKeyType.value}_flutter_ide',
                    helperText: 'Leave empty for default name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passphraseController,
                  obscureText: !_showPassphrase,
                  decoration: InputDecoration(
                    labelText: 'Passphrase (optional)',
                    hintText: 'Leave empty for no passphrase',
                    helperText: 'Adds extra security',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassphrase
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassphrase = !_showPassphrase;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ED25519 is recommended for new keys. It\'s more secure and faster than RSA.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isGenerating ? null : _generate,
          icon: _isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.vpn_key),
          label: Text(_isGenerating ? 'Generating...' : 'Generate'),
        ),
      ],
    );
  }

  Widget _buildSuccessDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Key Generated Successfully'),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.key,
              label: 'Key Type',
              value: _generatedKey!.keyType.value.toUpperCase(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.fingerprint,
              label: 'Fingerprint',
              value: _generatedKey!.fingerprint,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.folder,
              label: 'Private Key',
              value: _generatedKey!.privateKeyPath,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.folder_open,
              label: 'Public Key',
              value: _generatedKey!.publicKeyPath,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Public Key',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _generatedKey!.publicKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _generatedKey!.publicKey),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Public key copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: 'Copy public key',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add this public key to your Git hosting service (GitHub, GitLab, etc.) to enable SSH authentication.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, {'generated': true}),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
