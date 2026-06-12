// ─── AppNetworkStatusWidget ───────────────────────────────────────────────────
// InheritedWidget-based connectivity status for deeply-nested widgets.
// Complement to the Riverpod ConnectivityService — no ref needed.
//
// Setup (wrap app root or scaffold):
//   AppNetworkStatusWidget(child: MyApp())
//
// Read in any widget:
//   final isOnline = AppNetworkStatus.isOnline(context);
//   final status   = AppNetworkStatus.of(context);
//
// Show offline banner automatically:
//   AppNetworkStatusWidget(showOfflineBanner: true, child: ...)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ─── InheritedWidget ──────────────────────────────────────────────────────────

class _NetworkStatusInherited extends InheritedWidget {
  final bool isOnline;
  final List<ConnectivityResult> connectionTypes;

  const _NetworkStatusInherited({
    required this.isOnline,
    required this.connectionTypes,
    required super.child,
  });

  @override
  bool updateShouldNotify(_NetworkStatusInherited old) =>
      isOnline != old.isOnline || connectionTypes != old.connectionTypes;
}

// ─── Public accessor ──────────────────────────────────────────────────────────

class AppNetworkStatus {
  AppNetworkStatus._();

  /// Returns true when online. Defaults to true if not wrapped.
  static bool isOnline(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_NetworkStatusInherited>();
    return inherited?.isOnline ?? true;
  }

  static bool isOffline(BuildContext context) => !isOnline(context);

  static List<ConnectivityResult> connectionTypes(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_NetworkStatusInherited>();
    return inherited?.connectionTypes ?? const [];
  }

  static bool isWifi(BuildContext context) =>
      connectionTypes(context).contains(ConnectivityResult.wifi);

  static bool isMobile(BuildContext context) =>
      connectionTypes(context).contains(ConnectivityResult.mobile);
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class AppNetworkStatusWidget extends StatefulWidget {
  final Widget child;

  /// Show a persistent offline banner at the top of child.
  final bool showOfflineBanner;

  /// Custom offline banner widget. Defaults to a Material warning strip.
  final Widget? offlineBanner;

  /// Called when connectivity changes.
  final void Function(bool isOnline)? onStatusChange;

  const AppNetworkStatusWidget({
    super.key,
    required this.child,
    this.showOfflineBanner = false,
    this.offlineBanner,
    this.onStatusChange,
  });

  @override
  State<AppNetworkStatusWidget> createState() =>
      _AppNetworkStatusWidgetState();
}

class _AppNetworkStatusWidgetState extends State<AppNetworkStatusWidget> {
  bool _isOnline = true;
  List<ConnectivityResult> _types = const [];
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _update(result);

    _sub = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> result) {
    final online = result.any((r) => r != ConnectivityResult.none);
    if (!mounted) return;
    if (online != _isOnline || result != _types) {
      setState(() {
        _isOnline = online;
        _types = result;
      });
      widget.onStatusChange?.call(online);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _NetworkStatusInherited(
      isOnline: _isOnline,
      connectionTypes: _types,
      child: widget.child,
    );

    if (widget.showOfflineBanner) {
      body = Stack(
        children: [
          body,
          if (!_isOnline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: widget.offlineBanner ?? const _DefaultOfflineBanner(),
            ),
        ],
      );
    }

    return body;
  }
}

// ─── Default offline banner ───────────────────────────────────────────────────

class _DefaultOfflineBanner extends StatelessWidget {
  const _DefaultOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: const Color(0xFFB91C1C),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          bottom: 8,
          left: 16,
          right: 16,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
            SizedBox(width: 8),
            Text(
              'No internet connection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
