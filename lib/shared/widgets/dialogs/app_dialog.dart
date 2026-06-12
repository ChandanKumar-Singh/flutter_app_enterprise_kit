import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

// ─── Dialog Types ─────────────────────────────────────────────────────────────
// 1. Basic    2. Confirm   3. Destructive  4. Input     5. Loading
// 6. Success  7. Error     8. Warning      9. Info     10. Custom
// 11. Full Screen  12. Bottom Sheet Dialog

class AppDialog {
  AppDialog._();

  // ── 1. Basic Info Dialog ──────────────────────────────────────────────────
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String closeLabel = 'OK',
    Widget? icon,
  }) => showDialog(
    context: context,
    builder: (_) => _BasicDialog(title: title, message: message,
        closeLabel: closeLabel, icon: icon),
  );

  // ── 2. Confirm Dialog ─────────────────────────────────────────────────────
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Widget? icon,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(title: title, message: message,
        confirmLabel: confirmLabel, cancelLabel: cancelLabel, icon: icon),
  );

  // ── 3. Destructive Confirm ────────────────────────────────────────────────
  static Future<bool?> danger(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) => showDialog<bool>(
    context: context,
    builder: (_) => _DangerDialog(title: title, message: message,
        confirmLabel: confirmLabel, cancelLabel: cancelLabel),
  );

  // ── 4. Input Dialog ───────────────────────────────────────────────────────
  static Future<String?> input(
    BuildContext context, {
    required String title,
    String? hint,
    String? initialValue,
    String? label,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) => showDialog<String>(
    context: context,
    builder: (_) => _InputDialog(
      title: title, hint: hint, initialValue: initialValue,
      label: label, keyboardType: keyboardType, maxLines: maxLines,
      validator: validator,
    ),
  );

  // ── 5. Loading Dialog ─────────────────────────────────────────────────────
  static Future<T?> loading<T>(
    BuildContext context, {
    String message = 'Loading...',
    Future<T>? future,
  }) {
    if (future != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _LoadingDialog(message: message),
      );
      return future.whenComplete(() {
        if (context.mounted) Navigator.of(context).pop();
      }).then((v) => v).catchError((_) => null);
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingDialog(message: message),
    );
  }

  // ── 6. Success ────────────────────────────────────────────────────────────
  static Future<void> success(
    BuildContext context, {
    required String title,
    String? message,
    String closeLabel = 'Great!',
  }) => showDialog(
    context: context,
    builder: (_) => _StatusDialog(
      title: title, message: message, closeLabel: closeLabel,
      color: Colors.green, icon: Icons.check_circle_outline,
    ),
  );

  // ── 7. Error ──────────────────────────────────────────────────────────────
  static Future<void> error(
    BuildContext context, {
    required String title,
    String? message,
    String? details,
    String closeLabel = 'OK',
    VoidCallback? onRetry,
  }) => showDialog(
    context: context,
    builder: (_) => _ErrorDialog(title: title, message: message,
        details: details, closeLabel: closeLabel, onRetry: onRetry),
  );

  // ── 8. Warning ────────────────────────────────────────────────────────────
  static Future<void> warning(
    BuildContext context, {
    required String title,
    String? message,
    String closeLabel = 'Understood',
  }) => showDialog(
    context: context,
    builder: (_) => _StatusDialog(
      title: title, message: message, closeLabel: closeLabel,
      color: Colors.orange, icon: Icons.warning_amber_outlined,
    ),
  );

  // ── 9. Custom Widget ──────────────────────────────────────────────────────
  static Future<T?> custom<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
    EdgeInsets? insetPadding,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => Dialog(
      insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: child,
    ),
  );

  // ── 10. Full Screen Dialog ────────────────────────────────────────────────
  static Future<T?> fullScreen<T>(
    BuildContext context, {
    required Widget child,
    Color? barrierColor,
  }) => showDialog<T>(
    context: context,
    barrierColor: barrierColor ?? Colors.black87,
    builder: (_) => Dialog.fullscreen(child: child),
  );

  // ── Static helpers ────────────────────────────────────────────────────────
  static void dismiss(BuildContext context, {dynamic result}) =>
      Navigator.of(context).pop(result);
}

// ─── Dialog Implementations ────────────────────────────────────────────────────

class _BasicDialog extends StatelessWidget {
  final String title;
  final String message;
  final String closeLabel;
  final Widget? icon;

  const _BasicDialog({required this.title, required this.message,
      required this.closeLabel, this.icon});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: icon,
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton.text(label: closeLabel, onPressed: () => Navigator.pop(context), isFullWidth: false),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel, cancelLabel;
  final Widget? icon;
  const _ConfirmDialog({required this.title, required this.message,
      required this.confirmLabel, required this.cancelLabel, this.icon});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: icon,
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton.text(label: cancelLabel, onPressed: () => Navigator.pop(context, false), isFullWidth: false),
        AppButton.filled(label: confirmLabel, onPressed: () => Navigator.pop(context, true),
            size: AppButtonSize.sm, isFullWidth: false),
      ],
    );
  }
}

class _DangerDialog extends StatelessWidget {
  final String title, message, confirmLabel, cancelLabel;
  const _DangerDialog({required this.title, required this.message,
      required this.confirmLabel, required this.cancelLabel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 32),
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton.text(label: cancelLabel, onPressed: () => Navigator.pop(context, false), isFullWidth: false),
        AppButton.destructive(label: confirmLabel, onPressed: () => Navigator.pop(context, true),
            size: AppButtonSize.sm, isFullWidth: false),
      ],
    );
  }
}

class _InputDialog extends StatefulWidget {
  final String title;
  final String? hint, initialValue, label;
  final TextInputType keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const _InputDialog({required this.title, this.hint, this.initialValue,
      this.label, required this.keyboardType, this.maxLines, this.validator});

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final _ctrl = TextEditingController(text: widget.initialValue);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _ctrl,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          validator: widget.validator,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
          ),
        ),
      ),
      actions: [
        AppButton.text(label: 'Cancel', onPressed: () => Navigator.pop(context), isFullWidth: false),
        AppButton.filled(label: 'OK', size: AppButtonSize.sm, isFullWidth: false,
          onPressed: () {
            if (_key.currentState?.validate() ?? true) {
              Navigator.pop(context, _ctrl.text);
            }
          },
        ),
      ],
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  final String message;
  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _StatusDialog extends StatelessWidget {
  final String title, closeLabel;
  final String? message;
  final Color color;
  final IconData icon;

  const _StatusDialog({required this.title, this.message,
      required this.closeLabel, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon, color: color, size: 48),
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: [
        AppButton.filled(
          label: closeLabel,
          onPressed: () => Navigator.pop(context),
          size: AppButtonSize.sm,
          isFullWidth: false,
          backgroundColor: color,
        ),
      ],
    );
  }
}

class _ErrorDialog extends StatefulWidget {
  final String title, closeLabel;
  final String? message, details;
  final VoidCallback? onRetry;

  const _ErrorDialog({required this.title, this.message, this.details,
      required this.closeLabel, this.onRetry});

  @override
  State<_ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<_ErrorDialog> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.error_outline, color: colors.error, size: 48),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) Text(widget.message!),
          if (widget.details != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showDetails = !_showDetails),
              child: Row(
                children: [
                  Text('Technical details',
                      style: TextStyle(color: colors.primary, fontSize: 13)),
                  Icon(_showDetails ? Icons.expand_less : Icons.expand_more,
                      size: 16, color: colors.primary),
                ],
              ),
            ),
            if (_showDetails)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.details!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
          ],
        ],
      ),
      actions: [
        if (widget.onRetry != null)
          AppButton.tonal(label: 'Retry', onPressed: widget.onRetry,
              size: AppButtonSize.sm, isFullWidth: false),
        AppButton.text(label: widget.closeLabel,
            onPressed: () => Navigator.pop(context), isFullWidth: false),
      ],
    );
  }
}
