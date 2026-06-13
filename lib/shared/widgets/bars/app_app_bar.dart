// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── AppScrollBehavior ────────────────────────────────────────────────────────
enum AppBarScrollBehavior {
  /// Stays transparent, no change on scroll.
  transparent,

  /// Transparent → blur + glassmorphic on scroll.
  glassmorphic,

  /// Solid background from the start.
  solid,

  /// Hides on scroll down, shows on scroll up (YouTube/Instagram style).
  hideOnScrollDown,
}

// ─── AppAppBar ────────────────────────────────────────────────────────────────
/// Adaptive glassmorphic app bar.
///
/// - Transparent at top → blurs in as user scrolls down
/// - Configurable `AppBarScrollBehavior`
/// - Back button auto-visible via Navigator
/// - Status bar icon brightness adapts to scroll state
/// - Drop-in replacement for SliverAppBar in custom scroll views
/// - Also usable as a standard PreferredSizeWidget
///
/// Usage (sliver):
/// ```dart
/// CustomScrollView(slivers: [
///   AppSliverAppBar(title: 'Home', behavior: AppBarScrollBehavior.glassmorphic),
/// ])
/// ```
///
/// Usage (normal):
/// ```dart
/// AppAppBar(title: 'Page', behavior: AppBarScrollBehavior.glassmorphic)
/// ```
class AppAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final AppBarScrollBehavior behavior;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Widget? bottom;
  final double bottomHeight;
  final bool centerTitle;
  final ScrollController? scrollController;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.behavior = AppBarScrollBehavior.glassmorphic,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.bottom,
    this.bottomHeight = 0,
    this.centerTitle = false,
    this.scrollController,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + bottomHeight);

  @override
  State<AppAppBar> createState() => _AppAppBarState();
}

class _AppAppBarState extends State<AppAppBar> {
  double _scrollOffset = 0;
  bool _scrolledDown = false;
  bool _visible = true;
  double _prevOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AppAppBar old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      old.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final offset = widget.scrollController?.offset ?? 0;
    final delta = offset - _prevOffset;

    setState(() {
      _scrollOffset = offset.clamp(0.0, double.infinity);
      if (widget.behavior == AppBarScrollBehavior.hideOnScrollDown) {
        if (delta > 4 && offset > 60) {
          _visible = false;
        } else if (delta < -4) {
          _visible = true;
        }
      }
      _scrolledDown = offset > 10;
    });

    _prevOffset = offset;
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  double get _blurProgress {
    if (widget.behavior != AppBarScrollBehavior.glassmorphic) return 0;
    return (_scrollOffset / 60).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safePad = MediaQuery.paddingOf(context).top;

    final fgColor = widget.foregroundColor ?? cs.onSurface;
    final canPop = widget.automaticallyImplyLeading && Navigator.canPop(context);

    Color bg;
    switch (widget.behavior) {
      case AppBarScrollBehavior.transparent:
        bg = Colors.transparent;
      case AppBarScrollBehavior.solid:
        bg = widget.backgroundColor ?? cs.surface;
      case AppBarScrollBehavior.glassmorphic:
        bg = (widget.backgroundColor ?? cs.surface).withOpacity(_blurProgress * (isDark ? 0.8 : 0.85));
      case AppBarScrollBehavior.hideOnScrollDown:
        bg = widget.backgroundColor ?? cs.surface;
    }

    Widget bar = Container(
      height: kToolbarHeight + safePad + widget.bottomHeight,
      decoration: BoxDecoration(
        color: bg,
        border: _scrolledDown && widget.behavior != AppBarScrollBehavior.transparent
            ? Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3 * _blurProgress)))
            : null,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16 * _blurProgress,
          sigmaY: 16 * _blurProgress,
        ),
        child: Padding(
          padding: EdgeInsets.only(top: safePad),
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    // Leading
                    if (canPop)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: _GlassButton(
                          child: Icon(Iconsax.arrow_left_2, size: 18, color: fgColor),
                          onTap: () => Navigator.pop(context),
                          visible: _blurProgress > 0.3,
                        ),
                      )
                    else if (widget.leading != null)
                      widget.leading!
                    else
                      const SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: widget.behavior == AppBarScrollBehavior.glassmorphic
                            ? _blurProgress
                            : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: widget.centerTitle
                            ? Center(
                                child: _TitleText(title: widget.title, color: fgColor),
                              )
                            : Padding(
                                padding: EdgeInsets.only(left: canPop || widget.leading != null ? 4 : 16),
                                child: _TitleText(title: widget.title, color: fgColor),
                              ),
                      ),
                    ),

                    // Actions
                    if (widget.actions != null)
                      ...widget.actions!.map((a) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: a,
                          )),
                    if (widget.actions == null) const SizedBox(width: 8),
                  ],
                ),
              ),
              if (widget.bottom != null) widget.bottom!,
            ],
          ),
        ),
      ),
    );

    // Hide-on-scroll-down animation
    if (widget.behavior == AppBarScrollBehavior.hideOnScrollDown) {
      bar = AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, -1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: bar,
      );
    }

    return bar;
  }
}

class _TitleText extends StatelessWidget {
  final String title;
  final Color color;
  const _TitleText({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool visible;
  const _GlassButton({required this.child, required this.onTap, required this.visible});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: visible
            ? BoxDecoration(
                color: cs.surface.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
              )
            : null,
        child: Center(child: child),
      ),
    );
  }
}

// ─── AppSliverAppBar ──────────────────────────────────────────────────────────
/// Sliver variant — drop into CustomScrollView.
/// Handles its own scroll position via the scroll notification system.
class AppSliverAppBar extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final AppBarScrollBehavior behavior;
  final double expandedHeight;
  final Widget? flexibleContent;
  final bool pinned;
  final bool floating;
  final Color? backgroundColor;

  const AppSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.behavior = AppBarScrollBehavior.glassmorphic,
    this.expandedHeight = 160,
    this.flexibleContent,
    this.pinned = true,
    this.floating = false,
    this.backgroundColor,
  });

  @override
  State<AppSliverAppBar> createState() => _AppSliverAppBarState();
}

class _AppSliverAppBarState extends State<AppSliverAppBar> {
  double _blurSigma = 0;
  double _bgOpacity = 0;

  bool _onNotification(ScrollNotification n) {
    final offset = n.metrics.pixels;
    setState(() {
      _blurSigma = (offset / 60).clamp(0.0, 1.0) * 16;
      _bgOpacity = (offset / 60).clamp(0.0, 1.0);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: SliverAppBar(
        expandedHeight: widget.expandedHeight,
        pinned: widget.pinned,
        floating: widget.floating,
        leading: widget.leading,
        actions: widget.actions,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          background: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.flexibleContent != null) widget.flexibleContent!,
              // Blur overlay
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
                  child: Container(
                    color: (widget.backgroundColor ?? cs.surface).withOpacity(_bgOpacity * 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
