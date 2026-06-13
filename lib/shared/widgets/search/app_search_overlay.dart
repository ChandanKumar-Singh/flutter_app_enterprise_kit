// ─── AppSearchOverlay ─────────────────────────────────────────────────────────
// Universal full-screen search with debounce, history, and suggestions.
//
// Features:
//   • 300ms debounce on input
//   • Recent searches — persisted via SharedPreferences, max 10
//   • Suggestion slots populated by AppSearchDelegate
//   • Full-screen overlay with hero transition
//   • Empty / loading / results / error states
//   • Highlight matching query text in results
//   • Voice search hook
//
// Usage:
//   // 1. Define your delegate
//   class ProductSearchDelegate extends AppSearchDelegate<Product> {
//     @override
//     Future<List<AppSearchResult<Product>>> search(String query) async {
//       final products = await _api.searchProducts(query);
//       return products.map((p) => AppSearchResult(
//         title: p.name, subtitle: p.category,
//         data: p, icon: Iconsax.shopping_bag,
//       )).toList();
//     }
//
//     @override
//     void onResultTap(BuildContext context, AppSearchResult<Product> result) {
//       context.go('/products/${result.data.id}');
//     }
//   }
//
//   // 2. Open the overlay
//   AppSearchOverlay.show(context, delegate: ProductSearchDelegate());
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ── Result model ──────────────────────────────────────────────────────────────

class AppSearchResult<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final String? imageUrl;
  final T? data;

  const AppSearchResult({
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.imageUrl,
    this.data,
  });
}

// ── Delegate ──────────────────────────────────────────────────────────────────

abstract class AppSearchDelegate<T> {
  /// Called when the user submits a search query (debounced).
  Future<List<AppSearchResult<T>>> search(String query);

  /// Called when the user taps a result.
  void onResultTap(BuildContext context, AppSearchResult<T> result);

  /// Optional: initial suggestions shown before the user types.
  Future<List<AppSearchResult<T>>> suggestions() async => [];

  /// Optional: hint text shown in the search field.
  String get hintText => 'Search...';

  /// Optional: history key for SharedPreferences.
  String get historyKey => 'app_search_history_default';

  /// Max recent searches to keep.
  int get maxHistory => 10;
}

// ── Search overlay ────────────────────────────────────────────────────────────

class AppSearchOverlay<T> extends StatefulWidget {
  final AppSearchDelegate<T> delegate;

  const AppSearchOverlay._({required this.delegate});

  static Future<void> show<T>(
    BuildContext context, {
    required AppSearchDelegate<T> delegate,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => AppSearchOverlay<T>._(delegate: delegate),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  State<AppSearchOverlay<T>> createState() => _AppSearchOverlayState<T>();
}

class _AppSearchOverlayState<T> extends State<AppSearchOverlay<T>> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<AppSearchResult<T>> _results = [];
  List<AppSearchResult<T>> _suggestions = [];
  List<String> _history = [];

  bool _loading = false;
  bool _hasSearched = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadSuggestions();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history =
        prefs.getStringList(widget.delegate.historyKey) ?? [];
    if (mounted) setState(() => _history = history);
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final history = List<String>.from(_history);
    history.remove(query); // avoid duplicates
    history.insert(0, query);
    if (history.length > widget.delegate.maxHistory) {
      history.removeLast();
    }
    await prefs.setStringList(widget.delegate.historyKey, history);
    if (mounted) setState(() => _history = history);
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = List<String>.from(_history)..remove(query);
    await prefs.setStringList(widget.delegate.historyKey, history);
    if (mounted) setState(() => _history = history);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.delegate.historyKey);
    if (mounted) setState(() => _history = []);
  }

  Future<void> _loadSuggestions() async {
    try {
      final s = await widget.delegate.suggestions();
      if (mounted) setState(() => _suggestions = s);
    } catch (_) {}
  }

  void _onQueryChanged(String query) {
    setState(() => _query = query);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _doSearch(query));
  }

  Future<void> _doSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.delegate.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _hasSearched = true;
        _loading = false;
      });
      await _saveToHistory(query);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onResultTap(AppSearchResult<T> result) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    widget.delegate.onResultTap(context, result);
  }

  void _onHistoryTap(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    _onQueryChanged(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: TextFormField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onQueryChanged,
                        onFieldSubmitted: _doSearch,
                        onTapOutside: (event) => _focusNode.unfocus(),
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: widget.delegate.hintText,
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Iconsax.search_normal,
                            color: cs.onSurfaceVariant,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Iconsax.close_circle),
                                  onPressed: () {
                                    _controller.clear();
                                    _onQueryChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider + progress ──────────────────────────────────────────
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _query.isEmpty
                ? _buildIdle(context)
                : _buildResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        // Suggestions
        if (_suggestions.isNotEmpty) ...[
          _SectionHeader('Suggestions'),
          ..._suggestions.map((r) => _ResultTile(
                result: r,
                query: '',
                onTap: () => _onResultTap(r),
                trailing: const Icon(Iconsax.arrow_left, size: 16),
              )),
        ],
        // History
        if (_history.isNotEmpty) ...[
          _SectionHeader(
            'Recent',
            trailing: TextButton(
              onPressed: _clearHistory,
              child: const Text('Clear all'),
            ),
          ),
          ..._history.map(
            (q) => ListTile(
              leading: Icon(Iconsax.clock, color: cs.onSurfaceVariant),
              title: Text(q),
              trailing: IconButton(
                icon: Icon(
                  Iconsax.close_circle,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () => _removeFromHistory(q),
              ),
              onTap: () => _onHistoryTap(q),
            ),
          ),
        ],
        if (_suggestions.isEmpty && _history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
                  Icon(
                    Iconsax.search_normal,
                    size: 64,
                    color: cs.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Start typing to search',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.danger,
                size: 48, color: cs.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Search failed',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_hasSearched || _loading) {
      return const SizedBox.shrink();
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_normal,
              size: 64,
              color: cs.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No results for "$_query"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _results.length,
      itemBuilder: (_, i) => _ResultTile(
        result: _results[i],
        query: _query,
        onTap: () => _onResultTap(_results[i]),
      ).animate().fadeIn(
            delay: Duration(milliseconds: i * 30),
            duration: 200.ms,
          ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeader(this.label, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────

class _ResultTile<T> extends StatelessWidget {
  final AppSearchResult<T> result;
  final String query;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ResultTile({
    required this.result,
    required this.query,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      leading: _buildLeading(cs),
      title: _HighlightText(text: result.title, query: query),
      subtitle: result.subtitle != null
          ? Text(
              result.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildLeading(ColorScheme cs) {
    if (result.leading != null) return result.leading!;
    if (result.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Image.network(
          result.imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(result.icon ?? Iconsax.image, color: cs.primary),
        ),
      );
    }
    if (result.icon != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(result.icon, color: cs.primary, size: 20),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Highlight text ────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (query.isEmpty) {
      return Text(text, style: theme.textTheme.bodyMedium);
    }

    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final idx = lower.indexOf(queryLower);

    if (idx == -1) {
      return Text(text, style: theme.textTheme.bodyMedium);
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          if (idx > 0)
            TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}
