import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

// ─── Sheet Types ───────────────────────────────────────────────────────────────
// 1. Standard          — fixed height
// 2. Scrollable        — DraggableScrollableSheet, full expansion
// 3. Draggable         — snap points (min/initial/max)
// 4. FullScreen        — covers entire screen
// 5. Dialog Sheet      — modal with title + actions (like BottomSheetDialog)
// 6. Action Sheet      — iOS-style action list

class AppSheet {
  AppSheet._();

  // ── 1. Standard ───────────────────────────────────────────────────────────
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool showDragHandle = true,
    bool isDismissible = true,
    bool isScrollControlled = false,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    double? height,
    bool enableBlur = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled || height != null,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => _ModernSheetContainer(
        enableBlur: enableBlur,
        backgroundColor: backgroundColor,
        showDragHandle: showDragHandle,
        child: _StandardSheet(
          title: title,
          padding: padding,
          height: height,
          child: child,
        ),
      ),
    );
  }

  // ── 2. Scrollable DraggableSheet ──────────────────────────────────────────
  static Future<T?> scrollable<T>(
    BuildContext context, {
    required Widget Function(BuildContext, ScrollController) builder,
    String? title,
    double minChildSize = 0.3,
    double initialChildSize = 0.5,
    double maxChildSize = 1.0,
    bool expand = false,
    bool snap = true,
    List<double>? snapSizes,
    bool showDragHandle = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: backgroundColor,
      showDragHandle: showDragHandle,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: expand,
        snap: snap,
        snapSizes: snapSizes ?? [minChildSize, initialChildSize, maxChildSize],
        builder: (ctx2, scrollCtrl) => Column(
          children: [
            if (title != null) _SheetHeader(title: title, showHandle: false),
            Expanded(child: builder(ctx2, scrollCtrl)),
          ],
        ),
      ),
    );
  }

  // ── 3. Full Screen Sheet ──────────────────────────────────────────────────
  static Future<T?> fullScreen<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: backgroundColor,
      builder: (ctx) => _FullScreenSheet(
        title: title,
        actions: actions,
        leading: leading,
        child: child,
      ),
    );
  }

  // ── 4. Dialog Sheet ───────────────────────────────────────────────────────
  static Future<T?> dialog<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget>? actions,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    bool showDragHandle = true,
    Color? backgroundColor,
    bool enableBlur = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => _ModernSheetContainer(
        enableBlur: enableBlur,
        backgroundColor: backgroundColor,
        showDragHandle: showDragHandle,
        child: _DialogSheet(
          title: title,
          actions: actions,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onConfirm: onConfirm,
          child: child,
        ),
      ),
    );
  }

  // ── 5. Action Sheet (iOS-style) ───────────────────────────────────────────
  static Future<T?> actions<T>(
    BuildContext context, {
    String? title,
    String? message,
    required List<AppSheetAction<T>> actions,
    AppSheetAction<T>? cancelAction,
    Color? backgroundColor,
    bool enableBlur = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => _ModernSheetContainer(
        enableBlur: enableBlur,
        backgroundColor: backgroundColor,
        showDragHandle: false,
        child: _ActionSheet<T>(
          title: title,
          message: message,
          actions: actions,
          cancelAction: cancelAction,
        ),
      ),
    );
  }

  // ── 6. Confirm Sheet ──────────────────────────────────────────────────────
  static Future<bool?> confirm(
    BuildContext context, {
    String title = 'Confirm Action',
    String message = 'Are you sure you want to proceed?',
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    Widget? icon,
    Color? backgroundColor,
    bool enableBlur = true,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => _ModernSheetContainer(
        enableBlur: enableBlur,
        backgroundColor: backgroundColor,
        showDragHandle: true,
        child: _ConfirmSheet(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDestructive: isDestructive,
          icon: icon,
        ),
      ),
    );
  }

  static void dismiss<T>(BuildContext context, {T? result}) =>
      Navigator.of(context).pop(result);
}

// ─── Action Model ──────────────────────────────────────────────────────────────
class AppSheetAction<T> {
  final String label;
  final IconData? icon;
  final T? value;
  final bool isDestructive;
  final VoidCallback? onTap;

  const AppSheetAction({
    required this.label,
    this.icon,
    this.value,
    this.isDestructive = false,
    this.onTap,
  });
}

// ─── Modern Sheet Container ──────────────────────────────────────────────────

class _ModernSheetContainer extends StatelessWidget {
  final Widget child;
  final bool enableBlur;
  final Color? backgroundColor;
  final bool showDragHandle;

  const _ModernSheetContainer({
    required this.child,
    this.enableBlur = true,
    this.backgroundColor,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = backgroundColor ?? cs.surface;

    Widget container = Container(
      decoration: BoxDecoration(
        color: enableBlur ? bg.withOpacity(0.9) : bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );

    if (enableBlur) {
      container = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: container,
        ),
      );
    }

    return container;
  }
}

// ─── Shared Header ─────────────────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final String title;
  final bool showHandle;
  final List<Widget>? actions;
  final Widget? leading;

  const _SheetHeader({
    required this.title,
    this.showHandle = true,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.sm, 0),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}

// ─── Standard Sheet ────────────────────────────────────────────────────────────
class _StandardSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const _StandardSheet({this.title, required this.child, this.padding, this.height});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    Widget body = SingleChildScrollView(
      padding: (padding ?? const EdgeInsets.all(AppSpacing.md)).add(
          EdgeInsets.only(bottom: bottomInset)),
      child: child,
    );
    if (height != null) {
      body = SizedBox(height: height! + bottomInset, child: body);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          _SheetHeader(title: title!),
          const Divider(height: 1),
        ],
        body,
      ],
    );
  }
}

// ─── Full Screen Sheet ─────────────────────────────────────────────────────────
class _FullScreenSheet extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget child;

  const _FullScreenSheet({this.title, this.actions, this.leading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: leading ?? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: title != null ? Text(title!) : null,
        actions: actions,
        elevation: 0,
      ),
      body: child,
    );
  }
}

// ─── Dialog Sheet ──────────────────────────────────────────────────────────────
class _DialogSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final String? confirmLabel, cancelLabel;
  final VoidCallback? onConfirm;

  const _DialogSheet({
    required this.title,
    required this.child,
    this.actions,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: title),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
            child: actions != null
                ? Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!)
                : Row(children: [
                    if (cancelLabel != null) Expanded(
                      child: AppButton.outlined(
                        label: cancelLabel!,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    if (cancelLabel != null) const SizedBox(width: AppSpacing.sm),
                    if (confirmLabel != null) Expanded(
                      child: AppButton.filled(
                        label: confirmLabel!,
                        onPressed: () {
                          onConfirm?.call();
                          Navigator.pop(context, true);
                        },
                      ),
                    ),
                  ]),
          ),
        ],
      ),
    );
  }
}

// ─── Action Sheet ──────────────────────────────────────────────────────────────
class _ActionSheet<T> extends StatelessWidget {
  final String? title, message;
  final List<AppSheetAction<T>> actions;
  final AppSheetAction<T>? cancelAction;

  const _ActionSheet({this.title, this.message, required this.actions, this.cancelAction});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || message != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  if (title != null) Text(title!, style: textTheme.titleSmall,
                      textAlign: TextAlign.center),
                  if (message != null) ...[
                    const SizedBox(height: 4),
                    Text(message!, style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          const Divider(height: 1),
          ...actions.asMap().entries.map((entry) {
            final idx = entry.key;
            final action = entry.value;
            return ListTile(
              leading: action.icon != null
                  ? Icon(action.icon, color: action.isDestructive ? colors.error : null)
                  : null,
              title: Text(action.label,
                  style: TextStyle(
                      color: action.isDestructive ? colors.error : null,
                      fontWeight: FontWeight.w500)),
              onTap: () {
                action.onTap?.call();
                Navigator.pop(context, action.value);
              },
            ).animate(delay: Duration(milliseconds: 40 * idx))
             .fadeIn(duration: 200.ms)
             .slideY(begin: 0.1, end: 0, duration: 200.ms, curve: Curves.easeOut);
          }),
          if (cancelAction != null) ...[
            const Divider(height: 8),
            ListTile(
              title: Text(cancelAction!.label, textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                cancelAction!.onTap?.call();
                Navigator.pop(context, cancelAction!.value);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Confirm Sheet ─────────────────────────────────────────────────────────────
class _ConfirmSheet extends StatelessWidget {
  final String title, message, confirmLabel, cancelLabel;
  final bool isDestructive;
  final Widget? icon;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(height: AppSpacing.md)],
          Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            Expanded(child: AppButton.outlined(
              label: cancelLabel,
              onPressed: () => Navigator.pop(context, false),
            )),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: isDestructive
                ? AppButton.destructive(
                    label: confirmLabel,
                    onPressed: () => Navigator.pop(context, true))
                : AppButton.filled(
                    label: confirmLabel,
                    onPressed: () => Navigator.pop(context, true))),
          ]),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
