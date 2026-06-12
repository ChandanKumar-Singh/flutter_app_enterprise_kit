import 'package:flutter/material.dart';
import 'package:enterprise_kit/shared/widgets/loaders/app_shimmer.dart';
import 'package:enterprise_kit/shared/widgets/states/app_state_widget.dart';

// ─── Pagination State ─────────────────────────────────────────────────────────
enum AppPaginatorStatus { idle, loading, loadingMore, refreshing, error, empty, complete }

class AppPaginatorState<T> {
  final List<T> items;
  final AppPaginatorStatus status;
  final String? error;
  final int page;
  final bool hasMore;

  const AppPaginatorState({
    this.items = const [],
    this.status = AppPaginatorStatus.idle,
    this.error,
    this.page = 0,
    this.hasMore = true,
  });

  bool get isLoading => status == AppPaginatorStatus.loading;
  bool get isLoadingMore => status == AppPaginatorStatus.loadingMore;
  bool get isRefreshing => status == AppPaginatorStatus.refreshing;
  bool get isError => status == AppPaginatorStatus.error;
  bool get isEmpty => status == AppPaginatorStatus.empty;
  bool get isComplete => !hasMore;

  AppPaginatorState<T> copyWith({
    List<T>? items,
    AppPaginatorStatus? status,
    String? error,
    int? page,
    bool? hasMore,
  }) => AppPaginatorState(
    items: items ?? this.items,
    status: status ?? this.status,
    error: error ?? this.error,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
  );
}

// ─── Paginator Controller ─────────────────────────────────────────────────────
class AppPaginatorController<T> extends ChangeNotifier {
  final Future<List<T>> Function(int page, int pageSize) fetcher;
  final int pageSize;

  AppPaginatorState<T> _state = const AppPaginatorState();
  AppPaginatorState<T> get state => _state;

  AppPaginatorController({
    required this.fetcher,
    this.pageSize = 20,
  });

  Future<void> loadFirst() async {
    if (_state.status == AppPaginatorStatus.loading) return;
    _state = _state.copyWith(status: AppPaginatorStatus.loading, page: 0, items: []);
    notifyListeners();
    await _fetch(0);
  }

  Future<void> refresh() async {
    if (_state.status == AppPaginatorStatus.refreshing) return;
    _state = _state.copyWith(status: AppPaginatorStatus.refreshing, page: 0);
    notifyListeners();
    await _fetch(0);
  }

  Future<void> loadMore() async {
    if (!_state.hasMore) return;
    if (_state.status == AppPaginatorStatus.loadingMore) return;
    if (_state.status == AppPaginatorStatus.loading) return;
    _state = _state.copyWith(status: AppPaginatorStatus.loadingMore);
    notifyListeners();
    await _fetch(_state.page + 1);
  }

  Future<void> _fetch(int page) async {
    try {
      final results = await fetcher(page, pageSize);
      final combined = page == 0 ? results : [..._state.items, ...results];
      _state = AppPaginatorState(
        items: combined,
        status: combined.isEmpty ? AppPaginatorStatus.empty : AppPaginatorStatus.idle,
        page: page,
        hasMore: results.length == pageSize,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: AppPaginatorStatus.error,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  void reset() {
    _state = const AppPaginatorState();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ─── App Paginator Widget ─────────────────────────────────────────────────────
class AppPaginator<T> extends StatefulWidget {
  final AppPaginatorController<T> controller;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget Function(BuildContext, int)? skeletonBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? separator;
  final bool enableRefresh;
  final bool enableLoadMore;
  final Axis scrollDirection;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool useSlivers;
  // Grid support
  final SliverGridDelegate? gridDelegate;
  final double loadMoreThreshold;

  const AppPaginator({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.skeletonBuilder,
    this.emptyWidget,
    this.errorWidget,
    this.separator,
    this.enableRefresh = true,
    this.enableLoadMore = true,
    this.scrollDirection = Axis.vertical,
    this.scrollController,
    this.padding,
    this.useSlivers = false,
    this.gridDelegate,
    this.loadMoreThreshold = 200,
  });

  @override
  State<AppPaginator<T>> createState() => _AppPaginatorState<T>();
}

class _AppPaginatorState<T> extends State<AppPaginator<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_rebuild);
    // Auto-load on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.state.items.isEmpty &&
          widget.controller.state.status == AppPaginatorStatus.idle) {
        widget.controller.loadFirst();
      }
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!widget.enableLoadMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - widget.loadMoreThreshold) {
      widget.controller.loadMore();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _scrollController.dispose();
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;

    // Initial loading with skeletons
    if (state.isLoading) {
      return _buildSkeletons(context);
    }

    // Error with no data
    if (state.isError && state.items.isEmpty) {
      return widget.errorWidget ??
          AppStateWidget.error(
            message: state.error,
            onRetry: widget.controller.loadFirst,
          );
    }

    // Empty
    if (state.isEmpty && state.items.isEmpty) {
      return widget.emptyWidget ?? AppStateWidget.empty();
    }

    Widget list;
    if (widget.gridDelegate != null) {
      list = _buildGrid(state);
    } else {
      list = _buildList(state);
    }

    if (widget.enableRefresh) {
      list = RefreshIndicator(
        onRefresh: widget.controller.refresh,
        child: list,
      );
    }

    return list;
  }

  Widget _buildSkeletons(BuildContext context) {
    if (widget.skeletonBuilder != null) {
      return ListView.separated(
        padding: widget.padding,
        itemCount: 6,
        separatorBuilder: (_, __) =>
            widget.separator ?? const SizedBox(height: 8),
        itemBuilder: widget.skeletonBuilder!,
      );
    }
    return SingleChildScrollView(
      padding: widget.padding,
      child: AppShimmer.list(count: 6),
    );
  }

  Widget _buildList(AppPaginatorState<T> state) {
    return ListView.separated(
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          widget.separator ?? const SizedBox(height: 0),
      itemBuilder: (ctx, i) {
        if (i == state.items.length) return _buildLoadMoreIndicator();
        return widget.itemBuilder(ctx, state.items[i], i);
      },
    );
  }

  Widget _buildGrid(AppPaginatorState<T> state) {
    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      gridDelegate: widget.gridDelegate!,
      itemCount: state.items.length + (state.isLoadingMore ? 2 : 0),
      itemBuilder: (ctx, i) {
        if (i >= state.items.length) return _buildLoadMoreIndicator();
        return widget.itemBuilder(ctx, state.items[i], i);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (widget.controller.state.isError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: widget.controller.loadMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
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

// ─── Sliver-based Paginator (for CustomScrollView) ────────────────────────────
class AppSliverPaginator<T> extends StatefulWidget {
  final AppPaginatorController<T> controller;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget Function(BuildContext, int)? skeletonBuilder;
  final SliverGridDelegate? gridDelegate;
  final Widget? separator;

  const AppSliverPaginator({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.skeletonBuilder,
    this.gridDelegate,
    this.separator,
  });

  @override
  State<AppSliverPaginator<T>> createState() => _AppSliverPaginatorState<T>();
}

class _AppSliverPaginatorState<T> extends State<AppSliverPaginator<T>> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;

    if (widget.gridDelegate != null) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => widget.itemBuilder(ctx, state.items[i], i),
          childCount: state.items.length,
        ),
        gridDelegate: widget.gridDelegate!,
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => widget.itemBuilder(ctx, state.items[i], i),
        childCount: state.items.length,
      ),
    );
  }
}
