// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Toast Model ──────────────────────────────────────────────────────────────
enum AppToastType { success, error, warning, info, loading, custom }
enum AppToastPosition { top, bottom, center }

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

// ─── Toast Controller ─────────────────────────────────────────────────────────
class AppToastController {
  static final AppToastController _instance = AppToastController._();
  static AppToastController get instance => _instance;
  AppToastController._();

  final _streamController = StreamController<AppToastEntry>.broadcast();
  final _dismissController = StreamController<String>.broadcast();

  Stream<AppToastEntry> get onToast => _streamController.stream;
  Stream<String> get onDismiss => _dismissController.stream;

  int _counter = 0;

  String _nextId() => 'toast_${++_counter}';

  // ── Public API ───────────────────────────────────────────────────────────────
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
    _streamController.add(entry);
    return entry.id;
  }

  String success(String message, {String? title, String? actionLabel, VoidCallback? onAction, AppToastPosition position = AppToastPosition.bottom}) =>
      show(message: message, title: title, type: AppToastType.success, actionLabel: actionLabel, onAction: onAction, position: position);

  String error(String message, {String? title, String? actionLabel, VoidCallback? onAction, bool persistent = false, AppToastPosition position = AppToastPosition.bottom}) =>
      show(message: message, title: title, type: AppToastType.error, actionLabel: actionLabel, onAction: onAction, persistent: persistent, duration: const Duration(seconds: 5), position: position);

  String warning(String message, {String? title, String? actionLabel, VoidCallback? onAction, AppToastPosition position = AppToastPosition.bottom}) =>
      show(message: message, title: title, type: AppToastType.warning, actionLabel: actionLabel, onAction: onAction, duration: const Duration(seconds: 4), position: position);

  String info(String message, {String? title, String? actionLabel, VoidCallback? onAction, AppToastPosition position = AppToastPosition.bottom}) =>
      show(message: message, title: title, type: AppToastType.info, actionLabel: actionLabel, onAction: onAction, position: position);

  String loading(String message, {String? title}) =>
      show(message: message, title: title, type: AppToastType.loading, persistent: true, canDismiss: false);

  void dismiss(String id) => _dismissController.add(id);

  void dispose() {
    _streamController.close();
    _dismissController.close();
  }
}

// ─── Toast Overlay Widget (add to app root) ───────────────────────────────────
class AppToastOverlay extends StatefulWidget {
  final Widget child;
  final int maxVisible;

  const AppToastOverlay({super.key, required this.child, this.maxVisible = 3});

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay> {
  final _topToasts = <AppToastEntry>[];
  final _bottomToasts = <AppToastEntry>[];
  final _centerToasts = <AppToastEntry>[];
  late final StreamSubscription<AppToastEntry> _showSub;
  late final StreamSubscription<String> _dismissSub;

  @override
  void initState() {
    super.initState();
    _showSub = AppToastController.instance.onToast.listen(_addToast);
    _dismissSub = AppToastController.instance.onDismiss.listen(_removeToast);
  }

  void _addToast(AppToastEntry entry) {
    setState(() {
      switch (entry.position) {
        case AppToastPosition.top:
          _topToasts.insert(0, entry);
          if (_topToasts.length > widget.maxVisible) _topToasts.removeLast();
        case AppToastPosition.bottom:
          _bottomToasts.insert(0, entry);
          if (_bottomToasts.length > widget.maxVisible) _bottomToasts.removeLast();
        case AppToastPosition.center:
          _centerToasts.insert(0, entry);
          if (_centerToasts.length > widget.maxVisible) _centerToasts.removeLast();
      }
    });
  }

  void _removeToast(String id) {
    setState(() {
      _topToasts.removeWhere((e) => e.id == id);
      _bottomToasts.removeWhere((e) => e.id == id);
      _centerToasts.removeWhere((e) => e.id == id);
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
    return Stack(
      children: [
        widget.child,
        // Top toasts
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: _ToastStack(toasts: _topToasts, onRemove: _removeToast, slideFromTop: true),
        ),
        // Center toasts
        if (_centerToasts.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _centerToasts
                    .map((e) => Padding(
                          key: ValueKey(e.id),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                          child: _ToastCard(entry: e, onDismiss: () => _removeToast(e.id)),
                        ))
                    .toList(),
              ),
            ),
          ),
        // Bottom toasts
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 80,
          left: 16,
          right: 16,
          child: _ToastStack(toasts: _bottomToasts, onRemove: _removeToast, slideFromTop: false),
        ),
      ],
    );
  }
}

class _ToastStack extends StatelessWidget {
  final List<AppToastEntry> toasts;
  final void Function(String) onRemove;
  final bool slideFromTop;

  const _ToastStack({required this.toasts, required this.onRemove, required this.slideFromTop});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: toasts.map((e) => Padding(
        key: ValueKey(e.id),
        padding: const EdgeInsets.only(bottom: 8),
        child: _ToastCard(entry: e, onDismiss: () => onRemove(e.id), slideFromTop: slideFromTop),
      )).toList(),
    );
  }
}

// ─── Individual Toast Card ────────────────────────────────────────────────────
class _ToastCard extends StatefulWidget {
  final AppToastEntry entry;
  final VoidCallback onDismiss;
  final bool slideFromTop;

  const _ToastCard({
    required this.entry,
    required this.onDismiss,
    this.slideFromTop = false,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  Timer? _timer;
  double _progress = 1.0;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.entry.persistent) {
      _startTimer();
    }
  }

  void _startTimer() {
    final total = widget.entry.duration.inMilliseconds;
    const tick = 50;
    _timer = Timer.periodic(const Duration(milliseconds: tick), (t) {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final config = _toastConfig(widget.entry.type, cs);

    return Dismissible(
      key: Key(widget.entry.id),
      direction: widget.entry.canDismiss ? DismissDirection.horizontal : DismissDirection.none,
      onDismissed: (_) => _dismiss(),
      child: Material(
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: config.background,
            border: Border.all(color: config.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: config.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: widget.entry.leading ??
                          Icon(config.icon, color: config.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.entry.title != null)
                            Text(
                              widget.entry.title!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: config.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            widget.entry.message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: config.textColor.withOpacity(0.85),
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
                                  color: config.iconColor,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.entry.canDismiss)
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(Icons.close_rounded, size: 16, color: config.textColor.withOpacity(0.5)),
                      ),
                  ],
                ),
              ),
              // Progress bar
              if (!widget.entry.persistent && widget.entry.showProgress)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    backgroundColor: config.iconBg,
                    valueColor: AlwaysStoppedAnimation(config.iconColor),
                    minHeight: 3,
                  ),
                ),
            ],
          ),
        ),
      )
          .animate()
          .slideY(
            begin: widget.slideFromTop ? -1 : 1,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: 200.ms),
    );
  }
}

class _ToastConfig {
  final Color background;
  final Color border;
  final Color iconBg;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _ToastConfig({
    required this.background,
    required this.border,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}

_ToastConfig _toastConfig(AppToastType type, ColorScheme cs) {
  return switch (type) {
    AppToastType.success => _ToastConfig(
        background: const Color(0xFFF0FDF4),
        border: const Color(0xFFBBF7D0),
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        textColor: const Color(0xFF14532D),
        icon: Icons.check_circle_rounded,
      ),
    AppToastType.error => _ToastConfig(
        background: const Color(0xFFFFF1F2),
        border: const Color(0xFFFFCDD5),
        iconBg: const Color(0xFFFFE4E8),
        iconColor: const Color(0xFFDC2626),
        textColor: const Color(0xFF7F1D1D),
        icon: Icons.error_rounded,
      ),
    AppToastType.warning => _ToastConfig(
        background: const Color(0xFFFFFBEB),
        border: const Color(0xFFFEF08A),
        iconBg: const Color(0xFFFEF9C3),
        iconColor: const Color(0xFFD97706),
        textColor: const Color(0xFF713F12),
        icon: Icons.warning_rounded,
      ),
    AppToastType.loading => _ToastConfig(
        background: cs.surface,
        border: cs.outlineVariant,
        iconBg: cs.primaryContainer,
        iconColor: cs.primary,
        textColor: cs.onSurface,
        icon: Icons.sync_rounded,
      ),
    _ => _ToastConfig(
        background: const Color(0xFFF0F9FF),
        border: const Color(0xFFBAE6FD),
        iconBg: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
        textColor: const Color(0xFF0C4A6E),
        icon: Icons.info_rounded,
      ),
  };
}
