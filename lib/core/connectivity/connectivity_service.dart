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

  @override
  Future<ConnectivityState> build() async {
    ref.onDispose(() {
      _connectivitySub?.cancel();
      _internetSub?.cancel();
    });

    // Initial check
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    final hasInternet = await InternetConnection().hasInternetAccess;

    // Listen to connectivity changes
    _connectivitySub = connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final internet =
          results.any((r) => r != ConnectivityResult.none) &&
          await InternetConnection().hasInternetAccess;
      state = AsyncData(
        ConnectivityState(
          status: internet
              ? NetworkStatus.connected
              : NetworkStatus.disconnected,
          types: results,
          hasInternet: internet,
        ),
      );
    });

    // Listen to internet status changes
    _internetSub = InternetConnection().onStatusChange.listen((status) async {
      final current = state.value;
      state = AsyncData(
        (current ?? const ConnectivityState()).copyWith(
          status: status == InternetStatus.connected
              ? NetworkStatus.connected
              : NetworkStatus.disconnected,
          hasInternet: status == InternetStatus.connected,
        ),
      );
    });

    return ConnectivityState(
      status: hasInternet
          ? NetworkStatus.connected
          : NetworkStatus.disconnected,
      types: initial,
      hasInternet: hasInternet,
    );
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
