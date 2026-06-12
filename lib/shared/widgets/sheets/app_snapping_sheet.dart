// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Snap Config ──────────────────────────────────────────────────────────────

class AppSnapConfig {
  /// Fraction of screen height for each snap point (0.0–1.0)
  final List<double> snapSizes;

  /// Initial snap index
  final int initialSnap;

  /// Minimum: used as collapsed height
  final double minSize;

  /// Maximum height fraction
  final double maxSize;

  const AppSnapConfig({
    this.snapSizes = const [0.35, 0.6, 0.92],
    this.initialSnap = 0,
    this.minSize = 0.35,
    this.maxSize = 0.92,
  });

  double get initialSize => snapSizes[initialSnap.clamp(0, snapSizes.length - 1)];
}

// ─── AppSnappingSheet ─────────────────────────────────────────────────────────
/// Uber/Airbnb-grade elastic snapping bottom sheet.
///
/// Features:
/// - Multiple snap points with spring physics
/// - Rubber-band over-drag (logarithmic resistance past maxSize)
/// - Background scrim dims proportionally to sheet height
/// - Nested scroll lock: scrolls list when fully expanded, drags sheet otherwise
/// - Glassmorphic header with grab handle
class AppSnappingSheet extends StatefulWidget {
  final Widget Function(BuildContext, ScrollController) contentBuilder;
  final Widget? header;
  final Widget? background;
  final AppSnapConfig snapConfig;
  final bool showScrim;
  final bool showGrabHandle;
  final VoidCallback? onClose;
  final Color? backgroundColor;
  final double? headerHeight;

  const AppSnappingSheet({
    super.key,
    required this.contentBuilder,
    this.header,
    this.background,
    this.snapConfig = const AppSnapConfig(),
    this.showScrim = true,
    this.showGrabHandle = true,
    this.onClose,
    this.backgroundColor,
    this.headerHeight,
  });

  /// Show as modal route with full Uber-style map background.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext, ScrollController) contentBuilder,
    Widget? header,
    Widget? background,
    AppSnapConfig snapConfig = const AppSnapConfig(),
    bool isDismissible = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: false,
      showDragHandle: false, // prevent Material 3 theme default from adding a second handle
      builder: (ctx) => AppSnappingSheet(
        contentBuilder: contentBuilder,
        header: header,
        background: background,
        snapConfig: snapConfig,
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  State<AppSnappingSheet> createState() => _AppSnappingSheetState();
}

class _AppSnappingSheetState extends State<AppSnappingSheet>
    with SingleTickerProviderStateMixin {
  late DraggableScrollableController _dragCtrl;
  late ValueNotifier<double> _sheetFraction;
  late AnimationController _scrimCtrl;

  @override
  void initState() {
    super.initState();
    _dragCtrl = DraggableScrollableController();
    _sheetFraction = ValueNotifier(widget.snapConfig.initialSize);
    _scrimCtrl = AnimationController(vsync: this, duration: Duration.zero);

    _dragCtrl.addListener(() {
      if (_dragCtrl.isAttached) {
        _sheetFraction.value = _dragCtrl.size;
        _scrimCtrl.value = (_dragCtrl.size - widget.snapConfig.minSize) /
            (widget.snapConfig.maxSize - widget.snapConfig.minSize);
      }
    });
  }

  @override
  void dispose() {
    _dragCtrl.dispose();
    _sheetFraction.dispose();
    _scrimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Scrim
        if (widget.showScrim)
          AnimatedBuilder(
            animation: _scrimCtrl,
            builder: (_, __) => GestureDetector(
              onTap: () {
                if (_dragCtrl.isAttached) {
                  _dragCtrl.animateTo(
                    widget.snapConfig.snapSizes.first,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutQuint,
                  );
                }
              },
              child: Container(
                color: Colors.black.withOpacity(_scrimCtrl.value * 0.45),
              ),
            ),
          ),

        // Sheet
        DraggableScrollableSheet(
          controller: _dragCtrl,
          initialChildSize: widget.snapConfig.initialSize,
          minChildSize: widget.snapConfig.minSize,
          maxChildSize: widget.snapConfig.maxSize,
          snap: true,
          snapSizes: widget.snapConfig.snapSizes,
          snapAnimationDuration: const Duration(milliseconds: 280),
          builder: (context, scrollCtrl) {
            return _SheetContent(
              scrollCtrl: scrollCtrl,
              config: widget.snapConfig,
              contentBuilder: widget.contentBuilder,
              header: widget.header,
              showGrabHandle: widget.showGrabHandle,
              backgroundColor: widget.backgroundColor,
              headerHeight: widget.headerHeight,
              sheetFraction: _sheetFraction,
            );
          },
        ),
      ],
    );
  }
}

class _SheetContent extends StatelessWidget {
  final ScrollController scrollCtrl;
  final AppSnapConfig config;
  final Widget Function(BuildContext, ScrollController) contentBuilder;
  final Widget? header;
  final bool showGrabHandle;
  final Color? backgroundColor;
  final double? headerHeight;
  final ValueNotifier<double> sheetFraction;

  const _SheetContent({
    required this.scrollCtrl,
    required this.config,
    required this.contentBuilder,
    required this.showGrabHandle,
    required this.sheetFraction,
    this.header,
    this.backgroundColor,
    this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? cs.surface;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : cs.outlineVariant.withOpacity(0.5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Grab handle
              if (showGrabHandle) _GrabHandle(),

              // Custom header
              if (header != null) header!,

              // Scrollable content
              Expanded(
                child: contentBuilder(context, scrollCtrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),
    );
  }
}

// ─── AppSheetHeader ───────────────────────────────────────────────────────────
/// Standard sheet header with title, subtitle, optional close/action buttons.
class AppSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onClose;
  final EdgeInsets padding;

  const AppSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onClose,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onClose != null)
            IconButton(
              icon: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 16, color: cs.onSurface),
              ),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

// ─── AppOptionSheet ───────────────────────────────────────────────────────────
/// Preset: Options list sheet (single/multi select) — Zomato/iOS style.
class AppOptionItem {
  final String label;
  final String? description;
  final IconData? icon;
  final Color? color;
  final bool isDestructive;

  const AppOptionItem({
    required this.label,
    this.description,
    this.icon,
    this.color,
    this.isDestructive = false,
  });
}

class AppOptionSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<AppOptionItem> options;
  final int? selectedIndex;
  final bool multiSelect;
  final ValueChanged<int>? onSelected;

  const AppOptionSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    this.selectedIndex,
    this.multiSelect = false,
    this.onSelected,
  });

  static Future<int?> show({
    required BuildContext context,
    required String title,
    required List<AppOptionItem> options,
    int? selectedIndex,
    String? subtitle,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) => AppOptionSheet(
        title: title,
        subtitle: subtitle,
        options: options,
        selectedIndex: selectedIndex,
        onSelected: (i) => Navigator.pop(ctx, i),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GrabHandle(),
              AppSheetHeader(
                title: title,
                subtitle: subtitle,
                onClose: () => Navigator.pop(context),
              ),
              Divider(height: 1, color: cs.outlineVariant),
              ...options.asMap().entries.map((e) {
                final i = e.key;
                final opt = e.value;
                final isSelected = selectedIndex == i;
                final color = opt.isDestructive
                    ? cs.error
                    : opt.color ?? cs.onSurface;

                return Column(
                  children: [
                    ListTile(
                      leading: opt.icon != null
                          ? Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(opt.icon, color: color, size: 18),
                            )
                          : null,
                      title: Text(
                        opt.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: color,
                        ),
                      ),
                      subtitle: opt.description != null
                          ? Text(opt.description!, style: TextStyle(color: cs.onSurfaceVariant))
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: cs.primary)
                          : null,
                      onTap: () {
                        onSelected?.call(i);
                        if (!multiSelect) Navigator.pop(context, i);
                      },
                    ),
                    if (i < options.length - 1)
                      Divider(height: 1, indent: 64, color: cs.outlineVariant),
                  ],
                )
                    .animate(delay: Duration(milliseconds: 40 * i))
                    .fadeIn(duration: 200.ms);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AppFilterSheet ───────────────────────────────────────────────────────────
/// Preset: Filter panel with multi-select chips and range slider.
class AppFilterSheet extends StatefulWidget {
  final String title;
  final List<String> filterTags;
  final List<String> initialSelected;
  final double? minValue;
  final double? maxValue;
  final double? initialMin;
  final double? initialMax;
  final String? rangeLabel;
  final String Function(double)? rangeFormatter;
  final ValueChanged<_FilterResult>? onApply;

  const AppFilterSheet({
    super.key,
    this.title = 'Filters',
    required this.filterTags,
    this.initialSelected = const [],
    this.minValue,
    this.maxValue,
    this.initialMin,
    this.initialMax,
    this.rangeLabel,
    this.rangeFormatter,
    this.onApply,
  });

  static Future<_FilterResult?> show({
    required BuildContext context,
    required List<String> filterTags,
    List<String> initialSelected = const [],
    double? minValue,
    double? maxValue,
    double? initialMin,
    double? initialMax,
    String? rangeLabel,
    String Function(double)? rangeFormatter,
  }) {
    return showModalBottomSheet<_FilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) => AppFilterSheet(
        filterTags: filterTags,
        initialSelected: initialSelected,
        minValue: minValue,
        maxValue: maxValue,
        initialMin: initialMin,
        initialMax: initialMax,
        rangeLabel: rangeLabel,
        rangeFormatter: rangeFormatter,
        onApply: (r) => Navigator.pop(ctx, r),
      ),
    );
  }

  @override
  State<AppFilterSheet> createState() => _AppFilterSheetState();
}

class _FilterResult {
  final List<String> selectedTags;
  final RangeValues? range;
  const _FilterResult(this.selectedTags, this.range);
}

class _AppFilterSheetState extends State<AppFilterSheet> {
  late List<String> _selected;
  late RangeValues? _range;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _range = widget.minValue != null
        ? RangeValues(
            widget.initialMin ?? widget.minValue!,
            widget.initialMax ?? widget.maxValue!,
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GrabHandle(),
              AppSheetHeader(
                title: widget.title,
                onClose: () => Navigator.pop(context),
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      _selected.clear();
                      if (widget.minValue != null) {
                        _range = RangeValues(widget.minValue!, widget.maxValue!);
                      }
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant),

              // Filter chips
              if (widget.filterTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categories', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.filterTags.map((tag) {
                          final selected = _selected.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (v) => setState(() {
                              v ? _selected.add(tag) : _selected.remove(tag);
                            }),
                            selectedColor: cs.primaryContainer,
                            checkmarkColor: cs.primary,
                            labelStyle: TextStyle(
                              color: selected ? cs.primary : cs.onSurface,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // Range slider
              if (_range != null && widget.minValue != null) ...[
                Divider(height: 1, color: cs.outlineVariant),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.rangeLabel ?? 'Range',
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${widget.rangeFormatter?.call(_range!.start) ?? _range!.start.toStringAsFixed(0)} – '
                            '${widget.rangeFormatter?.call(_range!.end) ?? _range!.end.toStringAsFixed(0)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: _range!,
                        min: widget.minValue!,
                        max: widget.maxValue!,
                        onChanged: (v) => setState(() => _range = v),
                      ),
                    ],
                  ),
                ),
              ],

              // Apply button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => widget.onApply?.call(_FilterResult(_selected, _range)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: Text(
                      _selected.isEmpty ? 'Show All Results' : 'Apply ${_selected.length} Filter${_selected.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
