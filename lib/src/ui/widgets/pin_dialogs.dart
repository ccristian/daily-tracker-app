import 'package:flutter/material.dart';

Future<String?> showPinInputDialog({
  required BuildContext context,
  required String title,
  required String actionLabel,
  String? helper,
}) {
  final controller = TextEditingController();
  String? error;

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (helper != null) ...[
                  Text(helper),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: '4-digit PIN',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final pin = controller.text.trim();
                  if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                    setState(() => error = 'Enter exactly 4 digits');
                    return;
                  }
                  Navigator.of(context).pop(pin);
                },
                child: Text(actionLabel),
              ),
            ],
          );
        },
      );
    },
  );
}

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    required this.onUnlock,
    required this.onVerifyPin,
  });

  final Future<bool> Function(String pin) onVerifyPin;
  final VoidCallback onUnlock;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'Enter exactly 4 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await widget.onVerifyPin(pin);

    if (!mounted) {
      return;
    }

    if (ok) {
      widget.onUnlock();
    } else {
      setState(() {
        _loading = false;
        _error = 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Unlock App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: '4-digit PIN',
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
