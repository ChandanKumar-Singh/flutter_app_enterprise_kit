// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Column Definition ────────────────────────────────────────────────────────
class AppTableColumn<T> {
  final String key;
  final String label;
  final double? width;
  final bool sortable;
  final bool resizable;
  final TextAlign alignment;
  final Widget Function(BuildContext, T, int)? cellBuilder;
  final Comparable Function(T)? sortValue;

  const AppTableColumn({
    required this.key,
    required this.label,
    this.width,
    this.sortable = false,
    this.resizable = false,
    this.alignment = TextAlign.start,
    this.cellBuilder,
    this.sortValue,
  });
}

// ─── Sort State ───────────────────────────────────────────────────────────────
class _SortState {
  final String? columnKey;
  final bool ascending;

  const _SortState({this.columnKey, this.ascending = true});

  _SortState toggle(String key) {
    if (columnKey == key) return _SortState(columnKey: key, ascending: !ascending);
    return _SortState(columnKey: key, ascending: true);
  }
}

// ─── App Table ────────────────────────────────────────────────────────────────
class AppTable<T> extends StatefulWidget {
  final List<T> data;
  final List<AppTableColumn<T>> columns;
  final Widget Function(BuildContext, T, int)? rowBuilder;
  final String Function(T, AppTableColumn<T>)? cellText;
  final bool selectable;
  final void Function(Set<T>)? onSelectionChanged;
  final bool showHeader;
  final bool showRowNumbers;
  final bool striped;
  final bool bordered;
  final double? rowHeight;
  final Color? headerColor;
  final Color? stripedColor;
  final int? itemsPerPage;
  final bool showPagination;
  final Widget Function(T)? onRowTap;
  final void Function(T)? rowOnTap;
  final bool stickyHeader;
  final EdgeInsetsGeometry? padding;
  final String? emptyMessage;

  const AppTable({
    super.key,
    required this.data,
    required this.columns,
    this.rowBuilder,
    this.cellText,
    this.selectable = false,
    this.onSelectionChanged,
    this.showHeader = true,
    this.showRowNumbers = false,
    this.striped = true,
    this.bordered = true,
    this.rowHeight,
    this.headerColor,
    this.stripedColor,
    this.itemsPerPage = 20,
    this.showPagination = false,
    this.onRowTap,
    this.rowOnTap,
    this.stickyHeader = false,
    this.padding,
    this.emptyMessage,
  });

  @override
  State<AppTable<T>> createState() => _AppTableState<T>();
}

class _AppTableState<T> extends State<AppTable<T>> {
  _SortState _sort = const _SortState();
  Set<T> _selected = {};
  int _page = 0;

  List<T> get _sortedData {
    if (_sort.columnKey == null) return widget.data;
    final col = widget.columns.firstWhere(
      (c) => c.key == _sort.columnKey,
      orElse: () => widget.columns.first,
    );
    if (col.sortValue == null) return widget.data;
    final sorted = [...widget.data]..sort(
        (a, b) => col.sortValue!(a).compareTo(col.sortValue!(b)));
    return _sort.ascending ? sorted : sorted.reversed.toList();
  }

  List<T> get _pageData {
    final sorted = _sortedData;
    if (widget.itemsPerPage == null || !widget.showPagination) return sorted;
    final start = _page * widget.itemsPerPage!;
    final end = (start + widget.itemsPerPage!).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  int get _totalPages =>
      (widget.data.length / (widget.itemsPerPage ?? widget.data.length)).ceil();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget table = Column(
      children: [
        // Table
        Container(
          decoration: widget.bordered
              ? BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                )
              : null,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (widget.showHeader) _buildHeader(context, theme, cs),
                // Rows
                if (_pageData.isEmpty)
                  _buildEmpty(context, cs)
                else
                  ..._pageData.asMap().entries.map(
                        (e) => _buildRow(context, theme, cs, e.value, e.key),
                      ),
              ],
            ),
          ),
        ),
        // Pagination
        if (widget.showPagination && _totalPages > 1)
          _buildPagination(context, cs),
      ],
    );

    if (widget.padding != null) {
      table = Padding(padding: widget.padding!, child: table);
    }

    return table;
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Container(
      color: widget.headerColor ?? cs.surfaceVariant,
      child: Row(
        children: [
          if (widget.selectable)
            _HeaderCell(
              width: 48,
              child: Checkbox(
                value: _selected.length == widget.data.length &&
                    widget.data.isNotEmpty,
                tristate: _selected.isNotEmpty &&
                    _selected.length < widget.data.length,
                onChanged: (v) {
                  setState(() {
                    _selected = v == true ? Set.of(widget.data) : {};
                    widget.onSelectionChanged?.call(_selected);
                  });
                },
              ),
            ),
          if (widget.showRowNumbers)
            _HeaderCell(
              width: 48,
              child: Text('#',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ...widget.columns.map((col) => _HeaderCell(
                width: col.width ?? 120,
                onTap: col.sortable ? () => _onSort(col.key) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        col.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _sort.columnKey == col.key
                              ? cs.primary
                              : cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (col.sortable) ...[
                      const SizedBox(width: 4),
                      _sortIcon(col.key, cs),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRow(
      BuildContext context, ThemeData theme, ColorScheme cs, T item, int index) {
    final isSelected = _selected.contains(item);
    final isEven = index.isEven;

    return InkWell(
      onTap: () {
        widget.rowOnTap?.call(item);
        if (widget.selectable) {
          setState(() {
            if (isSelected) {
              _selected.remove(item);
            } else {
              _selected.add(item);
            }
            widget.onSelectionChanged?.call(_selected);
          });
        }
      },
      child: Container(
        color: isSelected
            ? cs.primaryContainer.withOpacity(0.3)
            : (widget.striped && isEven)
                ? (widget.stripedColor ?? cs.surfaceVariant.withOpacity(0.4))
                : Colors.transparent,
        child: Row(
          children: [
            if (widget.selectable)
              _DataCell(
                width: 48,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      v! ? _selected.add(item) : _selected.remove(item);
                      widget.onSelectionChanged?.call(_selected);
                    });
                  },
                ),
              ),
            if (widget.showRowNumbers)
              _DataCell(
                width: 48,
                child: Text(
                  '${_page * (widget.itemsPerPage ?? 0) + index + 1}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ...widget.columns.map((col) => _DataCell(
                  width: col.width ?? 120,
                  child: col.cellBuilder != null
                      ? col.cellBuilder!(context, item, index)
                      : Text(
                          widget.cellText?.call(item, col) ?? '',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                          textAlign: col.alignment,
                        ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          widget.emptyMessage ?? 'No data to display',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
          ),
          ...List.generate(
            _totalPages,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      _page == i ? cs.primary : cs.surfaceVariant,
                  foregroundColor:
                      _page == i ? cs.onPrimary : cs.onSurface,
                ),
                onPressed: () => setState(() => _page = i),
                child: Text('${i + 1}'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < _totalPages - 1
                ? () => setState(() => _page++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _sortIcon(String key, ColorScheme cs) {
    if (_sort.columnKey != key) {
      return Icon(Icons.unfold_more, size: 14, color: cs.onSurfaceVariant);
    }
    return Icon(
      _sort.ascending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      size: 14,
      color: cs.primary,
    );
  }

  void _onSort(String key) => setState(() => _sort = _sort.toggle(key));
}

// ─── Cell helpers ─────────────────────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final double width;
  final Widget child;
  final VoidCallback? onTap;

  const _HeaderCell({required this.width, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final double width;
  final Widget child;

  const _DataCell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: child,
      ),
    );
  }
}
