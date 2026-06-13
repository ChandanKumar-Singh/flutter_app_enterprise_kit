// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── AppMiniPlayerData ────────────────────────────────────────────────────────

class AppMiniPlayerData {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final Color? accentColor;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isLiked;

  const AppMiniPlayerData({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.accentColor,
    this.duration = const Duration(minutes: 3, seconds: 42),
    this.position = Duration.zero,
    this.isPlaying = false,
    this.isLiked = false,
  });

  AppMiniPlayerData copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    Color? accentColor,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isLiked,
  }) {
    return AppMiniPlayerData(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      accentColor: accentColor ?? this.accentColor,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

// ─── AppMiniPlayer ────────────────────────────────────────────────────────────
/// Spotify/YouTube-style persistent mini player.
///
/// States:
/// - Mini (collapsed): 64px strip above bottom nav
/// - Expanded: full-screen player with artwork + controls
///
/// Features:
/// - Drag to expand / collapse
/// - Swipe left/right to skip
/// - Swipe down to dismiss (mini mode only)
/// - Progress bar animates with position
/// - Glassmorphic background with accent color
/// - Spring physics on expand/collapse
class AppMiniPlayer extends StatefulWidget {
  final AppMiniPlayerData data;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onLike;
  final VoidCallback? onDismiss;
  final ValueChanged<Duration>? onSeek;
  final double bottomPadding;

  const AppMiniPlayer({
    super.key,
    required this.data,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onLike,
    this.onDismiss,
    this.onSeek,
    this.bottomPadding = 80,
  });

  @override
  State<AppMiniPlayer> createState() => _AppMiniPlayerState();
}

class _AppMiniPlayerState extends State<AppMiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandCtrl;
  bool _expanded = false;
  double _dragOffset = 0;
  double _swipeX = 0;

  static const double _miniHeight = 64.0;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
      HapticFeedback.lightImpact();
    } else {
      _expandCtrl.reverse();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (widget.data.duration.inMilliseconds == 0) return 0;
    return widget.data.position.inMilliseconds / widget.data.duration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = widget.data.accentColor ?? cs.primary;

    return AnimatedBuilder(
      animation: _expandCtrl,
      builder: (_, __) {
        final t = _expandCtrl.value;
        final screenH = MediaQuery.sizeOf(context).height;
        final screenW = MediaQuery.sizeOf(context).width;

        // Interpolated dimensions
        final height = lerpDouble(_miniHeight + widget.bottomPadding, screenH, t)!;
        final borderRadius = lerpDouble(AppSpacing.radiusLg, 0, t)!;

        return Positioned(
          bottom: lerpDouble(widget.bottomPadding - _miniHeight, 0, t)!,
          left: lerpDouble(8, 0, t)!,
          right: lerpDouble(8, 0, t)!,
          height: height,
          child: GestureDetector(
            onVerticalDragUpdate: (d) {
              setState(() => _dragOffset += d.delta.dy);
              if (!_expanded && _dragOffset < -30) {
                _dragOffset = 0;
                _toggleExpand();
              } else if (_expanded && _dragOffset > 60) {
                _dragOffset = 0;
                _toggleExpand();
              }
            },
            onVerticalDragEnd: (_) => setState(() => _dragOffset = 0),
            onHorizontalDragUpdate: (d) => setState(() => _swipeX += d.delta.dx),
            onHorizontalDragEnd: (d) {
              if (!_expanded) {
                if (_swipeX < -60) {
                  widget.onNext?.call();
                  HapticFeedback.lightImpact();
                } else if (_swipeX > 60) {
                  if (_swipeX > 100 && widget.onDismiss != null) {
                    widget.onDismiss!();
                  } else {
                    widget.onPrevious?.call();
                    HapticFeedback.lightImpact();
                  }
                }
              }
              setState(() => _swipeX = 0);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20 * t, sigmaY: 20 * t),
                child: Container(
                  decoration: BoxDecoration(
                    color: _expanded
                        ? Color.lerp(accentColor.withOpacity(0.95), cs.surface, 0.1)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      if (!_expanded)
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, -2),
                        ),
                    ],
                  ),
                  child: _expanded
                      ? _ExpandedPlayer(
                          data: widget.data,
                          progress: _progress,
                          accentColor: accentColor,
                          onPlayPause: widget.onPlayPause,
                          onNext: widget.onNext,
                          onPrevious: widget.onPrevious,
                          onLike: widget.onLike,
                          onCollapse: _toggleExpand,
                          onSeek: widget.onSeek,
                          formatDuration: _formatDuration,
                        )
                      : _MiniBar(
                          data: widget.data,
                          progress: _progress,
                          accentColor: accentColor,
                          onPlayPause: widget.onPlayPause,
                          onNext: widget.onNext,
                          onExpand: _toggleExpand,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Mini Bar ─────────────────────────────────────────────────────────────────

class _MiniBar extends StatelessWidget {
  final AppMiniPlayerData data;
  final double progress;
  final Color accentColor;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onExpand;

  const _MiniBar({
    required this.data,
    required this.progress,
    required this.accentColor,
    this.onPlayPause,
    this.onNext,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onExpand,
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: cs.outlineVariant.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(accentColor),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40, height: 40,
                      color: accentColor.withOpacity(0.2),
                      child: data.imageUrl != null
                          ? Image.network(data.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Iconsax.musicnote, color: accentColor, size: 20))
                          : Icon(Iconsax.musicnote, color: accentColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(data.subtitle, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Controls
                  IconButton(
                    icon: Icon(data.isPlaying ? Iconsax.pause : Iconsax.play, size: 28),
                    onPressed: onPlayPause,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.next, size: 24),
                    onPressed: onNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expanded Player ─────────────────────────────────────────────────────────

class _ExpandedPlayer extends StatelessWidget {
  final AppMiniPlayerData data;
  final double progress;
  final Color accentColor;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onLike;
  final VoidCallback? onCollapse;
  final ValueChanged<Duration>? onSeek;
  final String Function(Duration) formatDuration;

  const _ExpandedPlayer({
    required this.data,
    required this.progress,
    required this.accentColor,
    required this.formatDuration,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onLike,
    this.onCollapse,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final safeTop = MediaQuery.paddingOf(context).top;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Drag handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: 12),

            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.arrow_down_1, size: 28),
                  onPressed: onCollapse,
                  color: cs.onSurface,
                ),
                Text('Now Playing', style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.7))),
                IconButton(
                  icon: const Icon(Iconsax.more),
                  onPressed: () {},
                  color: cs.onSurface,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Artwork (big)
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedScale(
                    scale: data.isPlaying ? 1.0 : 0.88,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: data.imageUrl != null
                            ? Image.network(data.imageUrl!, fit: BoxFit.cover)
                            : Icon(Iconsax.musicnote, size: 80, color: accentColor),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Title + Like
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(data.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Icon(
                      data.isLiked ? Iconsax.heart : Iconsax.heart,
                      key: ValueKey(data.isLiked),
                      color: data.isLiked ? Colors.red : cs.onSurface,
                    ),
                  ),
                  onPressed: onLike,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress slider
            Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: cs.outlineVariant.withOpacity(0.4),
                    thumbColor: accentColor,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: onSeek != null
                        ? (v) => onSeek!(Duration(
                              milliseconds: (v * data.duration.inMilliseconds).round()))
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(data.position),
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.6))),
                      Text(formatDuration(data.duration),
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.shuffle, size: 22),
                  onPressed: () {},
                  color: cs.onSurface.withOpacity(0.6),
                ),
                IconButton(
                  icon: const Icon(Iconsax.previous, size: 36),
                  onPressed: onPrevious,
                  color: cs.onSurface,
                ),
                GestureDetector(
                  onTap: onPlayPause,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Icon(
                        data.isPlaying ? Iconsax.pause : Iconsax.play,
                        key: ValueKey(data.isPlaying),
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.next, size: 36),
                  onPressed: onNext,
                  color: cs.onSurface,
                ),
                IconButton(
                  icon: const Icon(Iconsax.repeat, size: 22),
                  onPressed: () {},
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
