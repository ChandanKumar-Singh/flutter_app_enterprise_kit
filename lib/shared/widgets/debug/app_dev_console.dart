// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum _NetworkStatus { success, error, pending }

class AppNetworkLog {
  final String method;
  final String url;
  final int? statusCode;
  final int? durationMs;
  final DateTime timestamp;
  final String? requestBody;
  final String? responseBody;
  final _NetworkStatus status;

  AppNetworkLog({
    required this.method,
    required this.url,
    this.statusCode,
    this.durationMs,
    DateTime? timestamp,
    this.requestBody,
    this.responseBody,
    _NetworkStatus? status,
  })  : timestamp = timestamp ?? DateTime.now(),
        status = status ??
            (statusCode != null
                ? statusCode! < 400
                    ? _NetworkStatus.success
                    : _NetworkStatus.error
                : _NetworkStatus.pending);
}

// ─── AppDevConsole ────────────────────────────────────────────────────────────
/// Developer diagnostics overlay — debug builds only.
///
/// Features:
/// - Draggable floating FAB (debug badge)
/// - 4 tabs: Network log, State, Prefs, FPS overlay
/// - Network log with method/status/url/duration
/// - Key-value state inspector
/// - SharedPrefs-style key/value editor
/// - FPS meter overlay
///
/// USAGE: Wrap app scaffold with AppDevConsoleWrapper.
/// The overlay is stripped from release builds via kDebugMode.
class AppDevConsoleWrapper extends StatefulWidget {
  final Widget child;
  final List<AppNetworkLog> networkLogs;
  final Map<String, dynamic> stateSnapshot;
  final Map<String, String> prefs;

  const AppDevConsoleWrapper({
    super.key,
    required this.child,
    this.networkLogs = const [],
    this.stateSnapshot = const {},
    this.prefs = const {},
  });

  @override
  State<AppDevConsoleWrapper> createState() => _AppDevConsoleWrapperState();
}

class _AppDevConsoleWrapperState extends State<AppDevConsoleWrapper>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  Offset _fabPosition = const Offset(20, 160);
  bool _showFps = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        widget.child,

        // FPS overlay
        if (_showFps)
          const Positioned(
            top: 48, right: 16,
            child: _FpsOverlay(),
          ),

        // Main panel
        if (_open)
          Positioned.fill(
            child: _DevPanel(
              networkLogs: widget.networkLogs,
              stateSnapshot: widget.stateSnapshot,
              prefs: widget.prefs,
              showFps: _showFps,
              onToggleFps: () => setState(() => _showFps = !_showFps),
              onClose: () => setState(() => _open = false),
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .slideY(begin: 0.04, duration: 200.ms, curve: Curves.easeOutCubic),
          ),

        // Draggable FAB
        if (!_open)
          Positioned(
            left: _fabPosition.dx,
            top: _fabPosition.dy,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) {
                setState(() {
                  _fabPosition = Offset(
                    (_fabPosition.dx + d.delta.dx).clamp(0, screenSize.width - 48),
                    (_fabPosition.dy + d.delta.dy).clamp(0, screenSize.height - 48),
                  );
                });
              },
              onTap: () {
                setState(() => _open = true);
                HapticFeedback.lightImpact();
              },
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44 + _pulseCtrl.value * 8,
                      height: 44 + _pulseCtrl.value * 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent.withOpacity(0.15 * (1 - _pulseCtrl.value)),
                      ),
                    ),
                    child!,
                  ],
                ),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A2E),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('DEV', style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    )),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Dev Panel ────────────────────────────────────────────────────────────────

class _DevPanel extends StatefulWidget {
  final List<AppNetworkLog> networkLogs;
  final Map<String, dynamic> stateSnapshot;
  final Map<String, String> prefs;
  final bool showFps;
  final VoidCallback onToggleFps;
  final VoidCallback onClose;

  const _DevPanel({
    required this.networkLogs,
    required this.stateSnapshot,
    required this.prefs,
    required this.showFps,
    required this.onToggleFps,
    required this.onClose,
  });

  @override
  State<_DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<_DevPanel> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xF01A1A2E);
    const accent = Colors.greenAccent;

    return Container(
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withOpacity(0.4)),
                    ),
                    child: const Text('DEV CONSOLE', style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    )),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'flutter ${kDebugMode ? 'debug' : 'release'}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      widget.showFps ? Icons.speed : Icons.speed_outlined,
                      color: widget.showFps ? accent : Colors.white54,
                      size: 20,
                    ),
                    tooltip: 'FPS overlay',
                    onPressed: widget.onToggleFps,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: accent,
              unselectedLabelColor: Colors.white38,
              indicatorColor: accent,
              indicatorWeight: 1.5,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Network (${widget.networkLogs.length})'),
                const Tab(text: 'State'),
                const Tab(text: 'Prefs'),
                const Tab(text: 'Info'),
              ],
            ),

            const Divider(height: 1, color: Colors.white12),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _NetworkTab(logs: widget.networkLogs),
                  _StateTab(snapshot: widget.stateSnapshot),
                  _PrefsTab(prefs: widget.prefs),
                  const _InfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Network Tab ──────────────────────────────────────────────────────────────

class _NetworkTab extends StatelessWidget {
  final List<AppNetworkLog> logs;
  const _NetworkTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No network requests captured', style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
      itemBuilder: (_, i) {
        final log = logs[i];
        return _NetworkRow(log: log);
      },
    );
  }
}

class _NetworkRow extends StatelessWidget {
  final AppNetworkLog log;
  const _NetworkRow({required this.log});

  Color get _statusColor {
    return switch (log.status) {
      _NetworkStatus.success => Colors.greenAccent,
      _NetworkStatus.error   => Colors.redAccent,
      _NetworkStatus.pending => Colors.orangeAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Method pill
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(log.method, style: TextStyle(color: _statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.url,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (log.statusCode != null)
                      Text('${log.statusCode}', style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    if (log.durationMs != null) ...[
                      const Text(' · ', style: TextStyle(color: Colors.white24, fontSize: 10)),
                      Text('${log.durationMs}ms', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                    const Spacer(),
                    Text(
                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State Tab ────────────────────────────────────────────────────────────────

class _StateTab extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  const _StateTab({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot.isEmpty) {
      return const Center(
        child: Text('Pass stateSnapshot to DevConsoleWrapper', style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: snapshot.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.key}:',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${e.value}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Prefs Tab ────────────────────────────────────────────────────────────────

class _PrefsTab extends StatefulWidget {
  final Map<String, String> prefs;
  const _PrefsTab({required this.prefs});

  @override
  State<_PrefsTab> createState() => _PrefsTabState();
}

class _PrefsTabState extends State<_PrefsTab> {
  late Map<String, String> _edited;
  String? _editingKey;
  late TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _edited = Map.from(widget.prefs);
    _editCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_edited.isEmpty) {
      return const Center(
        child: Text('No preferences to show', style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: _edited.entries.map((e) {
        final isEditing = _editingKey == e.key;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isEditing ? Colors.greenAccent.withOpacity(0.08) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEditing ? Colors.greenAccent.withOpacity(0.4) : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(e.key, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontFamily: 'monospace')),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: isEditing
                    ? TextField(
                        controller: _editCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        autofocus: true,
                        onSubmitted: (v) {
                          setState(() {
                            _edited[e.key] = v;
                            _editingKey = null;
                          });
                        },
                      )
                    : Text(e.value, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isEditing) {
                      _edited[e.key] = _editCtrl.text;
                      _editingKey = null;
                    } else {
                      _editingKey = e.key;
                      _editCtrl.text = e.value;
                    }
                  });
                },
                child: Icon(
                  isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  color: isEditing ? Colors.greenAccent : Colors.white38,
                  size: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Info Tab ─────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Mode', kDebugMode ? 'DEBUG' : kProfileMode ? 'PROFILE' : 'RELEASE'),
      ('Flutter', '3.27+'),
      ('Dart', '3.12+'),
      ('Platform', defaultTargetPlatform.name),
      ('Screen W', '${MediaQuery.of(context).size.width.toStringAsFixed(0)}px'),
      ('Screen H', '${MediaQuery.of(context).size.height.toStringAsFixed(0)}px'),
      ('DPR', '${MediaQuery.of(context).devicePixelRatio.toStringAsFixed(2)}x'),
      ('TextScale', '${MediaQuery.of(context).textScaler.scale(1.0).toStringAsFixed(2)}'),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: rows.map((r) {
        final (key, val) = r;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(key, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ),
              Text(val, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── FPS Overlay ──────────────────────────────────────────────────────────────

class _FpsOverlay extends StatefulWidget {
  const _FpsOverlay();

  @override
  State<_FpsOverlay> createState() => _FpsOverlayState();
}

class _FpsOverlayState extends State<_FpsOverlay> {
  final _history = <double>[];
  double _fps = 0;
  late final Stopwatch _stopwatch;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback(_tick);
  }

  void _tick(Duration _) {
    _frameCount++;
    if (_stopwatch.elapsedMilliseconds >= 1000) {
      final newFps = _frameCount / (_stopwatch.elapsedMilliseconds / 1000);
      _stopwatch.reset();
      _frameCount = 0;
      if (mounted) {
        setState(() {
          _fps = newFps;
          _history.add(newFps);
          if (_history.length > 60) _history.removeAt(0);
        });
      }
    }
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback(_tick);
    }
  }

  Color get _fpsColor {
    if (_fps >= 55) return Colors.greenAccent;
    if (_fps >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _fpsColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fps.toStringAsFixed(0),
                style: TextStyle(color: _fpsColor, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 4),
              const Text('fps', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          // Mini sparkline
          SizedBox(
            height: 20, width: 80,
            child: CustomPaint(painter: _SparklinePainter(_history, _fpsColor)),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final maxVal = values.reduce(math.max).clamp(1.0, double.infinity);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - (values[i] / maxVal) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => true;
}
