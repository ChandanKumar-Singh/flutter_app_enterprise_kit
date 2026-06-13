// ignore_for_file: deprecated_member_use
// ─── AppSearchConfig ──────────────────────────────────────────────────────────
// Config-driven search framework — plug into any screen without rewriting UI.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// ── Search states ─────────────────────────────────────────────────────────────

enum AppSearchState {
  /// Not in search mode.
  idle,
  /// Search mode open, no query yet — show recent + filters.
  empty,
  /// User is typing.
  typing,
  /// Async suggestion/result fetch in progress.
  loading,
  /// Results are available.
  results,
  /// Query produced no results.
  noResults,
}

// ── Filter models ─────────────────────────────────────────────────────────────

class AppSearchFilterOption {
  final String id;
  final String label;
  final IconData? icon;
  bool isSelected;

  AppSearchFilterOption({
    required this.id,
    required this.label,
    this.icon,
    this.isSelected = false,
  });

  AppSearchFilterOption copyWith({bool? isSelected}) => AppSearchFilterOption(
        id: id,
        label: label,
        icon: icon,
        isSelected: isSelected ?? this.isSelected,
      );
}

class AppSearchFilter {
  final String id;
  final String label;
  final IconData icon;
  final bool multiSelect;
  final List<AppSearchFilterOption> options;

  const AppSearchFilter({
    required this.id,
    required this.label,
    required this.icon,
    this.multiSelect = false,
    this.options = const [],
  });
}

// ── Suggestion model ──────────────────────────────────────────────────────────

class AppSearchSuggestion {
  final String text;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  /// Category label shown as a chip (e.g. "Security", "Finance").
  final String? category;

  const AppSearchSuggestion({
    required this.text,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.category,
  });
}

// ── Config ────────────────────────────────────────────────────────────────────

class AppSearchConfig {
  /// Placeholder text inside the search field.
  final String placeholder;

  /// Optional scope label — e.g. "notifications", "users", "orders".
  /// Used to build "Search {scope}" label in search mode AppBar.
  final String? scope;

  final bool enableHistory;
  final bool enableSuggestions;
  final bool enableFilters;
  final bool enableVoiceSearch;
  final bool enableRecentSearches;
  final int maxRecentSearches;
  final Duration searchDebounce;

  /// Extra filter rows (category, priority, date range, etc.).
  final List<AppSearchFilter> filters;

  const AppSearchConfig({
    this.placeholder = 'Search…',
    this.scope,
    this.enableHistory       = true,
    this.enableSuggestions   = true,
    this.enableFilters       = true,
    this.enableVoiceSearch   = false,
    this.enableRecentSearches = true,
    this.maxRecentSearches   = 8,
    this.searchDebounce      = const Duration(milliseconds: 280),
    this.filters             = const [],
  });

  // ── Presets ─────────────────────────────────────────────────────────────────

  /// Minimal — history + debounce only, no filter UI.
  static const AppSearchConfig minimal = AppSearchConfig(
    enableHistory:        true,
    enableSuggestions:    false,
    enableFilters:        false,
    enableVoiceSearch:    false,
    enableRecentSearches: true,
    maxRecentSearches:    5,
  );

  /// Full enterprise experience.
  static const AppSearchConfig enterprise = AppSearchConfig(
    enableHistory:        true,
    enableSuggestions:    true,
    enableFilters:        true,
    enableVoiceSearch:    false,
    enableRecentSearches: true,
    maxRecentSearches:    8,
  );

  /// Notification center preset — scope + filter chips built from categories.
  static AppSearchConfig notifications({List<AppSearchFilter> filters = const []}) =>
      AppSearchConfig(
        placeholder:          'Search notifications…',
        scope:                'notifications',
        enableHistory:        true,
        enableSuggestions:    true,
        enableFilters:        true,
        enableVoiceSearch:    false,
        enableRecentSearches: true,
        maxRecentSearches:    8,
        searchDebounce:       const Duration(milliseconds: 260),
        filters:              filters,
      );

  AppSearchConfig copyWith({
    String? placeholder,
    String? scope,
    bool? enableHistory,
    bool? enableSuggestions,
    bool? enableFilters,
    bool? enableVoiceSearch,
    bool? enableRecentSearches,
    int? maxRecentSearches,
    Duration? searchDebounce,
    List<AppSearchFilter>? filters,
  }) =>
      AppSearchConfig(
        placeholder:          placeholder          ?? this.placeholder,
        scope:                scope                ?? this.scope,
        enableHistory:        enableHistory        ?? this.enableHistory,
        enableSuggestions:    enableSuggestions    ?? this.enableSuggestions,
        enableFilters:        enableFilters        ?? this.enableFilters,
        enableVoiceSearch:    enableVoiceSearch    ?? this.enableVoiceSearch,
        enableRecentSearches: enableRecentSearches ?? this.enableRecentSearches,
        maxRecentSearches:    maxRecentSearches    ?? this.maxRecentSearches,
        searchDebounce:       searchDebounce       ?? this.searchDebounce,
        filters:              filters              ?? this.filters,
      );
}

// ── Default search scope icons (Iconsax) ─────────────────────────────────────

IconData appSearchScopeIcon(String? scope) => switch (scope) {
  'notifications' => Iconsax.notification,
  'users'         => Iconsax.people,
  'orders'        => Iconsax.bag,
  'products'      => Iconsax.box,
  'services'      => Iconsax.briefcase,
  'logs'          => Iconsax.document,
  'analytics'     => Iconsax.chart,
  _               => Iconsax.search_normal,
};
