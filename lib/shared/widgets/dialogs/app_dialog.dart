import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    String title = 'Information',
    String message = 'This is an information message.',
    String closeLabel = 'OK',
    Widget? icon,
  }) => showDialog(
    context: context,
    builder: (_) => _BasicDialog(
      title: title,
      message: message,
      closeLabel: closeLabel,
      icon: icon,
    ),
  );

  // ── 2. Confirm Dialog ─────────────────────────────────────────────────────
  static Future<bool?> confirm(
    BuildContext context, {
    String title = 'Confirm Action',
    String message = 'Are you sure you want to proceed?',
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Widget? icon,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
    ),
  );

  // ── 3. Destructive Confirm ────────────────────────────────────────────────
  static Future<bool?> danger(
    BuildContext context, {
    String title = 'Delete Item',
    String message = 'Are you sure you want to delete this? This action cannot be undone.',
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) => showDialog<bool>(
    context: context,
    builder: (_) => _DangerDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
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
      title: title,
      hint: hint,
      initialValue: initialValue,
      label: label,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
      }).then<T?>((v) => v).catchError((_) => null);
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
      title: title,
      message: message,
      closeLabel: closeLabel,
      color: Colors.green,
      icon: Icons.check_circle_outline,
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
    builder: (_) => _ErrorDialog(
      title: title,
      message: message,
      details: details,
      closeLabel: closeLabel,
      onRetry: onRetry,
    ),
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
      title: title,
      message: message,
      closeLabel: closeLabel,
      color: Colors.orange,
      icon: Icons.warning_amber_outlined,
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

// ─── Dialog Container Shell ──────────────────────────────────────────────────

class _DialogContainer extends StatelessWidget {
  final Widget? icon;
  final Color? iconContainerColor;
  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool isDestructive;

  const _DialogContainer({
    this.icon,
    this.iconContainerColor,
    required this.title,
    required this.content,
    required this.actions,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  color: isDestructive ? cs.error : (iconContainerColor ?? cs.primary),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: (iconContainerColor ?? cs.primary).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: icon,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DefaultTextStyle(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ) ?? const TextStyle(),
                        textAlign: TextAlign.center,
                        child: content,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: actions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final action = entry.value;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: idx == 0 ? 0 : 8,
                                right: idx == actions.length - 1 ? 0 : 8,
                              ),
                              child: action,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
     .fadeIn(duration: 220.ms, curve: Curves.easeOut)
     .scale(
       begin: const Offset(0.95, 0.95),
       end: const Offset(1.0, 1.0),
       duration: 220.ms,
       curve: Curves.easeOutBack,
     );
  }
}

// ─── Dialog Implementations ──────────────────────────────────────────────────

class _BasicDialog extends StatelessWidget {
  final String title;
  final String message;
  final String closeLabel;
  final Widget? icon;

  const _BasicDialog({
    required this.title,
    required this.message,
    required this.closeLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogContainer(
      icon: icon,
      title: title,
      content: Text(message),
      actions: [
        AppButton.filled(
          label: closeLabel,
          onPressed: () => Navigator.pop(context),
          size: AppButtonSize.md,
        ),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel, cancelLabel;
  final Widget? icon;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogContainer(
      icon: icon,
      title: title,
      content: Text(message),
      actions: [
        AppButton.outlined(
          label: cancelLabel,
          onPressed: () => Navigator.pop(context, false),
          size: AppButtonSize.md,
        ),
        AppButton.filled(
          label: confirmLabel,
          onPressed: () => Navigator.pop(context, true),
          size: AppButtonSize.md,
        ),
      ],
    );
  }
}

class _DangerDialog extends StatelessWidget {
  final String title, message, confirmLabel, cancelLabel;

  const _DangerDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return _DialogContainer(
      icon: Icon(Icons.delete_outline, color: errorColor, size: 28),
      iconContainerColor: errorColor,
      isDestructive: true,
      title: title,
      content: Text(message),
      actions: [
        AppButton.outlined(
          label: cancelLabel,
          onPressed: () => Navigator.pop(context, false),
          size: AppButtonSize.md,
        ),
        AppButton.destructive(
          label: confirmLabel,
          onPressed: () => Navigator.pop(context, true),
          size: AppButtonSize.md,
        ),
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

  const _InputDialog({
    required this.title,
    this.hint,
    this.initialValue,
    this.label,
    required this.keyboardType,
    this.maxLines,
    this.validator,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final _ctrl = TextEditingController(text: widget.initialValue);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogContainer(
      title: widget.title,
      content: Form(
        key: _key,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextFormField(
            controller: _ctrl,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            validator: widget.validator,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ),
      actions: [
        AppButton.outlined(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
          size: AppButtonSize.md,
        ),
        AppButton.filled(
          label: 'OK',
          size: AppButtonSize.md,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _StatusDialog extends StatelessWidget {
  final String title, closeLabel;
  final String? message;
  final Color color;
  final IconData icon;

  const _StatusDialog({
    required this.title,
    this.message,
    required this.closeLabel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogContainer(
      icon: Icon(icon, color: color, size: 28),
      iconContainerColor: color,
      title: title,
      content: message != null ? Text(message!) : const SizedBox.shrink(),
      actions: [
        AppButton.filled(
          label: closeLabel,
          onPressed: () => Navigator.pop(context),
          size: AppButtonSize.md,
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

  const _ErrorDialog({
    required this.title,
    this.message,
    this.details,
    required this.closeLabel,
    this.onRetry,
  });

  @override
  State<_ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<_ErrorDialog> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _DialogContainer(
      icon: Icon(Icons.error_outline, color: colors.error, size: 28),
      iconContainerColor: colors.error,
      isDestructive: true,
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null)
            Text(widget.message!, textAlign: TextAlign.center),
          if (widget.details != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showDetails = !_showDetails),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Technical details',
                      style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Icon(_showDetails ? Icons.expand_less : Icons.expand_more,
                      size: 16, color: colors.primary),
                ],
              ),
            ),
            if (_showDetails)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    widget.details!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      actions: [
        if (widget.onRetry != null)
          AppButton.tonal(
            label: 'Retry',
            onPressed: widget.onRetry,
            size: AppButtonSize.md,
          ),
        AppButton.outlined(
          label: widget.closeLabel,
          onPressed: () => Navigator.pop(context),
          size: AppButtonSize.md,
        ),
      ],
    );
  }
}
