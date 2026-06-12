import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

// ─── Connectivity State ───────────────────────────────────────────────────────
enum NetworkStatus { connected, disconnected, checking }

class ConnectivityState {
  final NetworkStatus status;
  final List<ConnectivityResult> types;
  final bool hasInternet;

  const ConnectivityState({
    this.status = NetworkStatus.checking,
    this.types = const [],
    this.hasInternet = false,
  });

  bool get isConnected => status == NetworkStatus.connected && hasInternet;
  bool get isDisconnected =>
      status == NetworkStatus.disconnected || !hasInternet;
  bool get isChecking => status == NetworkStatus.checking;

  bool get isWifi => types.contains(ConnectivityResult.wifi);
  bool get isMobile => types.contains(ConnectivityResult.mobile);
  bool get isEthernet => types.contains(ConnectivityResult.ethernet);

  String get connectionTypeLabel {
    if (isWifi) return 'Wi-Fi';
    if (isMobile) return 'Mobile Data';
    if (isEthernet) return 'Ethernet';
    if (isDisconnected) return 'No Connection';
    return 'Unknown';
  }

  ConnectivityState copyWith({
    NetworkStatus? status,
    List<ConnectivityResult>? types,
    bool? hasInternet,
  }) => ConnectivityState(
    status: status ?? this.status,
    types: types ?? this.types,
    hasInternet: hasInternet ?? this.hasInternet,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityState &&
          other.status == status &&
          other.hasInternet == hasInternet;

  @override
  int get hashCode => Object.hash(status, hasInternet);
}

// ─── Connectivity Notifier ────────────────────────────────────────────────────
class ConnectivityNotifier extends AsyncNotifier<ConnectivityState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetSub;

  // Track creation time to ignore startup/splash connectivity glitches
  final DateTime _createdAt = DateTime.now();

  @override
  Future<ConnectivityState> build() async {
    ref.onDispose(() {
      _connectivitySub?.cancel();
      _internetSub?.cancel();
    });

    // 1. Initial check (fetch connections status first time/splash)
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    final hasInternet = await InternetConnection().hasInternetAccess;

    final initialState = ConnectivityState(
      status: hasInternet
          ? NetworkStatus.connected
          : NetworkStatus.disconnected,
      types: initial,
      hasInternet: hasInternet,
    );

    // 2. Subscribe to listen to updates after fetching initial status
    _subscribeToChanges(connectivity, initialState);

    return initialState;
  }

  void _subscribeToChanges(Connectivity connectivity, ConnectivityState initialState) {
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) async {
      final internet =
          results.any((r) => r != ConnectivityResult.none) &&
          await InternetConnection().hasInternetAccess;
      final newState = ConnectivityState(
        status: internet ? NetworkStatus.connected : NetworkStatus.disconnected,
        types: results,
        hasInternet: internet,
      );
      _updateStateIfChanged(newState);
    });

    _internetSub = InternetConnection().onStatusChange.listen((status) {
      final current = state.value ?? initialState;
      final newState = current.copyWith(
        status: status == InternetStatus.connected
            ? NetworkStatus.connected
            : NetworkStatus.disconnected,
        hasInternet: status == InternetStatus.connected,
      );
      _updateStateIfChanged(newState);
    });
  }

  void _updateStateIfChanged(ConnectivityState newState) {
    final current = state.value;
    if (current == null) {
      state = AsyncData(newState);
      return;
    }

    // If new status is same as older, do not update (avoids redundant updates and toasts)
    if (current == newState) {
      return;
    }

    // Ignore transitions to disconnected within the first 2 seconds of initialization
    // to prevent startup/splash false offline alerts caused by stream initialization glitches
    if (DateTime.now().difference(_createdAt).inSeconds < 2 && newState.isDisconnected) {
      return;
    }

    state = AsyncData(newState);
  }

  Future<bool> checkNow() async {
    state = const AsyncLoading<ConnectivityState>();
    final internet = await InternetConnection().hasInternetAccess;
    final types = await Connectivity().checkConnectivity();
    state = AsyncData(
      ConnectivityState(
        status: internet ? NetworkStatus.connected : NetworkStatus.disconnected,
        types: types,
        hasInternet: internet,
      ),
    );
    return internet;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
final connectivityProvider =
    AsyncNotifierProvider<ConnectivityNotifier, ConnectivityState>(
      ConnectivityNotifier.new,
    );

/// Simple bool convenience provider
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value?.isConnected ?? false;
});
