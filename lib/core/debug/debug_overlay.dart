import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:enterprise_kit/core/bootstrap/env_config.dart';

// Riverpod 3: StateProvider removed — use NotifierProvider
class _DebugVisible extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void hide() => state = false;
}

final _debugVisibleProvider = NotifierProvider<_DebugVisible, bool>(_DebugVisible.new);

class DebugOverlay extends ConsumerWidget {
  final Widget child;
  const DebugOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode && !EnvConfig.showDebugOverlay) return child;
    final visible = ref.watch(_debugVisibleProvider);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          Positioned(
            right: 8,
            bottom: 100,
            child: GestureDetector(
              onTap: () => ref.read(_debugVisibleProvider.notifier).toggle(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Icon(Icons.bug_report, color: Colors.orange, size: 20),
              ),
            ),
          ),
          if (visible)
            Positioned.fill(
              child: _DebugPanel(
                onClose: () => ref.read(_debugVisibleProvider.notifier).hide(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DebugPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _DebugPanel({required this.onClose});

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  PackageInfo? _pkgInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) => setState(() => _pkgInfo = p));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🐛 Debug Panel',
                  style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white)),
            ],
          ),
          const Divider(color: Colors.orange),
          _row('Flavor', EnvConfig.flavor.name.toUpperCase()),
          _row('Base URL', EnvConfig.baseUrl),
          if (_pkgInfo != null) ...[
            _row('App', _pkgInfo!.appName),
            _row('Version', '${_pkgInfo!.version}+${_pkgInfo!.buildNumber}'),
            _row('Package', _pkgInfo!.packageName),
          ],
          _row('Mode', kDebugMode ? 'DEBUG' : 'RELEASE'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
}
