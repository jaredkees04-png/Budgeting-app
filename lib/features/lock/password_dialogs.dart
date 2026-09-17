import 'package:flutter/material.dart';

/// Prompts for a brand-new password (with confirmation), used both when
/// first turning app-lock on and when changing an existing password.
/// Returns the chosen password, or null if cancelled.
Future<String?> showNewPasswordDialog(
  BuildContext context, {
  String title = 'Set a password',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NewPasswordDialog(title: title),
  );
}

/// Prompts for the existing password, e.g. to confirm before turning
/// lock off or changing it. Returns what was typed, or null if
/// cancelled — the caller is responsible for verifying it's correct.
Future<String?> showEnterPasswordDialog(
  BuildContext context, {
  String title = 'Enter your password',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _EnterPasswordDialog(title: title),
  );
}

class _NewPasswordDialog extends StatefulWidget {
  final String title;

  const _NewPasswordDialog({required this.title});

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _newController.text;
    if (password.length < 4) {
      setState(() => _error = 'Use at least 4 characters');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Passwords don\'t match');
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _newController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: true,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _EnterPasswordDialog extends StatefulWidget {
  final String title;

  const _EnterPasswordDialog({required this.title});

  @override
  State<_EnterPasswordDialog> createState() => _EnterPasswordDialogState();
}

class _EnterPasswordDialogState extends State<_EnterPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isEmpty) return;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
