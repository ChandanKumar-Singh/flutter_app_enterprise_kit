// ignore_for_file: deprecated_member_use
// ─── AppSearchBar ─────────────────────────────────────────────────────────────
// Drop-in replacement for AppBar that handles normal ↔ search mode morphing.
//
// Normal mode:
//   [Title + badge]             [🔍] [extra actions...]
//
// Search mode (full-width):
//   [←]   [Search {scope}...]              [✕]
//
// Usage:
//   appBar: AppSearchBar(
//     controller: _searchCtrl,
//     config: AppSearchConfig.notifications(),
//     title: Text('Notifications'),
//     actions: [settingsButton, markAllReadButton],
//   ),
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../app_search_controller.dart';
import '../app_search_config.dart';

class AppSearchBar extends StatefulWidget implements PreferredSizeWidget {
  final AppSearchController controller;
  final AppSearchConfig config;

  /// Widget shown as the AppBar title in normal mode.
  final Widget title;

  /// Extra action buttons placed AFTER the search icon in normal mode.
  final List<Widget> actions;

  /// Called when back arrow is tapped in search mode (default: exitSearchMode).
  final VoidCallback? onSearchBack;

  /// Whether to show a back arrow on the left in normal mode.
  final bool showLeading;
  final VoidCallback? onLeadingTap;

  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.config,
    required this.title,
    this.actions = const [],
    this.onSearchBack,
    this.showLeading = false,
    this.onLeadingTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar>
    with SingleTickerProviderStateMixin {
  final _textCtrl  = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (!mounted) return;
    if (widget.controller.isSearchMode) {
      _animCtrl.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _animCtrl.reverse();
      _textCtrl.clear();
      _focusNode.unfocus();
    }
    setState(() {});
  }

  void _exitSearch() {
    widget.onSearchBack?.call();
    widget.controller.exitSearchMode();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final bg      = widget.backgroundColor
        ?? (isDark ? const Color(0xFF0F172A) : Colors.white);
    final fg      = widget.foregroundColor
        ?? (isDark ? Colors.white : const Color(0xFF0F172A));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      child: widget.controller.isSearchMode
          ? _SearchModeBar(
              key: const ValueKey('search'),
              textCtrl:  _textCtrl,
              focusNode: _focusNode,
              controller: widget.controller,
              config:    widget.config,
              onBack:    _exitSearch,
              bg:        bg,
              fg:        fg,
            )
          : _NormalModeBar(
              key: const ValueKey('normal'),
              controller: widget.controller,
              title:      widget.title,
              actions:    widget.actions,
              config:     widget.config,
              showLeading: widget.showLeading,
              onLeadingTap: widget.onLeadingTap,
              bg:         bg,
              fg:         fg,
            ),
    );
  }
}

// ── Normal mode bar ───────────────────────────────────────────────────────────

class _NormalModeBar extends StatelessWidget {
  final AppSearchController controller;
  final Widget title;
  final List<Widget> actions;
  final AppSearchConfig config;
  final bool showLeading;
  final VoidCallback? onLeadingTap;
  final Color bg, fg;

  const _NormalModeBar({
    super.key,
    required this.controller,
    required this.title,
    required this.actions,
    required this.config,
    required this.bg,
    required this.fg,
    this.showLeading = false,
    this.onLeadingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor:       bg,
      foregroundColor:       fg,
      elevation:             0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: showLeading,
      leading: showLeading
          ? IconButton(
              icon: Icon(Iconsax.arrow_left, color: fg, size: 20),
              onPressed: onLeadingTap ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: title,
      actions: [
        // Search icon — always present when search is enabled in config
        _SearchIconButton(
          controller: controller,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
        // Consumer actions
        ...actions,
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
    );
  }
}

// ── Search mode bar ───────────────────────────────────────────────────────────

class _SearchModeBar extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode focusNode;
  final AppSearchController controller;
  final AppSearchConfig config;
  final VoidCallback onBack;
  final Color bg, fg;

  const _SearchModeBar({
    super.key,
    required this.textCtrl,
    required this.focusNode,
    required this.controller,
    required this.config,
    required this.onBack,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hint   = config.placeholder;

    return AppBar(
      backgroundColor:       bg,
      elevation:             0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          // Back arrow
          IconButton(
            icon: Icon(Iconsax.arrow_left, size: 20, color: fg),
            onPressed: onBack,
            padding: const EdgeInsets.only(left: 8, right: 4),
          ),

          // Search field
          Expanded(
            child: TextFormField(
              controller: textCtrl,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFFADB5BD),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: controller.setQuery,
              onFieldSubmitted: (v) {
                controller.submitQuery(v);
                focusNode.unfocus();
              },
            ),
          ),

          // Clear / X button
          AnimatedOpacity(
            opacity: controller.hasQuery ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: IconButton(
              icon: Icon(
                Iconsax.close_circle,
                size: 18,
                color: isDark ? Colors.white38 : const Color(0xFFADB5BD),
              ),
              onPressed: controller.hasQuery
                  ? () {
                      textCtrl.clear();
                      controller.clearQuery();
                      focusNode.requestFocus();
                    }
                  : null,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
    );
  }
}

// ── Search icon action button ─────────────────────────────────────────────────

class _SearchIconButton extends StatelessWidget {
  final AppSearchController controller;
  final Color color;

  const _SearchIconButton({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Iconsax.search_normal, size: 20, color: color),
      tooltip: 'Search',
      onPressed: controller.enterSearchMode,
    );
  }
}
