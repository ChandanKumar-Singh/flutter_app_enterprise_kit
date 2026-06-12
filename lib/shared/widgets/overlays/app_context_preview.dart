// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Quick Action ─────────────────────────────────────────────────────────────

class AppQuickAction {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  final bool isDestructive;

  const AppQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isDestructive = false,
  });
}

// ─── AppContextPreview ────────────────────────────────────────────────────────
/// Instagram/Telegram-grade haptic long-press preview.
///
/// Features:
/// - Haptic medium-impact on press
/// - Backdrop blur portal overlay
/// - Scale-in spring entrance
/// - Swipe-up reveals action menu row
/// - Tap-outside or spring-dismiss
///
/// Usage:
/// ```dart
/// AppContextPreview(
///   actions: [...],
///   preview: MyPreviewWidget(),
///   child: MyListTile(),
/// )
/// ```
class AppContextPreview extends StatefulWidget {
  final Widget child;
  final Widget preview;
  final List<AppQuickAction> actions;
  final double previewHeight;
  final double previewWidth;
  final bool haptic;
  final Duration holdDuration;

  const AppContextPreview({
    super.key,
    required this.child,
    required this.preview,
    this.actions = const [],
    this.previewHeight = 280,
    this.previewWidth = double.infinity,
    this.haptic = true,
    this.holdDuration = const Duration(milliseconds: 380),
  });

  @override
  State<AppContextPreview> createState() => _AppContextPreviewState();
}

class _AppContextPreviewState extends State<AppContextPreview>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _showPreview(LongPressStartDetails details) {
    if (widget.haptic) HapticFeedback.mediumImpact();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _entry = OverlayEntry(builder: (_) {
      return _ContextPreviewOverlay(
        triggerOffset: offset,
        triggerSize: size,
        previewHeight: widget.previewHeight,
        previewWidth: widget.previewWidth,
        actions: widget.actions,
        preview: widget.preview,
        onDismiss: _removeOverlay,
      );
    });

    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _showPreview,
      onLongPressEnd: (_) {},
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _pressCtrl.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ─── Overlay ──────────────────────────────────────────────────────────────────

class _ContextPreviewOverlay extends StatefulWidget {
  final Offset triggerOffset;
  final Size triggerSize;
  final double previewHeight;
  final double previewWidth;
  final List<AppQuickAction> actions;
  final Widget preview;
  final VoidCallback onDismiss;

  const _ContextPreviewOverlay({
    required this.triggerOffset,
    required this.triggerSize,
    required this.previewHeight,
    required this.previewWidth,
    required this.actions,
    required this.preview,
    required this.onDismiss,
  });

  @override
  State<_ContextPreviewOverlay> createState() => _ContextPreviewOverlayState();
}

class _ContextPreviewOverlayState extends State<_ContextPreviewOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _showActions = false;
  double _dragY = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;

    // Position: above trigger if possible
    final double top = (widget.triggerOffset.dy - widget.previewHeight - 12)
        .clamp(48.0, screenH - widget.previewHeight - 60);

    final double width = widget.previewWidth == double.infinity
        ? screenW - 32
        : widget.previewWidth;
    final double left = ((widget.triggerOffset.dx + widget.triggerSize.width / 2) - width / 2)
        .clamp(16.0, screenW - width - 16);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(
          children: [
            // Blurred scrim
            Positioned.fill(
              child: Opacity(
                opacity: _opacity.value * 0.85,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8 * _opacity.value, sigmaY: 8 * _opacity.value),
                  child: Container(color: Colors.black.withOpacity(0.35 * _opacity.value)),
                ),
              ),
            ),

            // Preview card
            Positioned(
              top: top,
              left: left,
              width: width,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                onVerticalDragUpdate: (d) {
                  setState(() => _dragY += d.delta.dy);
                  if (_dragY < -30 && !_showActions) {
                    setState(() => _showActions = true);
                    HapticFeedback.lightImpact();
                  }
                },
                onVerticalDragEnd: (_) {
                  if (_dragY > 40) _dismiss();
                  setState(() => _dragY = 0);
                },
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        child: Container(
                          height: widget.previewHeight,
                          width: width,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: widget.preview,
                        ),
                      ),

                      // Actions menu (swipe-up to reveal)
                      if (_showActions && widget.actions.isNotEmpty)
                        _ActionsMenu(actions: widget.actions, onDismiss: _dismiss)
                            .animate()
                            .slideY(begin: -0.2, duration: 200.ms, curve: Curves.easeOutCubic)
                            .fadeIn(duration: 150.ms),

                      // Hint
                      if (!_showActions && widget.actions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Colors.white60),
                              const SizedBox(width: 4),
                              Text(
                                'Swipe up for actions',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  final List<AppQuickAction> actions;
  final VoidCallback onDismiss;

  const _ActionsMenu({required this.actions, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: actions.asMap().entries.map((e) {
              final i = e.key;
              final action = e.value;
              final color = action.isDestructive ? cs.error : action.color ?? cs.onSurface;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onDismiss();
                        action.onTap();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              action.label,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Icon(action.icon, color: color, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (i < actions.length - 1)
                    Divider(height: 1, color: cs.outlineVariant),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
