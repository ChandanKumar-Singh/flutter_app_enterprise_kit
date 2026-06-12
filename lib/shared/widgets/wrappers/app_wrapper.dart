import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── 1. SafeArea wrapper ──────────────────────────────────────────────────────
class AppSafeArea extends StatelessWidget {
  final Widget child;
  final bool top, bottom, left, right;

  const AppSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: top, bottom: bottom, left: left, right: right,
    child: child,
  );
}

// ─── 2. Padding wrapper ───────────────────────────────────────────────────────
class AppPadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? all;
  final double? horizontal, vertical, top, bottom, left, right;

  const AppPadding({
    super.key,
    required this.child,
    this.all,
    this.horizontal,
    this.vertical,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  factory AppPadding.screen({required Widget child}) => AppPadding(
    child: child, horizontal: AppSpacing.md, vertical: AppSpacing.md);

  factory AppPadding.symmetric({
    required Widget child,
    double horizontal = AppSpacing.md,
    double vertical = 0,
  }) => AppPadding(child: child, horizontal: horizontal, vertical: vertical);

  @override
  Widget build(BuildContext context) {
    final effectivePadding = all != null
        ? all!
        : EdgeInsets.fromLTRB(
            left ?? horizontal ?? 0,
            top ?? vertical ?? 0,
            right ?? horizontal ?? 0,
            bottom ?? vertical ?? 0,
          );
    return Padding(padding: effectivePadding, child: child);
  }
}

// ─── 3. Visibility wrapper ────────────────────────────────────────────────────
class AppVisible extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Widget? replacement;
  final bool maintainState;

  const AppVisible({
    super.key,
    required this.visible,
    required this.child,
    this.replacement,
    this.maintainState = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible && !maintainState) return replacement ?? const SizedBox.shrink();
    return Visibility(
      visible: visible,
      maintainState: maintainState,
      replacement: replacement ?? const SizedBox.shrink(),
      child: child,
    );
  }
}

// ─── 4. Conditional wrapper ───────────────────────────────────────────────────
class AppConditional extends StatelessWidget {
  final bool condition;
  final Widget Function(BuildContext) builder;
  final Widget Function(BuildContext)? fallbackBuilder;

  const AppConditional({
    super.key,
    required this.condition,
    required this.builder,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (condition) return builder(context);
    return fallbackBuilder?.call(context) ?? const SizedBox.shrink();
  }
}

// ─── 5. Expandable Section ────────────────────────────────────────────────────
class AppExpansionSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? leading;
  final EdgeInsetsGeometry? childPadding;
  final Color? backgroundColor;

  const AppExpansionSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.leading,
    this.childPadding,
    this.backgroundColor,
  });

  @override
  State<AppExpansionSection> createState() => _AppExpansionSectionState();
}

class _AppExpansionSectionState extends State<AppExpansionSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(widget.title),
      leading: widget.leading,
      initiallyExpanded: widget.initiallyExpanded,
      backgroundColor: widget.backgroundColor,
      onExpansionChanged: (v) => setState(() => _expanded = v),
      children: [
        Padding(
          padding: widget.childPadding ?? const EdgeInsets.all(AppSpacing.md),
          child: widget.child,
        ),
      ],
    );
  }
}

// ─── 6. Badge wrapper ─────────────────────────────────────────────────────────
class AppBadge extends StatelessWidget {
  final Widget child;
  final int? count;
  final bool showDot;
  final Color? color;
  final Alignment alignment;

  const AppBadge({
    super.key,
    required this.child,
    this.count,
    this.showDot = false,
    this.color,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    if (count == null && !showDot) return child;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft ? -4 : null,
          bottom: alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft ? -4 : null,
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? -4 : null,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? -4 : null,
          child: showDot
              ? Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: color ?? colors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 1.5),
                  ))
              : Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color ?? colors.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.surface, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      count! > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                          color: colors.onError,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── 7. Scaffold wrapper ──────────────────────────────────────────────────────
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool safeArea;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.drawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.safeArea = false,
    this.appBar,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget effectiveBody = body;
    if (safeArea) effectiveBody = SafeArea(child: body);

    return Scaffold(
      appBar: appBar ?? (title != null || titleWidget != null
          ? AppBar(
              title: titleWidget ?? Text(title!),
              leading: leading,
              actions: actions,
              elevation: 0,
            )
          : null),
      body: effectiveBody,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      drawer: drawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
