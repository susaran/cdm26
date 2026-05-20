import 'package:flutter/material.dart';

enum ButtonVariant { filled, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.variant = ButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(label);

    return switch (variant) {
      ButtonVariant.filled => ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      ButtonVariant.outlined => OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
    };
  }
}
