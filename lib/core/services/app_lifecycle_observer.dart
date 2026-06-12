// ─── AppLifecycleObserver ─────────────────────────────────────────────────────
// WidgetsBindingObserver wrapper for app lifecycle + memory pressure.
// Register once in app bootstrap and clean up on dispose.
//
// Usage:
//   final obs = AppLifecycleObserver(
//     onResume:          () => ref.invalidate(sessionProvider),
//     onMemoryPressure:  () => imageCache.clear(),
//     onBackground:      () => analyticsService.flush(),
//   );
//   obs.register();
//   // later:
//   obs.unregister();
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  final VoidCallback? onBackground;
  final VoidCallback? onDetach;
  final VoidCallback? onMemoryPressure;

  /// Called whenever lifecycle state changes (for custom handling).
  final void Function(AppLifecycleState state)? onStateChange;

  AppLifecycleState? _lastState;
  bool _registered = false;

  AppLifecycleObserver({
    this.onResume,
    this.onPause,
    this.onBackground,
    this.onDetach,
    this.onMemoryPressure,
    this.onStateChange,
  });

  AppLifecycleState? get currentState => _lastState;

  void register() {
    if (_registered) return;
    WidgetsBinding.instance.addObserver(this);
    _registered = true;
    debugPrint('[LifecycleObserver] registered');
  }

  void unregister() {
    if (!_registered) return;
    WidgetsBinding.instance.removeObserver(this);
    _registered = false;
    debugPrint('[LifecycleObserver] unregistered');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[LifecycleObserver] state → ${state.name}');
    _lastState = state;
    onStateChange?.call(state);

    switch (state) {
      case AppLifecycleState.resumed:
        onResume?.call();
      case AppLifecycleState.paused:
        onPause?.call();
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        onBackground?.call();
      case AppLifecycleState.detached:
        onDetach?.call();
    }
  }

  @override
  void didHaveMemoryPressure() {
    debugPrint('[LifecycleObserver] ⚠️ memory pressure — clearing caches');
    onMemoryPressure?.call();
    // Default: clear Flutter image cache on memory pressure
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Convenience factory — pre-wired for security re-check on resume.
  factory AppLifecycleObserver.withSecurityRecheck({
    required VoidCallback onSecurityRecheck,
    VoidCallback? onMemoryPressure,
  }) {
    return AppLifecycleObserver(
      onResume: onSecurityRecheck,
      onMemoryPressure: onMemoryPressure,
    );
  }
}

// ─── AppLifecycleWidget ───────────────────────────────────────────────────────
// Drop-in widget wrapper — registers/unregisters automatically.
//
// Usage:
//   AppLifecycleWidget(
//     onResume: () => ref.read(authProvider.notifier).refreshToken(),
//     child: const MyApp(),
//   )

class AppLifecycleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  final VoidCallback? onBackground;
  final VoidCallback? onMemoryPressure;
  final void Function(AppLifecycleState)? onStateChange;

  const AppLifecycleWidget({
    super.key,
    required this.child,
    this.onResume,
    this.onPause,
    this.onBackground,
    this.onMemoryPressure,
    this.onStateChange,
  });

  @override
  State<AppLifecycleWidget> createState() => _AppLifecycleWidgetState();
}

class _AppLifecycleWidgetState extends State<AppLifecycleWidget> {
  late final AppLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = AppLifecycleObserver(
      onResume: widget.onResume,
      onPause: widget.onPause,
      onBackground: widget.onBackground,
      onMemoryPressure: widget.onMemoryPressure,
      onStateChange: widget.onStateChange,
    )..register();
  }

  @override
  void dispose() {
    _observer.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
