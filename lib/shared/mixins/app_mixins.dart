import 'dart:async';
import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/debug/app_logger.dart';

// ─── 1. Logger Mixin ──────────────────────────────────────────────────────────
mixin LoggerMixin {
  AppLogger get _log => AppLogger.instance;

  void logD(String message, [dynamic data]) =>
      _log.d('[$runtimeType] $message${data != null ? ' | $data' : ''}');

  void logI(String message, [dynamic data]) =>
      _log.i('[$runtimeType] $message${data != null ? ' | $data' : ''}');

  void logW(String message, [dynamic data]) =>
      _log.w('[$runtimeType] $message${data != null ? ' | $data' : ''}');

  void logE(String message, [dynamic error, StackTrace? stack]) =>
      _log.e('[$runtimeType] $message', error: error, stackTrace: stack);
}

// ─── 2. Lifecycle Mixin (for State) ───────────────────────────────────────────
mixin LifecycleMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:    onResumed(); break;
      case AppLifecycleState.paused:     onPaused(); break;
      case AppLifecycleState.inactive:   onInactive(); break;
      case AppLifecycleState.detached:   onDetached(); break;
      case AppLifecycleState.hidden:     onHidden(); break;
    }
  }

  void onResumed() {}
  void onPaused() {}
  void onInactive() {}
  void onDetached() {}
  void onHidden() {}
}

// ─── 3. Pagination Mixin ──────────────────────────────────────────────────────
mixin PaginationMixin<T> {
  final List<T> items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  int get currentPage => _page;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<List<T>> fetchPage(int page);

  Future<void> loadFirstPage() async {
    _page = 1;
    _hasMore = true;
    items.clear();
    await loadNextPage();
  }

  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    try {
      final newItems = await fetchPage(_page);
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        items.addAll(newItems);
        _page++;
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() => loadFirstPage();
}

// ─── 4. Search Mixin ──────────────────────────────────────────────────────────
mixin SearchMixin<T> {
  String _query = '';
  Timer? _debounce;
  List<T> _allItems = [];
  List<T> _filteredItems = [];

  String get query => _query;
  List<T> get filteredItems => _filteredItems;
  bool get isSearching => _query.isNotEmpty;

  void initSearch(List<T> items) {
    _allItems = items;
    _filteredItems = items;
  }

  bool itemMatchesQuery(T item, String query);

  void onQueryChanged(String query, {Duration debounce = const Duration(milliseconds: 300)}) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      _query = query;
      _filteredItems = query.isEmpty
          ? _allItems
          : _allItems.where((item) => itemMatchesQuery(item, query)).toList();
      onSearchResultsChanged(_filteredItems);
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    _query = '';
    _filteredItems = _allItems;
    onSearchResultsChanged(_filteredItems);
  }

  void onSearchResultsChanged(List<T> results) {}

  void disposeSearch() => _debounce?.cancel();
}

// ─── 5. Form Mixin ────────────────────────────────────────────────────────────
mixin FormMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  bool validateForm() => formKey.currentState?.validate() ?? false;
  void resetForm() => formKey.currentState?.reset();
  void saveForm() => formKey.currentState?.save();

  Future<void> submitForm(Future<void> Function() onValid) async {
    if (!validateForm()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await onValid();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ─── 6. After-Layout Mixin ────────────────────────────────────────────────────
mixin AfterLayoutMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) afterLayout();
    });
  }

  void afterLayout();
}

// ─── 7. AsyncInitMixin ────────────────────────────────────────────────────────
mixin AsyncInitMixin<T extends StatefulWidget> on State<T> {
  bool _initialized = false;
  Object? _initError;

  bool get isInitialized => _initialized;
  Object? get initError => _initError;

  @override
  void initState() {
    super.initState();
    _asyncInit();
  }

  Future<void> _asyncInit() async {
    try {
      await asyncInit();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() { _initialized = true; _initError = e; });
    }
  }

  Future<void> asyncInit();
}
