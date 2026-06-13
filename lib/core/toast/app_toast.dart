// ignore_for_file: deprecated_member_use
// ─── AppToast ─────────────────────────────────────────────────────────────────
// Premium toast notification system.
//
// Design:
//   • Colored left-accent strip per type (success/error/warning/info/loading)
//   • White card (light) / dark-slate card (dark)
//   • Gradient progress bar contained inside the card — properly clipped
//   • Spring slide-up entrance, fade-out exit
//   • Swipe to dismiss
//   • Stacked: max 3 visible, newest on top
//
// Usage:
//   AppToastController.instance.success('Saved successfully');
//   AppToastController.instance.error('Upload failed', title: 'Error');
//   AppToastController.instance.info('Route: /services/files', title: 'Node');
//   AppToastController.instance.loading('Uploading...');
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Toast types & positions ───────────────────────────────────────────────────

enum AppToastType     { success, error, warning, info, loading, custom }
enum AppToastPosition { top, bottom, center }

// ── Toast entry ───────────────────────────────────────────────────────────────

class AppToastEntry {
  final String id;
  final String? title;
  final String message;
  final AppToastType type;
  final AppToastPosition position;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;
  final bool persistent;
  final bool showProgress;
  final VoidCallback? onDismiss;
  final bool canDismiss;

  AppToastEntry({
    required this.id,
    this.title,
    required this.message,
    this.type = AppToastType.info,
    this.position = AppToastPosition.bottom,
    this.duration = const Duration(seconds: 3),
    this.actionLabel,
    this.onAction,
    this.leading,
    this.persistent = false,
    this.showProgress = true,
    this.onDismiss,
    this.canDismiss = true,
  });
}

// ── Controller ────────────────────────────────────────────────────────────────

class AppToastController {
  static final AppToastController _instance = AppToastController._();
  static AppToastController get instance => _instance;
  AppToastController._();

  final _showStream    = StreamController<AppToastEntry>.broadcast();
  final _dismissStream = StreamController<String>.broadcast();

  Stream<AppToastEntry> get onToast   => _showStream.stream;
  Stream<String>        get onDismiss => _dismissStream.stream;

  int _counter = 0;
  String _nextId() => 'toast_${++_counter}';

  // ── Public API ───────────────────────────────────────────────────────────

  String show({
    String? title,
    required String message,
    AppToastType type = AppToastType.info,
    AppToastPosition position = AppToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    Widget? leading,
    bool persistent = false,
    bool showProgress = true,
    VoidCallback? onDismiss,
    bool canDismiss = true,
  }) {
    final entry = AppToastEntry(
      id: _nextId(),
      title: title,
      message: message,
      type: type,
      position: position,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      leading: leading,
      persistent: persistent,
      showProgress: showProgress,
      onDismiss: onDismiss,
      canDismiss: canDismiss,
    );
    _showStream.add(entry);
    return entry.id;
  }

  String success(String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    AppToastPosition position = AppToastPosition.bottom,
  }) => show(
    message: message, title: title, type: AppToastType.success,
    actionLabel: actionLabel, onAction: onAction, position: position,
  );

  String error(String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    bool persistent = false,
    AppToastPosition position = AppToastPosition.bottom,
  }) => show(
    message: message, title: title, type: AppToastType.error,
    actionLabel: actionLabel, onAction: onAction,
    persistent: persistent, duration: const Duration(seconds: 5),
    position: position,
  );

  String warning(String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    AppToastPosition position = AppToastPosition.bottom,
  }) => show(
    message: message, title: title, type: AppToastType.warning,
    actionLabel: actionLabel, onAction: onAction,
    duration: const Duration(seconds: 4), position: position,
  );

  String info(String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    AppToastPosition position = AppToastPosition.bottom,
  }) => show(
    message: message, title: title, type: AppToastType.info,
    actionLabel: actionLabel, onAction: onAction, position: position,
  );

  String loading(String message, {String? title}) => show(
    message: message, title: title, type: AppToastType.loading,
    persistent: true, canDismiss: false,
  );

  void dismiss(String id) => _dismissStream.add(id);

  void dispose() {
    _showStream.close();
    _dismissStream.close();
  }
}

// ── Overlay host ──────────────────────────────────────────────────────────────

class AppToastOverlay extends StatefulWidget {
  final Widget child;
  final int maxVisible;

  const AppToastOverlay({
    super.key,
    required this.child,
    this.maxVisible = 3,
  });

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay> {
  final _top    = <AppToastEntry>[];
  final _bottom = <AppToastEntry>[];
  final _center = <AppToastEntry>[];

  late final StreamSubscription<AppToastEntry> _showSub;
  late final StreamSubscription<String>        _dismissSub;

  @override
  void initState() {
    super.initState();
    _showSub    = AppToastController.instance.onToast.listen(_add);
    _dismissSub = AppToastController.instance.onDismiss.listen(_remove);
  }

  void _add(AppToastEntry e) {
    setState(() {
      final list = switch (e.position) {
        AppToastPosition.top    => _top,
        AppToastPosition.bottom => _bottom,
        AppToastPosition.center => _center,
      };
      list.insert(0, e);
      if (list.length > widget.maxVisible) list.removeLast();
    });
  }

  void _remove(String id) {
    setState(() {
      for (final l in [_top, _bottom, _center]) {
        l.removeWhere((e) => e.id == id);
      }
    });
  }

  @override
  void dispose() {
    _showSub.cancel();
    _dismissSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Stack(
      children: [
        widget.child,

        // Top
        if (_top.isNotEmpty)
          Positioned(
            top: mq.padding.top + 12,
            left: 16,
            right: 16,
            child: _ToastColumn(
              toasts: _top,
              onRemove: _remove,
              slideFromTop: true,
            ),
          ),

        // Center
        if (_center.isNotEmpty)
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _center.map((e) => Padding(
                key: ValueKey(e.id),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: _ToastCard(
                  entry: e,
                  onDismiss: () => _remove(e.id),
                ),
              )).toList(),
            ),
          ),

        // Bottom
        if (_bottom.isNotEmpty)
          Positioned(
            bottom: mq.padding.bottom + 80,
            left: 16,
            right: 16,
            child: _ToastColumn(
              toasts: _bottom,
              onRemove: _remove,
              slideFromTop: false,
            ),
          ),
      ],
    );
  }
}

// ── Toast column (stack of cards) ─────────────────────────────────────────────

class _ToastColumn extends StatelessWidget {
  final List<AppToastEntry> toasts;
  final void Function(String) onRemove;
  final bool slideFromTop;

  const _ToastColumn({
    required this.toasts,
    required this.onRemove,
    required this.slideFromTop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: toasts.map((e) => Padding(
        key: ValueKey(e.id),
        padding: const EdgeInsets.only(bottom: 8),
        child: _ToastCard(
          entry: e,
          onDismiss: () => onRemove(e.id),
          slideFromTop: slideFromTop,
        ),
      )).toList(),
    );
  }
}

// ── Toast card ────────────────────────────────────────────────────────────────

class _ToastCard extends StatefulWidget {
  final AppToastEntry entry;
  final VoidCallback  onDismiss;
  final bool          slideFromTop;

  const _ToastCard({
    required this.entry,
    required this.onDismiss,
    this.slideFromTop = false,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  double _progress = 1.0;
  bool   _dismissed = false;
  bool   _exiting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.entry.persistent) _startTimer();
  }

  void _startTimer() {
    final total = widget.entry.duration.inMilliseconds;
    const tick  = 50;
    _timer = Timer.periodic(const Duration(milliseconds: tick), (_) {
      if (!mounted) return;
      setState(() => _progress -= tick / total);
      if (_progress <= 0) _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    widget.entry.onDismiss?.call();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg    = _configFor(widget.entry.type);

    // Card colours
    final cardBg     = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);

    return Dismissible(
      key: Key(widget.entry.id),
      direction: widget.entry.canDismiss
          ? DismissDirection.horizontal
          : DismissDirection.none,
      onDismissed: (_) => _dismiss(),
      child: ClipRRect(                           // ← THE FIX: clip ALL children
        borderRadius: BorderRadius.circular(14),  //   incl. progress bar corners
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Accent strip (left border) ─────────────────────────────
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cfg.accentColor,
                        cfg.accentColor.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Main row: icon + text + close
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            _ToastIcon(
                              cfg: cfg,
                              isLoading: widget.entry.type == AppToastType.loading,
                              custom: widget.entry.leading,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),

                            // Title + message + action
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.entry.title != null) ...[
                                    Text(
                                      widget.entry.title!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    widget.entry.message,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569),
                                      height: 1.4,
                                    ),
                                  ),
                                  if (widget.entry.actionLabel != null) ...[
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        widget.entry.onAction?.call();
                                        _dismiss();
                                      },
                                      child: Text(
                                        widget.entry.actionLabel!,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: cfg.accentColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Close button
                            if (widget.entry.canDismiss)
                              GestureDetector(
                                onTap: _dismiss,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: isDark
                                        ? Colors.white30
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Progress bar — inside ClipRRect, always clipped properly
                      if (!widget.entry.persistent && widget.entry.showProgress)
                        _ProgressBar(
                          progress: _progress.clamp(0.0, 1.0),
                          color: cfg.accentColor,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .slideY(
      begin: widget.slideFromTop ? -0.4 : 0.4,
      end: 0,
      duration: 320.ms,
      curve: Curves.easeOutBack,
    )
    .fadeIn(duration: 220.ms);
  }
}

// ── Icon widget ───────────────────────────────────────────────────────────────

class _ToastIcon extends StatelessWidget {
  final _ToastCfg cfg;
  final bool isLoading;
  final Widget? custom;
  final bool isDark;

  const _ToastIcon({
    required this.cfg,
    required this.isLoading,
    required this.isDark,
    this.custom,
  });

  @override
  Widget build(BuildContext context) {
    if (custom != null) {
      return SizedBox(width: 22, height: 22, child: custom!);
    }

    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(cfg.accentColor),
        ),
      ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1.seconds);
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: cfg.accentColor.withOpacity(isDark ? 0.18 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(cfg.icon, size: 14, color: cfg.accentColor),
    )
    .animate()
    .scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1, 1),
      duration: 280.ms,
      curve: Curves.easeOutBack,
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final bool isDark;

  const _ProgressBar({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Stack(
            children: [
              // Track
              Container(
                width: constraints.maxWidth,
                height: 3,
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05),
              ),
              // Fill (gradient)
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: constraints.maxWidth * progress,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Config ────────────────────────────────────────────────────────────────────

class _ToastCfg {
  final Color   accentColor;
  final IconData icon;

  const _ToastCfg({required this.accentColor, required this.icon});
}

_ToastCfg _configFor(AppToastType type) => switch (type) {
  AppToastType.success => const _ToastCfg(
    accentColor: Color(0xFF16A34A),
    icon: Icons.check_circle_rounded,
  ),
  AppToastType.error => const _ToastCfg(
    accentColor: Color(0xFFDC2626),
    icon: Icons.error_rounded,
  ),
  AppToastType.warning => const _ToastCfg(
    accentColor: Color(0xFFD97706),
    icon: Icons.warning_rounded,
  ),
  AppToastType.loading => const _ToastCfg(
    accentColor: Color(0xFF7C3AED),
    icon: Icons.sync_rounded,
  ),
  _ => const _ToastCfg(
    accentColor: Color(0xFF0284C7),
    icon: Icons.info_rounded,
  ),
};
