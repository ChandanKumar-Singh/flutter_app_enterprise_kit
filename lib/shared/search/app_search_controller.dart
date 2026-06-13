// ─── AppSearchController ──────────────────────────────────────────────────────
// Manages all search UI state: mode, query, history, suggestions, loading.
// Plug into any screen by connecting onSearch / onSuggest callbacks.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_search_config.dart';

class AppSearchController extends ChangeNotifier {
  AppSearchController({required this.config});

  final AppSearchConfig config;

  // ── State ──────────────────────────────────────────────────────────────────
  String _query         = '';
  bool   _isSearchMode  = false;
  bool   _isLoading     = false;

  final List<String>              _recentSearches = [];
  final List<AppSearchSuggestion> _suggestions    = [];

  Timer? _debounce;

  // ── Callbacks wired by the consumer ───────────────────────────────────────
  /// Called (debounced) every time the query changes. Feed into data layer.
  ValueChanged<String>? onSearch;

  /// Called when suggestions should be regenerated. Consumer should call
  /// [setSuggestions] with results.
  ValueChanged<String>? onSuggest;

  // ── Getters ────────────────────────────────────────────────────────────────
  String get query        => _query;
  bool   get isSearchMode => _isSearchMode;
  bool   get isLoading    => _isLoading;
  bool   get hasQuery     => _query.isNotEmpty;

  List<String>              get recentSearches => List.unmodifiable(_recentSearches);
  List<AppSearchSuggestion> get suggestions    => List.unmodifiable(_suggestions);

  AppSearchState get state {
    if (!_isSearchMode)    return AppSearchState.idle;
    if (_query.isEmpty)    return AppSearchState.empty;
    if (_isLoading)        return AppSearchState.loading;
    return AppSearchState.typing;
  }

  // ── Search mode control ───────────────────────────────────────────────────

  void enterSearchMode() {
    if (_isSearchMode) return;
    _isSearchMode = true;
    notifyListeners();
  }

  void exitSearchMode() {
    _debounce?.cancel();
    _isSearchMode = false;
    _isLoading    = false;
    if (_query.isNotEmpty) {
      _query = '';
      onSearch?.call('');
    }
    _suggestions.clear();
    notifyListeners();
  }

  // ── Query management ──────────────────────────────────────────────────────

  void setQuery(String q) {
    _query = q;

    _debounce?.cancel();
    _debounce = Timer(config.searchDebounce, () {
      onSearch?.call(q);
      if (config.enableSuggestions && q.isNotEmpty) {
        onSuggest?.call(q);
      }
    });

    notifyListeners();
  }

  void clearQuery() {
    _debounce?.cancel();
    _query = '';
    _isLoading = false;
    _suggestions.clear();
    onSearch?.call('');
    notifyListeners();
  }

  /// Called when user taps Enter / submits the search field.
  void submitQuery(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    _addToHistory(trimmed);
    _debounce?.cancel();
    onSearch?.call(trimmed);
    notifyListeners();
  }

  // ── Suggestions ────────────────────────────────────────────────────────────

  void setSuggestions(List<AppSearchSuggestion> suggestions) {
    _suggestions
      ..clear()
      ..addAll(suggestions);
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ── History ────────────────────────────────────────────────────────────────

  void _addToHistory(String q) {
    _recentSearches.remove(q);
    _recentSearches.insert(0, q);
    if (_recentSearches.length > config.maxRecentSearches) {
      _recentSearches.removeRange(config.maxRecentSearches, _recentSearches.length);
    }
  }

  void removeFromHistory(String q) {
    _recentSearches.remove(q);
    notifyListeners();
  }

  void clearHistory() {
    _recentSearches.clear();
    notifyListeners();
  }

  // ── Tap a recent/suggestion ───────────────────────────────────────────────

  void selectRecent(String q) {
    _query = q;
    _addToHistory(q);
    onSearch?.call(q);
    notifyListeners();
  }

  void selectSuggestion(AppSearchSuggestion s) {
    _query = s.text;
    _addToHistory(s.text);
    onSearch?.call(s.text);
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
