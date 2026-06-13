// ignore_for_file: deprecated_member_use
// ─── AppSearchOverlay ─────────────────────────────────────────────────────────
// Full search experience panel — shown as a Stack overlay on top of the list
// when search mode is active.
//
// Idle (no query):
//   Recent Searches  [Clear]
//   ◷ payment         ✕
//   ◷ invoice         ✕
//   ◷ security        ✕
//   ─────────────────────
//   Quick Filters
//   [Unread] [Security] [Finance] [Tasks]
//
// Typing (has query):
//   Suggestions
//   🔔  Payment Approved      Finance
//   🔔  Payment Failed        Finance
//   🔔  Payment Received      Finance
//
// Wrap your list like:
//   Stack(children: [
//     YourListWidget(),
//     AppSearchOverlay(controller: _searchCtrl, config: ..., resultCount: n),
//   ])
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../app_search_config.dart';
import '../app_search_controller.dart';

class AppSearchOverlay extends StatelessWidget {
  final AppSearchController controller;
  final AppSearchConfig config;

  /// How many results the current query returned (shown in results header).
  final int? resultCount;

  /// Extra filter chips to show in the idle state (e.g. categories).
  final List<_OverlayChip> quickFilters;

  /// Callback when a quick filter chip is tapped.
  final ValueChanged<_OverlayChip>? onFilterTap;

  const AppSearchOverlay({
    super.key,
    required this.controller,
    required this.config,
    this.resultCount,
    this.quickFilters = const [],
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isSearchMode) return const SizedBox.shrink();

        final theme  = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bg     = isDark ? const Color(0xFF0A0F1C) : Colors.white;

        return _OverlayPanel(
          isDark: isDark,
          bg: bg,
          child: controller.hasQuery
              ? _SuggestionsSection(
                  controller: controller,
                  theme: theme,
                  isDark: isDark,
                  resultCount: resultCount,
                )
              : _IdleSection(
                  controller: controller,
                  config: config,
                  theme: theme,
                  isDark: isDark,
                  quickFilters: quickFilters,
                  onFilterTap: onFilterTap,
                ),
        );
      },
    );
  }
}

// ── Overlay panel wrapper ─────────────────────────────────────────────────────

class _OverlayPanel extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color bg;

  const _OverlayPanel({required this.child, required this.isDark, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: bg,
        child: child,
      )
      .animate()
      .fadeIn(duration: 160.ms, curve: Curves.easeOut)
      .slideY(begin: -0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
    );
  }
}

// ── Idle state (no query) ─────────────────────────────────────────────────────

class _IdleSection extends StatelessWidget {
  final AppSearchController controller;
  final AppSearchConfig config;
  final ThemeData theme;
  final bool isDark;
  final List<_OverlayChip> quickFilters;
  final ValueChanged<_OverlayChip>? onFilterTap;

  const _IdleSection({
    required this.controller,
    required this.config,
    required this.theme,
    required this.isDark,
    required this.quickFilters,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final recents = controller.recentSearches;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [

        // ── Quick filter chips ─────────────────────────────────────────────
        if (quickFilters.isNotEmpty) ...[
          _OverlayHeader(
            label: 'Quick Filters',
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: quickFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final chip = quickFilters[i];
                return _QuickFilterChip(
                  chip: chip,
                  isDark: isDark,
                  theme: theme,
                  onTap: () => onFilterTap?.call(chip),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _Divider(isDark: isDark),
        ],

        // ── Recent searches ────────────────────────────────────────────────
        if (config.enableRecentSearches && recents.isNotEmpty) ...[
          _OverlayHeader(
            label: 'Recent Searches',
            isDark: isDark,
            trailingLabel: 'Clear',
            onTrailingTap: controller.clearHistory,
          ),
          const SizedBox(height: 4),
          ...recents.map((q) => _RecentSearchRow(
                query: q,
                isDark: isDark,
                theme: theme,
                onTap: () => controller.selectRecent(q),
                onRemove: () => controller.removeFromHistory(q),
              )),
        ] else if (recents.isEmpty && !config.enableSuggestions) ...[
          _EmptyPrompt(
            icon: Iconsax.search_normal,
            message: 'Start typing to search',
            isDark: isDark,
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Suggestions state (has query) ─────────────────────────────────────────────

class _SuggestionsSection extends StatelessWidget {
  final AppSearchController controller;
  final ThemeData theme;
  final bool isDark;
  final int? resultCount;

  const _SuggestionsSection({
    required this.controller,
    required this.theme,
    required this.isDark,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = controller.suggestions;

    if (controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white38 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Searching…',
              style: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Results header when suggestions are loaded and resultCount is known
    if (suggestions.isEmpty && resultCount != null) {
      return resultCount! > 0
          ? _ResultsHeader(count: resultCount!, isDark: isDark)
          : _EmptyPrompt(
              icon: Iconsax.search_status,
              message: 'No results for "${controller.query}"',
              subtitle: 'Try different keywords or clear filters',
              isDark: isDark,
            );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        // Result count header
        if (resultCount != null)
          _ResultsHeader(count: resultCount!, isDark: isDark),

        // Suggestion rows
        if (suggestions.isNotEmpty) ...[
          _OverlayHeader(label: 'Suggestions', isDark: isDark),
          ...suggestions.map((s) => _SuggestionRow(
                suggestion: s,
                query: controller.query,
                isDark: isDark,
                theme: theme,
                onTap: () => controller.selectSuggestion(s),
              )),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const _OverlayHeader({
    required this.label,
    required this.isDark,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
          ),
          const Spacer(),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailingLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  final String query;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchRow({
    required this.query,
    required this.isDark,
    required this.theme,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(
              Iconsax.clock,
              size: 16,
              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Iconsax.close_circle,
                  size: 14,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final AppSearchSuggestion suggestion;
  final String query;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.suggestion,
    required this.query,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = suggestion.iconColor
        ?? (isDark ? Colors.white38 : const Color(0xFF94A3B8));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // Icon
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                suggestion.icon ?? Iconsax.search_normal,
                size: 14,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(
                    text: suggestion.text,
                    highlight: query,
                    theme: theme,
                    isDark: isDark,
                  ),
                  if (suggestion.subtitle != null)
                    Text(
                      suggestion.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            // Category chip
            if (suggestion.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  suggestion.category!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final _OverlayChip chip;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.chip,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active     = chip.isActive;
    final chipColor  = chip.color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? chipColor.withOpacity(isDark ? 0.25 : 0.12)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? chipColor.withOpacity(0.5)
                : (isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chip.icon != null) ...[
              Icon(chip.icon, size: 12, color: active ? chipColor : (isDark ? Colors.white54 : const Color(0xFF6B7280))),
              const SizedBox(width: 5),
            ],
            Text(
              chip.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? chipColor : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
            ),
            if (chip.count != null) ...[
              const SizedBox(width: 5),
              Text(
                '${chip.count}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? chipColor : (isDark ? Colors.white30 : Colors.black38),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final int count;
  final bool isDark;

  const _ResultsHeader({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(
            Iconsax.search_status,
            size: 14,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
          const SizedBox(width: 6),
          Text(
            count == 1 ? '1 result' : '$count results',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final bool isDark;

  const _EmptyPrompt({
    required this.icon,
    required this.message,
    required this.isDark,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40,
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.black12),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
    );
  }
}

/// Highlights [highlight] substring inside [text] in bold.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final ThemeData theme;
  final bool isDark;

  const _HighlightedText({
    required this.text,
    required this.highlight,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : const Color(0xFF374151),
          ));
    }

    final lower  = text.toLowerCase();
    final hLower = highlight.toLowerCase();
    final idx    = lower.indexOf(hLower);

    if (idx == -1) {
      return Text(text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : const Color(0xFF374151),
          ));
    }

    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark ? Colors.white70 : const Color(0xFF374151),
    );
    final boldStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    );

    return RichText(
      text: TextSpan(children: [
        if (idx > 0) TextSpan(text: text.substring(0, idx), style: baseStyle),
        TextSpan(text: text.substring(idx, idx + highlight.length), style: boldStyle),
        if (idx + highlight.length < text.length)
          TextSpan(text: text.substring(idx + highlight.length), style: baseStyle),
      ]),
    );
  }
}

// ── Public chip model ─────────────────────────────────────────────────────────

class _OverlayChip {
  final String id;
  final String label;
  final IconData? icon;
  final Color? color;
  final int? count;
  final bool isActive;

  const _OverlayChip({
    required this.id,
    required this.label,
    this.icon,
    this.color,
    this.count,
    this.isActive = false,
  });

  _OverlayChip copyWith({bool? isActive}) => _OverlayChip(
        id: id,
        label: label,
        icon: icon,
        color: color,
        count: count,
        isActive: isActive ?? this.isActive,
      );
}

// Make it public (exported via index.dart)
typedef AppSearchOverlayChip = _OverlayChip;
