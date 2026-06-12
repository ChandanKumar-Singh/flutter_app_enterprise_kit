// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Timeline Item Model ──────────────────────────────────────────────────────
enum AppTimelineStatus { completed, active, pending, error, warning }

class AppTimelineItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? date;
  final String? time;
  final AppTimelineStatus status;
  final Widget? icon;
  final Color? color;
  final Widget? content;
  final bool isFirst;
  final bool isLast;

  const AppTimelineItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.date,
    this.time,
    this.status = AppTimelineStatus.pending,
    this.icon,
    this.color,
    this.content,
    this.isFirst = false,
    this.isLast = false,
  });
}

// ─── App Timeline ─────────────────────────────────────────────────────────────
class AppTimeline extends StatelessWidget {
  final List<AppTimelineItem> items;
  final bool animated;
  final bool showConnector;
  final double nodeSize;
  final double connectorWidth;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext, AppTimelineItem)? nodeBuilder;
  final Widget Function(BuildContext, AppTimelineItem)? contentBuilder;

  const AppTimeline({
    super.key,
    required this.items,
    this.animated = true,
    this.showConnector = true,
    this.nodeSize = 36,
    this.connectorWidth = 2,
    this.padding,
    this.nodeBuilder,
    this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final isLast = i == items.length - 1;
        Widget tile = _TimelineTile(
          item: item,
          isLast: isLast,
          showConnector: showConnector,
          nodeSize: nodeSize,
          connectorWidth: connectorWidth,
          nodeBuilder: nodeBuilder,
          contentBuilder: contentBuilder,
        );
        if (animated) {
          tile = tile
              .animate(delay: (i * 60).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.1, end: 0, duration: 300.ms);
        }
        return tile;
      },
    );
  }
}

// ─── Timeline Tile ────────────────────────────────────────────────────────────
class _TimelineTile extends StatelessWidget {
  final AppTimelineItem item;
  final bool isLast;
  final bool showConnector;
  final double nodeSize;
  final double connectorWidth;
  final Widget Function(BuildContext, AppTimelineItem)? nodeBuilder;
  final Widget Function(BuildContext, AppTimelineItem)? contentBuilder;

  const _TimelineTile({
    required this.item,
    required this.isLast,
    required this.showConnector,
    required this.nodeSize,
    required this.connectorWidth,
    this.nodeBuilder,
    this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final config = _statusConfig(item.status, cs);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: node + connector
          SizedBox(
            width: nodeSize + 16,
            child: Column(
              children: [
                // Node
                nodeBuilder?.call(context, item) ??
                    Container(
                      width: nodeSize,
                      height: nodeSize,
                      decoration: BoxDecoration(
                        color: item.color ?? config.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: (item.color ?? config.color).withOpacity(0.3),
                            width: 3),
                        boxShadow: item.status == AppTimelineStatus.active
                            ? [
                                BoxShadow(
                                  color: (item.color ?? config.color)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: item.icon ??
                          Icon(config.icon, size: 18, color: Colors.white),
                    ),
                // Connector line
                if (!isLast && showConnector)
                  Expanded(
                    child: Container(
                      width: connectorWidth,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            item.color ?? config.color,
                            (item.color ?? config.color).withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right column: content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: contentBuilder?.call(context, item) ??
                  _DefaultContent(item: item, theme: theme, cs: cs),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultContent extends StatelessWidget {
  final AppTimelineItem item;
  final ThemeData theme;
  final ColorScheme cs;

  const _DefaultContent({
    required this.item,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: item.status == AppTimelineStatus.active
                      ? cs.primary
                      : cs.onSurface,
                ),
              ),
            ),
            if (item.date != null || item.time != null)
              Text(
                item.date ?? item.time ?? '',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
        if (item.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            item.subtitle!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        if (item.content != null) ...[
          const SizedBox(height: 8),
          item.content!,
        ],
      ],
    );
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;

  const _StatusConfig({required this.color, required this.icon});
}

_StatusConfig _statusConfig(AppTimelineStatus status, ColorScheme cs) =>
    switch (status) {
      AppTimelineStatus.completed => _StatusConfig(
          color: const Color(0xFF16A34A), icon: Icons.check_rounded),
      AppTimelineStatus.active => _StatusConfig(
          color: cs.primary, icon: Icons.radio_button_checked_rounded),
      AppTimelineStatus.error => _StatusConfig(
          color: cs.error, icon: Icons.close_rounded),
      AppTimelineStatus.warning => _StatusConfig(
          color: const Color(0xFFD97706), icon: Icons.warning_rounded),
      _ => _StatusConfig(
          color: cs.onSurfaceVariant, icon: Icons.radio_button_unchecked_rounded),
    };
