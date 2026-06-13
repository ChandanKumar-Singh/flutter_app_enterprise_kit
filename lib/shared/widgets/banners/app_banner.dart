// ignore_for_file: deprecated_member_use
// ─── AppBanner ────────────────────────────────────────────────────────────────
// Enterprise-grade banner + connectivity indicator system.
//
// Two distinct visual modes:
//
//   strip    (position: top)    — Full-width row BELOW the status bar, pushes
//                                 content down. Used for maintenance / announcements.
//                                 Respects SafeArea automatically.
//
//   pill     (position: bottom) — Floating rounded card above the bottom safe
//                                 area / nav bar. Does NOT push content. Used for
//                                 offline indicator, app updates, non-blocking alerts.
//
// UX principles applied:
//   • Offline → bottom pill — never obscures content, non-alarming dark glass
//   • Error/maintenance → top strip — must be seen, pushes content intentionally
//   • All enter/exit with spring animation — never janky
//   • Auto-dismiss for non-persistent banners (default 6 s for info/success)
//   • Status-bar inset applied automatically on top strips
//
// Usage:
//   AppBannerController.instance.offline();
//   AppBannerController.instance.show(message: '...', type: AppBannerType.maintenance);
//   AppBannerController.instance.dismiss(id);
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Public enums ──────────────────────────────────────────────────────────────

enum AppBannerType {
  info,
  warning,
  error,
  success,
  offline,
  announcement,
  maintenance,
  update,
}

/// Where and how the banner renders.
enum AppBannerPosition {
  /// Full-width strip pinned at the top (below status bar). Pushes content.
  top,
  /// Floating pill near the bottom (above safe area). Overlays content.
  bottom,
}

// ── Data model ────────────────────────────────────────────────────────────────

class AppBannerAction {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const AppBannerAction({
    required this.label,
    required this.onTap,
    this.primary = false,
  });
}

class AppBannerData {
  final String id;
  final String message;
  final String? title;
  final AppBannerType type;
  final AppBannerPosition position;
  final List<AppBannerAction> actions;
  final bool dismissible;
  final bool persistent;
  final Widget? leading;
  /// true = pill overlay; false = full-width strip.
  final bool floating;

  AppBannerData({
    required this.id,
    required this.message,
    this.title,
    this.type = AppBannerType.info,
    this.position = AppBannerPosition.top,
    this.actions = const [],
    this.dismissible = true,
    this.persistent = false,
    this.leading,
    this.floating = false,
  });
}

// ── Controller ────────────────────────────────────────────────────────────────

class AppBannerController extends ChangeNotifier {
  static final _instance = AppBannerController._();
  static AppBannerController get instance => _instance;
  AppBannerController._();

  final _banners = <AppBannerData>[];
  final _timers  = <String, Timer>{};
  int _counter   = 0;

  List<AppBannerData> get topBanners    => _banners.where((b) => b.position == AppBannerPosition.top).toList();
  List<AppBannerData> get bottomBanners => _banners.where((b) => b.position == AppBannerPosition.bottom).toList();

  String _nextId() => 'banner_${++_counter}';

  String show({
    required String message,
    String? title,
    AppBannerType type = AppBannerType.info,
    AppBannerPosition position = AppBannerPosition.top,
    List<AppBannerAction> actions = const [],
    bool dismissible = true,
    bool persistent = false,
    Widget? leading,
    bool floating = false,
    Duration? autoDismissAfter,
  }) {
    final id     = _nextId();
    final banner = AppBannerData(
      id: id,
      message: message,
      title: title,
      type: type,
      position: position,
      actions: actions,
      dismissible: dismissible,
      persistent: persistent,
      leading: leading,
      floating: floating,
    );

    _banners.add(banner);
    notifyListeners();

    // Auto-dismiss non-persistent, non-offline banners
    if (!persistent) {
      final duration = autoDismissAfter ?? _defaultDuration(type);
      if (duration != null) {
        _timers[id] = Timer(duration, () => dismiss(id));
      }
    }

    return id;
  }

  // ── Convenience methods ───────────────────────────────────────────────────

  /// Offline indicator — bottom floating pill, persistent.
  String offline({String? message}) => show(
    message: message ?? 'No internet connection',
    type: AppBannerType.offline,
    position: AppBannerPosition.bottom,
    floating: true,
    dismissible: false,
    persistent: true,
    leading: const Icon(Iconsax.wifi_square, size: 15, color: Colors.white70),
    actions: [
      AppBannerAction(label: 'Retry', onTap: () {}, primary: true),
    ],
  );

  /// Maintenance — top strip, persistent.
  String maintenance({required String message, List<AppBannerAction> actions = const []}) => show(
    message: message,
    type: AppBannerType.maintenance,
    position: AppBannerPosition.top,
    floating: false,
    dismissible: false,
    persistent: true,
    actions: actions,
  );

  /// Announcement — top strip, dismissible.
  String announcement({required String message, String? title, List<AppBannerAction> actions = const []}) => show(
    message: message,
    title: title,
    type: AppBannerType.announcement,
    position: AppBannerPosition.top,
    floating: false,
    dismissible: true,
    persistent: true,
    actions: actions,
  );

  /// Update available — bottom pill, dismissible.
  String update({required String message, List<AppBannerAction> actions = const []}) => show(
    message: message,
    type: AppBannerType.update,
    position: AppBannerPosition.bottom,
    floating: true,
    dismissible: true,
    persistent: true,
    actions: actions,
  );

  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    _banners.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void dismissAll() {
    for (final t in _timers.values) t.cancel();
    _timers.clear();
    _banners.clear();
    notifyListeners();
  }

  void dismissByType(AppBannerType type) {
    final ids = _banners.where((b) => b.type == type).map((b) => b.id).toList();
    for (final id in ids) dismiss(id);
  }

  static Duration? _defaultDuration(AppBannerType type) => switch (type) {
    AppBannerType.success      => const Duration(seconds: 5),
    AppBannerType.info         => const Duration(seconds: 6),
    AppBannerType.offline      => null,  // persistent
    AppBannerType.maintenance  => null,  // persistent
    AppBannerType.announcement => null,  // persistent (user dismisses)
    AppBannerType.update       => null,  // persistent
    _                          => null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Rendering widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Drop this into the banner layer instead of the old _BannerTile.
/// Picks strip vs pill based on banner.floating.
///
/// [embedded] — set true when rendering inside a scroll view or page body
/// (not at y=0) to suppress the automatic status-bar top inset.
class AppBannerWidget extends StatelessWidget {
  final AppBannerData banner;
  final VoidCallback onDismiss;
  /// When true the strip banner does NOT add status-bar top padding.
  /// Use for inline / embedded previews that aren't positioned at y=0.
  final bool embedded;

  const AppBannerWidget({
    super.key,
    required this.banner,
    required this.onDismiss,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) => banner.floating
      ? _PillBanner(banner: banner, onDismiss: onDismiss)
      : _StripBanner(banner: banner, onDismiss: onDismiss, embedded: embedded);
}

// ── Strip banner ──────────────────────────────────────────────────────────────
// Full-width, top-mounted, pushes content. Respects SafeArea inset.

class _StripBanner extends StatelessWidget {
  final AppBannerData banner;
  final VoidCallback onDismiss;
  final bool embedded;

  const _StripBanner({required this.banner, required this.onDismiss, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg    = _stripConfig(banner.type);
    final mq     = MediaQuery.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: cfg.bg),
      // Top inset: when at y=0 (the banner layer Column) we pad out the
      // status bar area so text never renders over clock/battery icons.
      // When embedded inline in a scroll view, no inset is needed.
      padding: EdgeInsets.only(
        top: embedded ? 10 : mq.padding.top + 8,
        bottom: 10,
        left: 0,
        right: 0,
      ),
      child: Row(
        children: [
          // Accent strip
          Container(width: 4, height: 36, color: cfg.accent),
          const SizedBox(width: 12),
          // Icon
          Icon(cfg.icon, size: 18, color: cfg.accent),
          const SizedBox(width: 10),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner.title != null)
                  Text(
                    banner.title!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cfg.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  banner.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cfg.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (banner.actions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: banner.actions.map((a) => GestureDetector(
                      onTap: a.onTap,
                      child: Text(
                        a.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: a.primary ? cfg.accent : cfg.textSecondary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: a.primary ? cfg.accent : cfg.textSecondary,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Dismiss
          if (banner.dismissible)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Iconsax.close_circle, size: 16, color: cfg.textSecondary),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    )
    .animate()
    .slideY(begin: -1.0, end: 0, duration: 340.ms, curve: Curves.easeOutBack)
    .fadeIn(duration: 200.ms);
  }
}

// ── Pill banner ───────────────────────────────────────────────────────────────
// Floating rounded card. Positioned by the parent layer.

class _PillBanner extends StatelessWidget {
  final AppBannerData banner;
  final VoidCallback onDismiss;

  const _PillBanner({required this.banner, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg    = _pillConfig(banner.type, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(50), // fully rounded pill
        border: Border.all(color: cfg.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.50 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulse dot for offline
              if (banner.type == AppBannerType.offline)
                _PulseDot(color: cfg.accent)
              else
                banner.leading ?? Icon(cfg.icon, size: 15, color: cfg.accent),
              const SizedBox(width: 8),

              // Message
              Flexible(
                child: Text(
                  banner.message,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cfg.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Actions
              ...banner.actions.take(2).map((a) => Padding(
                padding: const EdgeInsets.only(left: 10),
                child: GestureDetector(
                  onTap: () {
                    a.onTap();
                    if (banner.dismissible) onDismiss();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: a.primary
                          ? cfg.accent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: a.primary
                            ? cfg.accent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      a.label,
                      style: TextStyle(
                        color: a.primary ? cfg.accent : cfg.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )),

              // Dismiss
              if (banner.dismissible) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(Iconsax.close_circle, size: 14, color: cfg.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    )
    .animate()
    .slideY(begin: 1.0, end: 0, duration: 380.ms, curve: Curves.easeOutBack)
    .fadeIn(duration: 220.ms);
  }
}

// ── Pulse dot (for offline pill) ──────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5 * _scale.value),
              blurRadius: 6 + (4 * _scale.value),
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Config maps
// ─────────────────────────────────────────────────────────────────────────────

class _StripCfg {
  final Color bg, accent, textPrimary, textSecondary;
  final IconData icon;
  const _StripCfg({
    required this.bg, required this.accent,
    required this.textPrimary, required this.textSecondary,
    required this.icon,
  });
}

_StripCfg _stripConfig(AppBannerType type) => switch (type) {
  AppBannerType.error => const _StripCfg(
    bg: Color(0xFF1A0A0A),
    accent: Color(0xFFEF4444),
    textPrimary: Color(0xFFFEF2F2),
    textSecondary: Color(0xFFFCA5A5),
    icon: Iconsax.danger,
  ),
  AppBannerType.warning => const _StripCfg(
    bg: Color(0xFF1A1200),
    accent: Color(0xFFF59E0B),
    textPrimary: Color(0xFFFFFBEB),
    textSecondary: Color(0xFFFDE68A),
    icon: Iconsax.warning_2,
  ),
  AppBannerType.success => const _StripCfg(
    bg: Color(0xFF0A1A0E),
    accent: Color(0xFF22C55E),
    textPrimary: Color(0xFFF0FDF4),
    textSecondary: Color(0xFF86EFAC),
    icon: Iconsax.tick_circle,
  ),
  AppBannerType.maintenance => const _StripCfg(
    bg: Color(0xFF1A1400),
    accent: Color(0xFFD97706),
    textPrimary: Color(0xFFFFFBEB),
    textSecondary: Color(0xFFFDE68A),
    icon: Iconsax.designtools,
  ),
  AppBannerType.announcement => const _StripCfg(
    bg: Color(0xFF0E0A1A),
    accent: Color(0xFF8B5CF6),
    textPrimary: Color(0xFFF5F3FF),
    textSecondary: Color(0xFFC4B5FD),
    icon: Iconsax.volume_high,
  ),
  _ => const _StripCfg(
    bg: Color(0xFF0A1020),
    accent: Color(0xFF60A5FA),
    textPrimary: Color(0xFFEFF6FF),
    textSecondary: Color(0xFF93C5FD),
    icon: Iconsax.info_circle,
  ),
};

class _PillCfg {
  final Color bg, border, accent, textPrimary, textSecondary;
  final IconData icon;
  const _PillCfg({
    required this.bg, required this.border, required this.accent,
    required this.textPrimary, required this.textSecondary,
    required this.icon,
  });
}

_PillCfg _pillConfig(AppBannerType type, bool isDark) => switch (type) {
  AppBannerType.offline => _PillCfg(
    bg:            isDark ? const Color(0xFF1C2433) : const Color(0xFF1E293B),
    border:        isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.08),
    accent:        const Color(0xFF94A3B8),
    textPrimary:   Colors.white,
    textSecondary: const Color(0xFF94A3B8),
    icon:          Iconsax.wifi_square,
  ),
  AppBannerType.update => _PillCfg(
    bg:            isDark ? const Color(0xFF1E1B4B) : const Color(0xFF1E1B4B),
    border:        const Color(0xFF8B5CF6).withOpacity(0.3),
    accent:        const Color(0xFFA78BFA),
    textPrimary:   Colors.white,
    textSecondary: const Color(0xFFC4B5FD),
    icon:          Iconsax.refresh,
  ),
  AppBannerType.error => _PillCfg(
    bg:            const Color(0xFF1A0505),
    border:        const Color(0xFFEF4444).withOpacity(0.3),
    accent:        const Color(0xFFEF4444),
    textPrimary:   Colors.white,
    textSecondary: const Color(0xFFFCA5A5),
    icon:          Iconsax.danger,
  ),
  AppBannerType.warning => _PillCfg(
    bg:            const Color(0xFF1A1200),
    border:        const Color(0xFFF59E0B).withOpacity(0.3),
    accent:        const Color(0xFFF59E0B),
    textPrimary:   Colors.white,
    textSecondary: const Color(0xFFFDE68A),
    icon:          Iconsax.warning_2,
  ),
  _ => _PillCfg(
    bg:            isDark ? const Color(0xFF1C2433) : const Color(0xFF1E293B),
    border:        Colors.white.withOpacity(0.1),
    accent:        const Color(0xFF60A5FA),
    textPrimary:   Colors.white,
    textSecondary: const Color(0xFF93C5FD),
    icon:          Iconsax.info_circle,
  ),
};
