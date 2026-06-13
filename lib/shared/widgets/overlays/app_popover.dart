// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── AppPopoverPosition ───────────────────────────────────────────────────────
enum AppPopoverPosition { top, bottom, left, right, auto }

// ─── AppPopover ───────────────────────────────────────────────────────────────
/// Anchor-positioned floating card using CompositedTransformFollower.
///
/// - Auto-flips when insufficient screen space in preferred direction
/// - Scale + fade spring animation
/// - Tap-outside dismiss with scrim
/// - Optional arrow tip pointing at anchor
///
/// Usage:
/// ```dart
/// AppPopoverAnchor(
///   popover: Text('Hello!'),
///   child: IconButton(icon: Icon(Iconsax.info_circle), onPressed: null),
/// )
/// ```
class AppPopoverAnchor extends StatefulWidget {
  final Widget child;
  final Widget popover;
  final AppPopoverPosition position;
  final double maxWidth;
  final double? popoverPadding;
  final bool showArrow;
  final Color? popoverColor;

  const AppPopoverAnchor({
    super.key,
    required this.child,
    required this.popover,
    this.position = AppPopoverPosition.auto,
    this.maxWidth = 280,
    this.popoverPadding,
    this.showArrow = true,
    this.popoverColor,
  });

  @override
  State<AppPopoverAnchor> createState() => _AppPopoverAnchorState();
}

class _AppPopoverAnchorState extends State<AppPopoverAnchor> {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _show();
    }
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    setState(() => _open = false);
  }

  void _show() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final anchor = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screen = MediaQuery.sizeOf(context);

    // Auto-detect position
    AppPopoverPosition pos = widget.position;
    if (pos == AppPopoverPosition.auto) {
      // Prefer bottom; flip to top if insufficient space
      pos = anchor.dy + anchorSize.height + 220 < screen.height
          ? AppPopoverPosition.bottom
          : AppPopoverPosition.top;
    }

    setState(() => _open = true);

    _entry = OverlayEntry(
      builder: (_) => _PopoverOverlay(
        layerLink: _layerLink,
        anchorSize: anchorSize,
        position: pos,
        maxWidth: widget.maxWidth,
        showArrow: widget.showArrow,
        popoverColor: widget.popoverColor,
        padding: widget.popoverPadding ?? 14,
        onDismiss: _close,
        child: widget.popover,
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: widget.child,
      ),
    );
  }
}

// ─── Overlay ──────────────────────────────────────────────────────────────────

class _PopoverOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final Size anchorSize;
  final AppPopoverPosition position;
  final double maxWidth;
  final bool showArrow;
  final Color? popoverColor;
  final double padding;
  final VoidCallback onDismiss;
  final Widget child;

  const _PopoverOverlay({
    required this.layerLink,
    required this.anchorSize,
    required this.position,
    required this.maxWidth,
    required this.showArrow,
    required this.padding,
    required this.onDismiss,
    required this.child,
    this.popoverColor,
  });

  @override
  State<_PopoverOverlay> createState() => _PopoverOverlayState();
}

class _PopoverOverlayState extends State<_PopoverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  Offset get _offset {
    const gap = 8.0;
    return switch (widget.position) {
      AppPopoverPosition.bottom => Offset(-widget.maxWidth / 2 + widget.anchorSize.width / 2, widget.anchorSize.height + gap),
      AppPopoverPosition.top    => Offset(-widget.maxWidth / 2 + widget.anchorSize.width / 2, -(widget.anchorSize.height + 200 + gap)),
      AppPopoverPosition.left   => Offset(-(widget.maxWidth + gap), -widget.anchorSize.height / 2),
      AppPopoverPosition.right  => Offset(widget.anchorSize.width + gap, -widget.anchorSize.height / 2),
      AppPopoverPosition.auto   => Offset(-widget.maxWidth / 2 + widget.anchorSize.width / 2, widget.anchorSize.height + gap),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = widget.popoverColor ?? cs.surface;

    return Stack(
      children: [
        // Scrim
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Popover card
        CompositedTransformFollower(
          link: widget.layerLink,
          offset: _offset,
          followerAnchor: Alignment.topLeft,
          targetAnchor: Alignment.topLeft,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => FadeTransition(
              opacity: _fade,
              child: ScaleTransition(scale: _scale, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Arrow
                if (widget.showArrow && widget.position == AppPopoverPosition.bottom)
                  Padding(
                    padding: EdgeInsets.only(left: widget.maxWidth / 2 - 8),
                    child: _Arrow(color: bgColor, pointUp: true),
                  ),

                // Card
                Material(
                  color: Colors.transparent,
                  child: Container(
                    width: widget.maxWidth,
                    padding: EdgeInsets.all(widget.padding),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: widget.child,
                  ),
                ),

                // Arrow (below)
                if (widget.showArrow && widget.position == AppPopoverPosition.top)
                  Padding(
                    padding: EdgeInsets.only(left: widget.maxWidth / 2 - 8),
                    child: _Arrow(color: bgColor, pointUp: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final Color color;
  final bool pointUp;
  const _Arrow({required this.color, required this.pointUp});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 8),
      painter: _ArrowPainter(color: color, pointUp: pointUp),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointUp;
  const _ArrowPainter({required this.color, required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Popover Menu ─────────────────────────────────────────────────────────────
/// Preset: classic menu popover (like iOS context menus or WhatsApp reply menu).
class AppPopoverMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const AppPopoverMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

class AppMenuPopover extends StatelessWidget {
  final Widget child;
  final List<AppPopoverMenuItem> items;
  final AppPopoverPosition position;

  const AppMenuPopover({
    super.key,
    required this.child,
    required this.items,
    this.position = AppPopoverPosition.auto,
  });

  @override
  Widget build(BuildContext context) {
    return AppPopoverAnchor(
      position: position,
      maxWidth: 200,
      popoverPadding: 0,
      showArrow: false,
      popover: _MenuContent(items: items),
      child: child,
    );
  }
}

class _MenuContent extends StatelessWidget {
  final List<AppPopoverMenuItem> items;
  const _MenuContent({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final color = item.isDestructive ? cs.error : cs.onSurface;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 18, color: color),
                      const SizedBox(width: 10),
                      Text(item.label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(height: 1, color: cs.outlineVariant),
            ],
          );
        }).toList(),
      ),
    );
  }
}
