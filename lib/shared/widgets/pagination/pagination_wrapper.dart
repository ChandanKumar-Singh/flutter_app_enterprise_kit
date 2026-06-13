import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/loaders/app_shimmer.dart';
import 'package:enterprise_kit/shared/widgets/states/app_state_widget.dart';
import 'package:enterprise_kit/core/debug/app_logger.dart';

typedef FetchPage<T> = Future<List<T>> Function(int page, int pageSize);

typedef ItemBuilder<T> = Widget Function(
  BuildContext context,
  List<T> items,
  bool isLoadingMore,
  ScrollController scrollController,
);

/// A premium, robust pagination controller to manage paging, filtering, scrolling,
/// and resets from outside the widget.
class PaginationController<T> extends ChangeNotifier {
  VoidCallback? _refreshCallback;
  VoidCallback? _scrollToTopCallback;
  void Function(List<T> Function(List<T>))? _updateFilterCallback;
  List<T> Function(List<T>)? _currentFilter;

  void _bind({
    required VoidCallback refresh,
    required VoidCallback scrollToTop,
    required void Function(List<T> Function(List<T>)) updateFilter,
  }) {
    _refreshCallback = refresh;
    _scrollToTopCallback = scrollToTop;
    _updateFilterCallback = updateFilter;
    if (_currentFilter != null) {
      _updateFilterCallback?.call(_currentFilter!);
    }
  }

  /// Programmatically trigger a full pull-to-refresh reload.
  void refresh() => _refreshCallback?.call();

  /// Animate the bound scroll controller to the top of the viewport.
  void scrollToTop() => _scrollToTopCallback?.call();

  /// Apply a reactive filter function to the current list of items.
  /// Matches can be dynamically searched or sorted.
  void updateFilteredList(List<T> Function(List<T>) filterFn) {
    _currentFilter = filterFn;
    _updateFilterCallback?.call(filterFn);
  }

  /// Remove any active search/filter rules and restore the full loaded list.
  void clearFilter() {
    _currentFilter = null;
    _updateFilterCallback?.call((items) => items);
  }
}

/// A highly polished, smooth, and flexible pagination wrapper.
/// Takes a fetch callback, manages page counters, handles pull-to-refresh,
/// and triggers seamless load-more events with momentum scroll optimizations.
class PaginationWrapper<T> extends StatefulWidget {
  final FetchPage<T> fetchData;
  final ItemBuilder<T> builder;
  final PaginationController<T>? controller;
  final List<T>? initialData;
  final void Function(List<T> allItems, List<T> newItems)? onData;
  final int pageSize;
  final double triggerOffset;
  final bool debugMode;

  final Widget? initialLoadingWidget;
  final Widget? emptyWidget;
  final Widget Function(Future<void> retryFuture)? errorWidget;
  final Widget? loadMoreWidget;

  final Future<void> Function()? onRefresh;
  final void Function(int currentPage)? onLoadMore;

  /// External constraint configuration to toggle if pagination has more data.
  final bool enableHasMore;

  const PaginationWrapper({
    super.key,
    required this.fetchData,
    required this.builder,
    this.controller,
    this.initialData,
    this.pageSize = 20,
    this.triggerOffset = 100,
    this.initialLoadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.loadMoreWidget,
    this.onRefresh,
    this.onData,
    this.onLoadMore,
    this.debugMode = false,
    this.enableHasMore = true,
  });

  /// Convenience factory constructor that builds standard list view layouts
  /// with pre-baked divider and configuration structures.
  factory PaginationWrapper.builder({
    Key? key,
    required FetchPage<T> fetchData,
    required Widget Function(BuildContext context, T item) itemBuilder,
    PaginationController<T>? controller,
    List<T>? initialData,
    int pageSize = 20,
    Widget? loadingWidget,
    Widget? emptyWidget,
    Widget Function(Future<void> retryFuture)? errorWidget,
    Widget? loadMoreWidget,
    Future<void> Function()? onRefresh,
    void Function(int currentPage)? onLoadMore,
    bool debugMode = false,

    // Extra customization
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    bool separated = false,
    Widget Function(BuildContext, int)? separatorBuilder,
    ScrollPhysics? physics,
    bool enableHasMore = true,
  }) {
    return PaginationWrapper<T>(
      key: key,
      fetchData: fetchData,
      controller: controller,
      initialData: initialData,
      pageSize: pageSize,
      initialLoadingWidget: loadingWidget,
      emptyWidget: emptyWidget,
      errorWidget: errorWidget,
      loadMoreWidget: loadMoreWidget,
      onRefresh: onRefresh,
      onLoadMore: onLoadMore,
      debugMode: debugMode,
      enableHasMore: enableHasMore,
      builder: (
        BuildContext context,
        List<T> items,
        bool loadingMore,
        ScrollController scrollController,
      ) {
        final totalCount = items.length + (loadingMore ? 1 : 0);

        if (separated && separatorBuilder != null) {
          return ListView.separated(
            controller: scrollController,
            padding: padding,
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: totalCount,
            separatorBuilder: separatorBuilder,
            itemBuilder: (context, index) {
              if (index == items.length) {
                return loadMoreWidget ?? _DefaultLoadMoreWidget();
              }
              return itemBuilder(context, items[index]);
            },
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (index == items.length) {
              return loadMoreWidget ?? _DefaultLoadMoreWidget();
            }
            return itemBuilder(context, items[index]);
          },
        );
      },
    );
  }

  @override
  State<PaginationWrapper<T>> createState() => _PaginationWrapperState<T>();
}

class _PaginationWrapperState<T> extends State<PaginationWrapper<T>> {
  final List<T> _items = [];
  List<T>? _filteredList;
  int _currentPage = 1;

  bool _isInitialLoadingRunning = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _hasLoadMoreError = false;

  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      _items.addAll(widget.initialData!);
      _isInitialLoading = false;
      _isInitialLoadingRunning = false;
    }

    widget.controller?._bind(
      refresh: _refresh,
      scrollToTop: _scrollToTop,
      updateFilter: (List<T> Function(List<T>) filterFn) {
        setState(() {
          _filteredList = filterFn(_items);
        });
      },
    );

    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialData == null) {
        _loadInitialData();
      }
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleScroll() {
    if (!_hasMore || _isLoadingMore || _isInitialLoadingRunning || _hasError || _hasLoadMoreError) {
      return;
    }

    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Trigger load more when user scrolls past the threshold offset
    // (We removed strict scroll direction checks so momentum/deceleration triggers work smoothly)
    if (currentScroll >= (maxScroll - widget.triggerOffset)) {
      _loadMoreData();
    }
  }

  Future<void> _refresh([bool showSpinner = true]) async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!.call();
    }
    await _loadInitialData(showSpinner);
  }

  Future<void> _loadInitialData([bool showSpinner = true]) async {
    setState(() {
      _isInitialLoadingRunning = true;
      _isInitialLoading = showSpinner;
      _hasError = false;
      _currentPage = 1;
      _hasMore = true;
      _hasLoadMoreError = false;
    });

    try {
      final data = await widget.fetchData(1, widget.pageSize);
      AppLogger.instance.d('PaginationWrapper: Loaded initial page (count: ${data.length})');

      setState(() {
        _items.clear();
        _items.addAll(data);
        _filteredList = null;

        widget.onData?.call(_items, data);

        if (widget.enableHasMore) {
          _hasMore = data.length >= widget.pageSize;
        }
        if (data.isNotEmpty) {
          _currentPage++;
        }
      });
    } catch (e, st) {
      AppLogger.instance.e('PaginationWrapper: Failed to load initial data', error: e, stackTrace: st);
      setState(() => _hasError = true);
    } finally {
      setState(() {
        _isInitialLoading = false;
        _isInitialLoadingRunning = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMore || _isLoadingMore || _isInitialLoadingRunning) return;

    setState(() {
      _isLoadingMore = true;
      _hasLoadMoreError = false;
    });

    try {
      final data = await widget.fetchData(_currentPage, widget.pageSize);
      AppLogger.instance.d('PaginationWrapper: Loaded page $_currentPage (count: ${data.length})');

      setState(() {
        _items.addAll(data);
        _filteredList = null;

        widget.onData?.call(_items, data);
        widget.onLoadMore?.call(_currentPage);

        if (widget.enableHasMore) {
          if (data.isEmpty) {
            _hasMore = false;
          } else {
            _currentPage++;
            _hasMore = data.length >= widget.pageSize;
          }
        } else {
          if (data.isNotEmpty) {
            _currentPage++;
          }
        }
      });
    } catch (e, st) {
      AppLogger.instance.e('PaginationWrapper: Failed to load page $_currentPage', error: e, stackTrace: st);
      setState(() => _hasLoadMoreError = true);
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  List<T> get _displayList => _filteredList ?? _items;

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return widget.initialLoadingWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppShimmer.list(count: 6),
            ),
          );
    }

    if (_hasError) {
      return widget.errorWidget?.call(_loadInitialData()) ??
          AppStateWidget.error(
            onRetry: _loadInitialData,
          );
    }

    if (_displayList.isEmpty) {
      return widget.emptyWidget ?? AppStateWidget.empty();
    }

    final listContent = widget.builder(
      context,
      _displayList,
      _isLoadingMore,
      _scrollController,
    );

    Widget mainContent;
    if (_hasLoadMoreError) {
      // If load more fails, display an inline retry strip at the bottom of the list widget
      mainContent = Column(
        children: [
          Expanded(child: listContent),
          _LoadMoreRetryBar(onRetry: _loadMoreData),
        ],
      );
    } else {
      mainContent = listContent;
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(false),
      child: Column(
        children: [
          if (widget.debugMode) _DebugOverlay(
            isLoadingMore: _isLoadingMore,
            totalItems: _items.length,
            currentPage: _currentPage - 1,
            hasMore: _hasMore,
          ),
          Expanded(child: mainContent),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _DefaultLoadMoreWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _LoadMoreRetryBar extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadMoreRetryBar({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.errorContainer.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Failed to load next page',
              style: TextStyle(color: colors.onErrorContainer, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Iconsax.refresh, size: 16, color: colors.error),
            label: Text(
              'Retry',
              style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugOverlay extends StatelessWidget {
  final bool isLoadingMore;
  final int totalItems;
  final int currentPage;
  final bool hasMore;

  const _DebugOverlay({
    required this.isLoadingMore,
    required this.totalItems,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest ?? colors.surfaceVariant.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: colors.outlineVariant.withOpacity(0.3))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: Text(
        'Loading: $isLoadingMore | Total: $totalItems | Page: $currentPage | hasMore: $hasMore',
        style: TextStyle(
          color: colors.onSurfaceVariant.withOpacity(0.8),
          fontSize: 11,
          fontFamily: 'monospace',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
