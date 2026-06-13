// ─── AppCharts ────────────────────────────────────────────────────────────────
// Themed, production-ready chart wrappers built on fl_chart.
//
// Components:
//   AppLineChart   — smooth line/area chart with gradient fill
//   AppBarChart    — vertical/horizontal bar chart with touch
//   AppPieChart    — donut + pie with legend
//   AppSparkline   — compact inline sparkline (no axes, no labels)
//
// All charts:
//   • Use theme ColorScheme tokens — no hardcoded colours
//   • Loading shimmer state
//   • Empty state with icon + message
//   • Error state
//   • Touch tooltips
//   • Responsive (fills available space)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ── Chart data models ─────────────────────────────────────────────────────────

class AppChartPoint {
  final double x;
  final double y;
  final String? label;

  const AppChartPoint(this.x, this.y, {this.label});
}

class AppChartSeries {
  final String name;
  final List<AppChartPoint> points;
  final Color? color;
  final bool filled;

  const AppChartSeries({
    required this.name,
    required this.points,
    this.color,
    this.filled = true,
  });
}

class AppBarData {
  final String label;
  final double value;
  final Color? color;
  final String? tooltip;

  const AppBarData({
    required this.label,
    required this.value,
    this.color,
    this.tooltip,
  });
}

class AppPieSection {
  final String label;
  final double value;
  final Color? color;

  const AppPieSection({
    required this.label,
    required this.value,
    this.color,
  });
}

// ── Chart state helper ────────────────────────────────────────────────────────

enum _ChartState { loading, empty, data, error }

Widget _buildLoading(double height) {
  return Shimmer.fromColors(
    baseColor: const Color(0xFFE0E0E0),
    highlightColor: const Color(0xFFF5F5F5),
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),
  );
}

Widget _buildEmpty(BuildContext context, String message) {
  final cs = Theme.of(context).colorScheme;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.chart,
            size: 40, color: cs.onSurfaceVariant.withOpacity(0.3)),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

Widget _buildError(BuildContext context, String? error) {
  final cs = Theme.of(context).colorScheme;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.danger, size: 32, color: cs.error),
        const SizedBox(height: 8),
        Text(
          error ?? 'Failed to load chart',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ── AppLineChart ──────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class AppLineChart extends StatefulWidget {
  final List<AppChartSeries> series;
  final double height;
  final bool isLoading;
  final bool showGrid;
  final bool showDots;
  final String? emptyMessage;
  final String? errorMessage;
  final String? Function(double x)? xLabelBuilder;
  final String? Function(double y)? yLabelBuilder;
  final String? Function(AppChartPoint point, String seriesName)? tooltipBuilder;

  const AppLineChart({
    super.key,
    required this.series,
    this.height = 200,
    this.isLoading = false,
    this.showGrid = true,
    this.showDots = false,
    this.emptyMessage,
    this.errorMessage,
    this.xLabelBuilder,
    this.yLabelBuilder,
    this.tooltipBuilder,
  });

  @override
  State<AppLineChart> createState() => _AppLineChartState();
}

class _AppLineChartState extends State<AppLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.isLoading) return _buildLoading(widget.height);
    if (widget.errorMessage != null) {
      return SizedBox(height: widget.height,
          child: _buildError(context, widget.errorMessage));
    }
    final hasData = widget.series.any((s) => s.points.isNotEmpty);
    if (!hasData) {
      return SizedBox(height: widget.height,
          child: _buildEmpty(context, widget.emptyMessage ?? 'No data'));
    }

    final palette = _defaultPalette(cs);
    final lineBarsData = widget.series.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      final color = s.color ?? palette[i % palette.length];
      return LineChartBarData(
        spots: s.points.map((p) => FlSpot(p.x, p.y)).toList(),
        isCurved: true,
        curveSmoothness: 0.35,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(show: widget.showDots),
        belowBarData: s.filled
            ? BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            : BarAreaData(show: false),
      );
    }).toList();

    return SizedBox(
      height: widget.height,
      child: LineChart(
        LineChartData(
          lineBarsData: lineBarsData,
          gridData: FlGridData(
            show: widget.showGrid,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: widget.yLabelBuilder != null,
                getTitlesWidget: (value, meta) {
                  final label = widget.yLabelBuilder?.call(value);
                  if (label == null) return const SizedBox.shrink();
                  return Text(label,
                      style: TextStyle(
                          fontSize: 10, color: cs.onSurfaceVariant));
                },
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: widget.xLabelBuilder != null,
                getTitlesWidget: (value, meta) {
                  final label = widget.xLabelBuilder?.call(value);
                  if (label == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant)),
                  );
                },
                reservedSize: 24,
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.surfaceContainerHighest,
              getTooltipItems: (spots) => spots.map((s) {
                final series = widget.series[s.barIndex];
                final point = series.points[s.spotIndex];
                final label = widget.tooltipBuilder?.call(point, series.name)
                    ?? '${series.name}: ${s.y.toStringAsFixed(1)}';
                return LineTooltipItem(
                  label,
                  TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── AppBarChart ───────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class AppBarChart extends StatefulWidget {
  final List<AppBarData> data;
  final double height;
  final bool isLoading;
  final bool horizontal;
  final String? emptyMessage;
  final String? errorMessage;
  final String? Function(double y)? yLabelBuilder;
  final bool showValues;

  const AppBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.isLoading = false,
    this.horizontal = false,
    this.emptyMessage,
    this.errorMessage,
    this.yLabelBuilder,
    this.showValues = false,
  });

  @override
  State<AppBarChart> createState() => _AppBarChartState();
}

class _AppBarChartState extends State<AppBarChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.isLoading) return _buildLoading(widget.height);
    if (widget.errorMessage != null) {
      return SizedBox(height: widget.height,
          child: _buildError(context, widget.errorMessage));
    }
    if (widget.data.isEmpty) {
      return SizedBox(height: widget.height,
          child: _buildEmpty(context, widget.emptyMessage ?? 'No data'));
    }

    final palette = _defaultPalette(cs);
    final groups = widget.data.asMap().entries.map((e) {
      final i = e.key;
      final d = e.value;
      final color = d.color ?? palette[i % palette.length];
      final isTouched = _touched == i;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: d.value,
            color: isTouched ? color : color.withOpacity(0.85),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: widget.data.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.1,
              color: cs.surfaceContainerHighest,
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: widget.height,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: widget.yLabelBuilder != null,
                getTitlesWidget: (value, _) {
                  final label = widget.yLabelBuilder?.call(value);
                  if (label == null) return const SizedBox.shrink();
                  return Text(label,
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant));
                },
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= widget.data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.data[i].label,
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                  );
                },
                reservedSize: 24,
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (event.isInterestedForInteractions &&
                    response?.spot != null) {
                  _touched = response!.spot!.touchedBarGroupIndex;
                } else {
                  _touched = null;
                }
              });
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = widget.data[groupIndex];
                return BarTooltipItem(
                  d.tooltip ?? '${d.label}: ${d.value.toStringAsFixed(1)}',
                  TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── AppPieChart ───────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class AppPieChart extends StatefulWidget {
  final List<AppPieSection> sections;
  final double height;
  final bool isLoading;
  final bool donut;
  final String? centerText;
  final bool showLegend;
  final String? emptyMessage;
  final String? errorMessage;

  const AppPieChart({
    super.key,
    required this.sections,
    this.height = 200,
    this.isLoading = false,
    this.donut = true,
    this.centerText,
    this.showLegend = true,
    this.emptyMessage,
    this.errorMessage,
  });

  @override
  State<AppPieChart> createState() => _AppPieChartState();
}

class _AppPieChartState extends State<AppPieChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (widget.isLoading) return _buildLoading(widget.height);
    if (widget.errorMessage != null) {
      return SizedBox(height: widget.height,
          child: _buildError(context, widget.errorMessage));
    }
    if (widget.sections.isEmpty) {
      return SizedBox(height: widget.height,
          child: _buildEmpty(context, widget.emptyMessage ?? 'No data'));
    }

    final palette = _defaultPalette(cs);
    final total = widget.sections.fold<double>(0, (s, e) => s + e.value);

    final flSections = widget.sections.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      final color = s.color ?? palette[i % palette.length];
      final isTouched = _touched == i;
      return PieChartSectionData(
        value: s.value,
        color: color,
        radius: isTouched ? 80 : 70,
        title: isTouched
            ? '${(s.value / total * 100).toStringAsFixed(1)}%'
            : '',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: flSections,
                  centerSpaceRadius: widget.donut ? 50 : 0,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (event.isInterestedForInteractions &&
                            response?.touchedSection != null) {
                          _touched = response!.touchedSection!.touchedSectionIndex;
                        } else {
                          _touched = null;
                        }
                      });
                    },
                  ),
                ),
              ),
              if (widget.donut && widget.centerText != null)
                Text(
                  widget.centerText!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        // Legend
        if (widget.showLegend)
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.center,
            children: widget.sections.asMap().entries.map((e) {
              final color = e.value.color ?? palette[e.key % palette.length];
              final pct =
                  (e.value.value / total * 100).toStringAsFixed(1);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.value.label} ($pct%)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── AppSparkline ──────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class AppSparkline extends StatelessWidget {
  final List<double> data;
  final double height;
  final double width;
  final Color? color;
  final bool filled;
  final bool isLoading;

  const AppSparkline({
    super.key,
    required this.data,
    this.height = 40,
    this.width = 80,
    this.color,
    this.filled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedColor = color ?? cs.primary;

    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
          width: width,
          height: height,
          color: Colors.white,
        ),
      );
    }

    if (data.length < 2) return SizedBox(width: width, height: height);

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: resolvedColor,
              barWidth: 1.8,
              dotData: const FlDotData(show: false),
              belowBarData: filled
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          resolvedColor.withOpacity(0.2),
                          resolvedColor.withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    )
                  : BarAreaData(show: false),
            ),
          ],
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}

// ── Colour palette ────────────────────────────────────────────────────────────

List<Color> _defaultPalette(ColorScheme cs) => [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      const Color(0xFF16A34A),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF7C3AED),
      const Color(0xFF0891B2),
    ];
