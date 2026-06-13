// ignore_for_file: deprecated_member_use
// ─── AppSearchField ──────────────────────────────────────────────────────────
// Reusable search text field that can be embedded anywhere.
// Supports filled box, bottom-border only (underline), and borderless designs.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

enum AppSearchFieldStyle {
  /// Rounded box with filled background.
  filled,
  /// Only bottom border/line.
  underline,
  /// No border at all (borderless).
  none,
}

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final AppSearchFieldStyle style;
  final bool autofocus;
  final Color? fillColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? iconColor;
  final bool unfocusOnTapOutside;

  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.style = AppSearchFieldStyle.filled,
    this.autofocus = false,
    this.fillColor,
    this.borderRadius = 8.0,
    this.textStyle,
    this.hintStyle,
    this.iconColor,
    this.unfocusOnTapOutside = true,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isControllerOwned = false;
  bool _isFocusNodeOwned = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isControllerOwned = true;
    }
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isFocusNodeOwned = true;
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_isControllerOwned) _controller.dispose();
    if (_isFocusNodeOwned) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    
    // Resolve colors based on current design system
    final resolvedIconColor = widget.iconColor ?? (isDark ? Colors.white38 : const Color(0xFF94A3B8));
    final resolvedFillColor = widget.fillColor ?? 
        (widget.style == AppSearchFieldStyle.filled
            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
            : Colors.transparent);

    // Build the border configuration based on selected style
    InputBorder border;
    switch (widget.style) {
      case AppSearchFieldStyle.filled:
        border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide.none,
        );
        break;
      case AppSearchFieldStyle.underline:
        border = UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        );
        break;
      case AppSearchFieldStyle.none:
        border = InputBorder.none;
        break;
    }

    InputBorder focusedBorder;
    switch (widget.style) {
      case AppSearchFieldStyle.filled:
        focusedBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: cs.primary.withOpacity(0.5),
            width: 1.5,
          ),
        );
        break;
      case AppSearchFieldStyle.underline:
        focusedBorder = UnderlineInputBorder(
          borderSide: BorderSide(
            color: cs.primary,
            width: 2.0,
          ),
        );
        break;
      case AppSearchFieldStyle.none:
        focusedBorder = InputBorder.none;
        break;
    }

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTapOutside: widget.unfocusOnTapOutside
          ? (event) => _focusNode.unfocus()
          : null,
      style: widget.textStyle ?? theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ?? TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        filled: widget.style == AppSearchFieldStyle.filled,
        fillColor: resolvedFillColor,
        prefixIcon: Icon(
          Iconsax.search_normal,
          size: 18,
          color: resolvedIconColor,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(
                  Iconsax.close_circle,
                  size: 18,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                  widget.onClear?.call();
                  _focusNode.requestFocus();
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
      ),
    );
  }
}
