// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Banner Model ─────────────────────────────────────────────────────────────
enum AppBannerType { info, warning, error, success, offline, announcement, maintenance }
enum AppBannerPosition { top, bottom }

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
  });
}

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

// ─── Banner Controller ────────────────────────────────────────────────────────
class AppBannerController extends ChangeNotifier {
  static final _instance = AppBannerController._();
  static AppBannerController get instance => _instance;
  AppBannerController._();

  final _topBanners = <AppBannerData>[];
  final _bottomBanners = <AppBannerData>[];
  int _counter = 0;

  List<AppBannerData> get topBanners => List.unmodifiable(_topBanners);
  List<AppBannerData> get bottomBanners => List.unmodifiable(_bottomBanners);

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
  }) {
    final banner = AppBannerData(
      id: _nextId(),
      message: message,
      title: title,
      type: type,
      position: position,
      actions: actions,
      dismissible: dismissible,
      persistent: persistent,
      leading: leading,
    );
    if (position == AppBannerPosition.top) {
      _topBanners.add(banner);
    } else {
      _bottomBanners.add(banner);
    }
    notifyListeners();
    return banner.id;
  }

  String offline({String? message}) => show(
    message: message ?? 'You\'re offline. Check your internet connection.',
    type: AppBannerType.offline,
    dismissible: false,
    persistent: true,
    leading: const Icon(Icons.wifi_off_rounded, size: 18),
  );

  String maintenance({required String message}) => show(
    message: message,
    type: AppBannerType.maintenance,
    dismissible: false,
    persistent: true,
    leading: const Icon(Icons.construction_rounded, size: 18),
  );

  void dismiss(String id) {
    _topBanners.removeWhere((b) => b.id == id);
    _bottomBanners.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void dismissAll() {
    _topBanners.clear();
    _bottomBanners.clear();
    notifyListeners();
  }

  void dismissByType(AppBannerType type) {
    _topBanners.removeWhere((b) => b.type == type);
    _bottomBanners.removeWhere((b) => b.type == type);
    notifyListeners();
  }
}

// ─── Banner Overlay ───────────────────────────────────────────────────────────
class AppBannerOverlay extends StatefulWidget {
  final Widget child;

  const AppBannerOverlay({super.key, required this.child});

  @override
  State<AppBannerOverlay> createState() => _AppBannerOverlayState();
}

class _AppBannerOverlayState extends State<AppBannerOverlay> {
  @override
  void initState() {
    super.initState();
    AppBannerController.instance.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    AppBannerController.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppBannerController.instance;
    return Column(
      children: [
        // Top banners
        ...ctrl.topBanners.map((b) => _BannerTile(
              banner: b,
              onDismiss: () => ctrl.dismiss(b.id),
            )),
        // Main content
        Expanded(child: widget.child),
        // Bottom banners
        ...ctrl.bottomBanners.reversed.map((b) => _BannerTile(
              banner: b,
              fromBottom: true,
              onDismiss: () => ctrl.dismiss(b.id),
            )),
      ],
    );
  }
}

// ─── Banner Tile ──────────────────────────────────────────────────────────────
class _BannerTile extends StatelessWidget {
  final AppBannerData banner;
  final VoidCallback onDismiss;
  final bool fromBottom;

  const _BannerTile({
    required this.banner,
    required this.onDismiss,
    this.fromBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _bannerConfig(banner.type, Theme.of(context).colorScheme);

    return Container(
      width: double.infinity,
      color: config.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading icon
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: banner.leading ??
                Icon(config.icon, size: 18, color: config.iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner.title != null)
                  Text(
                    banner.title!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: config.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                Text(
                  banner.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: config.textColor.withOpacity(0.9),
                      ),
                ),
                if (banner.actions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: banner.actions.map((a) {
                      return GestureDetector(
                        onTap: a.onTap,
                        child: Text(
                          a.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: config.iconColor,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      );
                    }).toList(),
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
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.close_rounded, size: 16, color: config.textColor.withOpacity(0.6)),
              ),
            ),
        ],
      ),
    )
        .animate()
        .slideY(begin: fromBottom ? 1 : -1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
  }
}

class _BannerConfig {
  final Color background;
  final Color textColor;
  final Color iconColor;
  final IconData icon;

  const _BannerConfig({
    required this.background,
    required this.textColor,
    required this.iconColor,
    required this.icon,
  });
}

_BannerConfig _bannerConfig(AppBannerType type, ColorScheme cs) {
  return switch (type) {
    AppBannerType.success => const _BannerConfig(
        background: Color(0xFF166534),
        textColor: Color(0xFFDCFCE7),
        iconColor: Color(0xFF86EFAC),
        icon: Icons.check_circle_outline_rounded,
      ),
    AppBannerType.error => const _BannerConfig(
        background: Color(0xFF991B1B),
        textColor: Color(0xFFFEE2E2),
        iconColor: Color(0xFFFCA5A5),
        icon: Icons.error_outline_rounded,
      ),
    AppBannerType.warning => const _BannerConfig(
        background: Color(0xFF92400E),
        textColor: Color(0xFFFEF9C3),
        iconColor: Color(0xFFFDE68A),
        icon: Icons.warning_amber_rounded,
      ),
    AppBannerType.offline => const _BannerConfig(
        background: Color(0xFF1F2937),
        textColor: Color(0xFFF9FAFB),
        iconColor: Color(0xFF9CA3AF),
        icon: Icons.wifi_off_rounded,
      ),
    AppBannerType.maintenance => const _BannerConfig(
        background: Color(0xFF1E40AF),
        textColor: Color(0xFFDBEAFE),
        iconColor: Color(0xFF93C5FD),
        icon: Icons.construction_rounded,
      ),
    AppBannerType.announcement => const _BannerConfig(
        background: Color(0xFF4C1D95),
        textColor: Color(0xFFEDE9FE),
        iconColor: Color(0xFFC4B5FD),
        icon: Icons.campaign_rounded,
      ),
    _ => _BannerConfig(
        background: cs.primaryContainer,
        textColor: cs.onPrimaryContainer,
        iconColor: cs.primary,
        icon: Icons.info_outline_rounded,
      ),
  };
}

// ─── Standalone Banner Widget ─────────────────────────────────────────────────
class AppBannerWidget extends StatelessWidget {
  final String message;
  final String? title;
  final AppBannerType type;
  final List<AppBannerAction> actions;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final Widget? leading;

  const AppBannerWidget({
    super.key,
    required this.message,
    this.title,
    this.type = AppBannerType.info,
    this.actions = const [],
    this.dismissible = true,
    this.onDismiss,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return _BannerTile(
      banner: AppBannerData(
        id: 'standalone',
        message: message,
        title: title,
        type: type,
        actions: actions,
        dismissible: dismissible,
        leading: leading,
      ),
      onDismiss: onDismiss ?? () {},
    );
  }
}
